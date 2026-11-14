import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/design.dart';
import '../services/cloudinary_service.dart';
import 'food_image.dart';

class MultiImageUploadField extends StatefulWidget {
  final List<String> initial;
  final int max;
  final String folder;
  final ValueChanged<List<String>> onChanged;
  const MultiImageUploadField({
    super.key,
    required this.initial,
    required this.max,
    required this.folder,
    required this.onChanged,
  });

  @override
  State<MultiImageUploadField> createState() => _State();
}

class _State extends State<MultiImageUploadField> {
  late final List<String> _urls = [...widget.initial];
  bool _busy = false;

  Future<void> _add() async {
    final left = widget.max - _urls.length;
    if (left <= 0) return;
    final files = await ImagePicker().pickMultiImage(maxWidth: 1200, imageQuality: 80);
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      for (final f in files.take(left)) {
        final u = await uploadToCloudinary(f, widget.folder);
        setState(() => _urls.add(u));
        widget.onChanged(List.of(_urls));
      }
      if (files.length > left && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Max ${widget.max} images mattum')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove(int i) {
    setState(() => _urls.removeAt(i));
    widget.onChanged(List.of(_urls));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images (${_urls.length}/${widget.max}). Mudhal image cover-ah varum',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: Sp.sm),
        Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
          for (var i = 0; i < _urls.length; i++)
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: SizedBox(width: 80, height: 80, child: FoodImage(_urls[i])),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  onTap: () => _remove(i),
                  child: const CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 14, color: Colors.white)),
                ),
              ),
              if (i == 0)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.black54,
                    child: const Text('Cover',
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ]),
          if (_urls.length < widget.max)
            InkWell(
              onTap: _busy ? null : _add,
              borderRadius: BorderRadius.circular(Radii.md),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: c.outline),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: _busy
                    ? const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : const Icon(Icons.add_photo_alternate_outlined),
              ),
            ),
        ]),
      ],
    );
  }
}