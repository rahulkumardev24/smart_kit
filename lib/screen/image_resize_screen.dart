import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:smart_kit/domain/uitils.dart';
import 'package:smart_kit/widgets/my_filled_button.dart';
import 'package:smart_kit/widgets/my_navigation_button.dart';
import 'package:smart_kit/widgets/my_outline_button.dart';

import '../constant/app_colors.dart';
import '../helper/dialogs.dart';

class ImageResizeScreen extends StatefulWidget {
  const ImageResizeScreen({super.key});

  @override
  State<ImageResizeScreen> createState() => _ImageResizeScreenState();
}

class _ImageResizeScreenState extends State<ImageResizeScreen> {
  ImagePicker imagePicker = ImagePicker();
  File? pickedImage;

  /// Pick and crop the image (unchanged logic)
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
        title: const Text("Image Resizer Pro"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: MyNavigationButton(
            btnIcon: Icons.arrow_back_ios_new_outlined,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Image display area with card and shadow
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.grey[50],
                height: MediaQuery.of(context).size.height * 0.6,
                width: double.infinity,
                child: pickedImage != null
                    ? InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3,
                  child: Image.file(
                    pickedImage!,
                    fit: BoxFit.contain,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "lib/assets/images/photo.png",
                      height: 150,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Select an image to resize",
                      style: myTextStyle22(textColor: Colors.black45)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tap the button below to choose from gallery",
                      style: myTextStyle22(textColor: Colors.black26),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),

          // Bottom action buttons with neumorphic design
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Download button with icon
                MyOutlineButton(
                  btnText: "Download",
                  onPressed: () async {
                    try {
                      await GallerySaver.saveImage(
                        pickedImage!.path,
                        albumName: 'Smart Kit',
                      ).then((success) {
                        if (success != null && success) {
                          Dialogs.myShowSnackBar(
                            context,
                            "Image saved to gallery!",
                            Colors.greenAccent.shade200,
                            Colors.black54,
                          );
                        }
                      });
                    } catch (e) {
                      print('ErrorWhileSavingImg: $e');
                    }
                  },
                ),

                // Select Image button with pulse animation
                TweenAnimationBuilder(
                  tween: Tween(begin: 1.0, end: 1.05),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value as double,
                      child: MyFilledButton(
                        btnText: "Select Image",
                        textWeight: FontWeight.bold,

                        onPressed: pickAndCropImage,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}