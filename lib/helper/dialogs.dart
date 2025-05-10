import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../domain/uitils.dart';

class Dialogs {
  static void myShowSnackBar(
    BuildContext context,
    String title,
    Color backgroundColor,
    Color textColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          title,
          style: myTextStyle18(),
        ),
        backgroundColor: backgroundColor,
      ),
    );


  }
/// Circular progressbar
static void myShowProgressbar(BuildContext context){
    showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Center(
        child: CircularProgressIndicator(),
      );
    },
  );

}
}
