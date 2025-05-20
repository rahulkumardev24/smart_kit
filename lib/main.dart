import 'package:flutter/material.dart';
import 'package:smart_kit/screen/image_background_remove_screen.dart';
import 'package:smart_kit/screen/pdf_to_image_screen.dart';


import 'home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:ImageBackgroundRemoveScreen()
    );
  }
}

