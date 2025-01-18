import 'package:flutter/material.dart';
import 'package:smart_kit/domain/uitils.dart';
import 'package:smart_kit/screen/image_resize_screen.dart';
import 'package:smart_kit/screen/image_to_pdf_screen.dart';

import 'constant/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> tool = [
    {"title": "Resize", "image": "lib/assets/images/resize.png"},
    {"title": "PDF Converter", "image": "lib/assets/images/pdf-file-format.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Title"),
          backgroundColor: Colors.white,
        ),
        body: GridView.builder(
            itemCount: tool.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 3 / 3),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: (){
                  if(tool[index]['title'] == "Resize"){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageResizeScreen()));
                  }
                  if(tool[index]['title'] == "PDF Converter"){
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>const ImageToPdfScreen() ));

                  }
                },
                child: Column(
                  children: [
                    Card(
                      color: Colors.white,
                      elevation: 7,
                      shadowColor: AppColors.primaryLight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(tool[index]['image'] , height: 100,),
                      ),
                    ),
                    Text(
                      tool[index]['title'],
                      style: myTextStyle26(fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              );
            }));
  }
}
