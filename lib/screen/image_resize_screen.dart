import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:smart_kit/domain/uitils.dart';
import 'package:smart_kit/widgets/my_filled_button.dart';
import 'package:smart_kit/widgets/my_navigation_button.dart';
import 'package:smart_kit/widgets/my_outline_button.dart';

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
    final XFile? image =
        await imagePicker.pickImage(source: ImageSource.gallery);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Resize your Image"),
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: MyNavigationButton(btnIcon: Icons.arrow_back_ios_new_outlined, onPressed: () { Navigator.pop(context); },),
        ),
      ),
      body: Column(
        children: [
          pickedImage != null
              ? Image.file(pickedImage!)
              : Column(
                  children: [
                    Image.asset("lib/assets/images/photo.png", height: 200),
                    Text(
                      "Plz select the image ",
                      style: myTextStyle22(textColor: Colors.black45),
                    )
                  ],
                ),
          const Spacer(),

          // Bottom buttons
          Container(
            color: AppColors.primary.withOpacity(0.3),
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                MyOutlineButton(
                    btnText: "Download",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "First Select The Image",
                            style: myTextStyle18(
                              textColor: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }),
                MyFilledButton(
                    btnText: "Select Image",
                    textWeight: FontWeight.bold,
                    onPressed: pickAndCropImage)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
