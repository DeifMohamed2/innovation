import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String CLOUDINARY_URL =
      'https://api.cloudinary.com/v1_1/dusod9wxt/upload';
  static const String CLOUDINARY_UPLOAD_PRESET = 'order_project';

  // Upload image to Cloudinary and return the URL
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(CLOUDINARY_URL));

      // Add fields to request
      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;

      // Add file to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        ),
      );

      // Send request
      final response = await request.send();

      // Check if upload was successful
      if (response.statusCode == 200) {
        // Get response data
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);

        // Return secure URL
        return jsonData['secure_url'];
      } else {
        print('Failed to upload image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Pick image from gallery or camera
  static Future<XFile?> pickImage({bool fromCamera = false}) async {
    final ImagePicker picker = ImagePicker();

    if (fromCamera) {
      return await picker.pickImage(source: ImageSource.camera);
    } else {
      return await picker.pickImage(source: ImageSource.gallery);
    }
  }
}
