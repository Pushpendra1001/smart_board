import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';

Future<void> _openCamera(BuildContext context) async {
  try {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image captured')),
      );
      return;
    }

    // Save the image to the app's documents directory
    final directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String fileName = 'camera_${DateTime.now().millisecondsSinceEpoch}.png';
    final String filePath = '$path/$fileName';
    
    await File(image.path).copy(filePath);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved successfully')),
    );
  } catch (e) {
    print('Error capturing image: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to capture image: ${e.toString()}')),
    );
  }
}