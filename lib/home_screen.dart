import 'package:flutter/material.dart';

import 'constant/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> tool = [
    {"title": "Resize", "image": "lib/assets/images/resize.png"}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Title"),
          backgroundColor: Colors.white,
        ),
        body: GridView.builder(
            itemCount: tool.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 3 / 6),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 7,
                    shadowColor: AppColors.primaryLight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(tool[index]['image']),
                    ),
                  ),
                  Text(
                    tool[index]['title'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 32),
                  )
                ],
              );
            }));
  }
}
