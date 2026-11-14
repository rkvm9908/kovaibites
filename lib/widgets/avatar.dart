import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/design.dart';
import '../models/app_user.dart';
import '../providers/auth_providers.dart';
import '../services/cloudinary_service.dart';

/// Square face-centred thumbnail for Cloudinary URLs.
String _thumb(String u, int px) => u.contains('res.cloudinary.com')
    ? u.replaceFirst(
        '/upload/', '/upload/f_auto,q_auto,w_$px,h_$px,c_fill,g_face/')
    : u;

/// Circular profile picture. Falls back to the first letter of the name.
class Avatar extends StatelessWidget {
  final String name;
  final String url;
  final double radius;

  /// Adds a white ring, useful on gradient backgrounds.
  final bool ring;

  const Avatar({
    super.key,
    required this.name,
    this.url = '',
    this.radius = 24,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    final fallback = Center(
      child: Text(initial,
          style: TextStyle(
              fontSize: radius * 0.85,
              fontWeight: FontWeight.w800,
              color: Brand.primary)),
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
        border: ring ? Border.all(color: Colors.white, width: 3) : null,
      ),
      child: url.isEmpty
          ? fallback
          : Image.network(
              _thumb(url, (size * 2).round()),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

/// Avatar with a camera badge. Tap it to change or remove the photo.
class EditableAvatar extends ConsumerStatefulWidget {
  final AppUser user;
  final double radius;
  final bool ring;

  const EditableAvatar(this.user,
      {super.key, this.radius = 32, this.ring = false});

  @override
  ConsumerState<EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends ConsumerState<EditableAvatar> {
  bool _busy = false;

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  /// Picks a photo, uploads it to Cloudinary and saves the URL on the profile.
  Future<void> _change() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (x == null) return;

    setState(() => _busy = true);
    try {
      final url = await uploadToCloudinary(x, 'avatars');
      await ref.read(authServiceProvider).updatePhoto(widget.user.uid, url);
    } catch (e) {
      if (mounted) _toast('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).updatePhoto(widget.user.uid, '');
    } catch (e) {
      if (mounted) _toast('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openMenu() {
    final hasPhoto = widget.user.photoUrl.isNotEmpty;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(hasPhoto ? 'Change photo' : 'Choose a photo'),
            onTap: () {
              Navigator.pop(ctx);
              _change();
            },
          ),
          if (hasPhoto)
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
              title: const Text('Remove photo'),
              onTap: () {
                Navigator.pop(ctx);
                _remove();
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.radius;

    return GestureDetector(
      onTap: _busy ? null : _openMenu,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: r * 2,
          height: r * 2,
          child: Stack(clipBehavior: Clip.none, children: [
            Avatar(
              name: widget.user.name,
              url: widget.user.photoUrl,
              radius: r,
              ring: widget.ring,
            ),
            if (_busy)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                      color: Colors.black38, shape: BoxShape.circle),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Brand.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt,
                    size: 13, color: Colors.white),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}