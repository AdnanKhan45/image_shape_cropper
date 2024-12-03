import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_shape_cropper/image_shape_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_shape_cropper_example/result_page.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: MyApp(), title: "Image Shape Cropper Demo",));
}

class MyApp extends StatelessWidget {
  final ImageShapeCropper _cropper = ImageShapeCropper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Shape Cropper Demo'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
              print("Button pressed. Opening image picker.");
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                print("Image selected: ${pickedFile.path}. Starting crop.");
                final bytes = await _cropper.cropOval(
                  sourcePath: pickedFile.path,
                  angle: 0, // Rotate 45 degrees
                  width: 150,
                  height: 300,
                );

                if (bytes != null) {
                  print("Image cropped successfully. Saving and displaying.");
                  // Save the cropped image to a file (optional)
                  final directory = await getApplicationDocumentsDirectory();
                  final croppedPath = '${directory.path}/cropped_image.png';
                  final croppedFile = File(croppedPath);
                  await croppedFile.writeAsBytes(bytes);
                  print("Cropped image saved at: $croppedPath");

                  // Display the cropped image

                  Navigator.push(context, MaterialPageRoute(builder: (context) => ResultPage(bytes: bytes)));

                } else {
                  print("Cropped bytes are null.");
                }
              }

          },

          child: Text('Select and Crop Image'),
        ),
      ),
    );
  }
}
