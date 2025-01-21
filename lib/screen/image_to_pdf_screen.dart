import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_kit/widgets/my_navigation_button.dart';

import '../constant/app_colors.dart';
import '../domain/uitils.dart';
import '../widgets/my_filled_button.dart';
import '../widgets/my_outline_button.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _imageList = [];
  final pdf = pw.Document();
  File? _pdfFile;

  /// Function to get images from the gallery
  Future<void> getImageFromGallery() async {
    final pickedImages = await _imagePicker.pickMultiImage();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _imageList.addAll(pickedImages.map((e) => File(e.path)));
      });
    }
  }

  /// Function to create a PDF and save it locally
  Future<void> createPDF() async {
    for (var img in _imageList) {
      final image = pw.MemoryImage(img.readAsBytesSync());
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
                width: double.infinity,
                height: double.infinity,
                child: pw.Image(image, fit: pw.BoxFit.cover));
          },
        ),
      );
    }

    /// Save the PDF file to local storage
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/converted_images.pdf');
      await file.writeAsBytes(await pdf.save());
      setState(() {
        _pdfFile = file;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "PDF Created Successfully!",
            style: myTextStyle18(
              textColor: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to Create PDF!",
            style: myTextStyle18(
              textColor: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// View PDF
  void viewPDF(File file) async {
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Converter"),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: MyNavigationButton(
            btnIcon: Icons.arrow_back_ios_new_outlined,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _imageList.isNotEmpty
                ? GridView.builder(
                    itemCount: _imageList.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(
                            _imageList[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text("No Image Selected"),
                  ),
          ),
          _pdfFile != null
              ? MyOutlineButton(
                  btnText: "View and Download",
                  textWeight: FontWeight.bold,
                  btnBackground: AppColors.primaryLight.withOpacity(0.8),
                  borderRadius: 8,
                  onPressed: () => viewPDF(_pdfFile!),
                )
              : const SizedBox(),
         const  SizedBox(height: 20,),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: AppColors.primary.withOpacity(0.3),
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  MyOutlineButton(
                      btnText: "Convert",
                      onPressed: () {
                        if (_imageList.isEmpty) {
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
                        } else {
                          createPDF();
                        }
                      }),
                  MyFilledButton(
                      btnText: "Select Image",
                      textWeight: FontWeight.bold,
                      onPressed: getImageFromGallery),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
