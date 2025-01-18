import 'package:flutter/material.dart';

import '../constant/app_colors.dart';

class MyOutlineButton extends StatefulWidget {
  String btnText;
  FontWeight? textWeight;
  Color? btnBackground;
  Color? btnTextColor;
  double? btnTextSize;
  VoidCallback onPressed;
  double? borderRadius;
  MyOutlineButton(
      {super.key,
        this.btnBackground = Colors.white,
        required this.btnText,
        required this.onPressed,
        this.btnTextColor = Colors.black,
        this.textWeight = FontWeight.normal,
        this.btnTextSize = 18 ,
        this.borderRadius = 16 ,
      });

  @override
  State<MyOutlineButton> createState() => _MyFilledButtonState();
}

class _MyFilledButtonState extends State<MyOutlineButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: widget.btnBackground,
            side: BorderSide(width: 2 , color: AppColors.primary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius!))),
        child: Text(
          widget.btnText,
          style: TextStyle(
              fontWeight: widget.textWeight,
              color: widget.btnTextColor,
              fontSize: widget.btnTextSize),
        ));
  }
}
