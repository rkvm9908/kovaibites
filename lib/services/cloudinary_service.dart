import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const _cloudName = 'm5xj4yxi';
const _uploadPreset = 'kovaibites_unsigned';

Future<String> uploadToCloudinary(XFile x, String folder) async {
  final bytes = await x.readAsBytes();
  final req = http.MultipartRequest(
    'POST',
    Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
  )
    ..fields['upload_preset'] = _uploadPreset
    ..fields['folder'] = 'kovaibites/$folder'
    ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'upload.jpg'));
  final res = await http.Response.fromStream(await req.send());
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(body['error']?['message'] ?? 'Upload failed');
  }
  return body['secure_url'] as String;
}