import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../constant/app_colors.dart';

class ImageResizeScreen extends StatefulWidget {
  const ImageResizeScreen({super.key});

  @override
  State<ImageResizeScreen> createState() => _ImageResizeScreenState();
}

class _ImageResizeScreenState extends State<ImageResizeScreen> {
  ImagePicker imagePicker = ImagePicker();
  File? pickedImage;

  /// Pick and crop the image
  Future<void> pickAndCropImage() async {
    final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          pickedImage = File(croppedFile.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resize your Image")),
      body: Column(
        children: [
          // Show the selected image or a placeholder image
          pickedImage != null
              ? Image.file(pickedImage!) // Display the cropped image
              : Image.asset("lib/assets/images/photo.png", height: 200),
          const Spacer(),

          // Bottom buttons
          Container(
            color: AppColors.primary.withOpacity(0.3),
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: pickedImage != null
                      ? () {

                  }
                      : null, // Disable the button if no image is selected
                  child: const Text("Resize"),
                ),
                ElevatedButton(
                  onPressed: pickAndCropImage, // Pick and crop the image
                  child: const Text("Choose Image"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
