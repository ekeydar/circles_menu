import 'package:anim1/circles_menu_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Future<Color?> pickColor(BuildContext context, {required Color initialColor, required CircleMenuConfig config}) async {
  Color newColor = initialColor;
  return await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: newColor,
              onColorChanged: (Color c) {
                newColor = c;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: Text(config.cancel),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: Text(config.accept),
              onPressed: () {
                Navigator.of(context).pop(newColor);
              },
            ),
          ],
        );
      });
}