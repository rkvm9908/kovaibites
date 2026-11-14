import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/design.dart';
import '../services/cloudinary_service.dart';
import 'food_image.dart';

class ImageUploadField extends StatefulWidget {
  final String initialUrl;
  final String folder;
  final ValueChanged<String> onChanged;
  const ImageUploadField(
      {super.key, required this.initialUrl, required this.folder, required this.onChanged});

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  late String _url = widget.initialUrl;
  bool _busy = false;

  Future<void> _pick() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (x == null) return;
    setState(() => _busy = true);
    try {
      final url = await uploadToCloudinary(x, widget.folder);
      setState(() => _url = url);
      widget.onChanged(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: SizedBox(width: 80, height: 80, child: FoodImage(_url)),
      ),
      const SizedBox(width: Sp.md),
      OutlinedButton.icon(
        onPressed: _busy ? null : _pick,
        icon: _busy
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload),
        label: Text(_url.isEmpty ? 'Upload image' : 'Change image'),
      ),
    ]);
  }
}