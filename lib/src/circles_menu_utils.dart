import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'circles_menu_models.dart';

Future<Color?> pickColor(BuildContext context, {required Color initialColor, required CirclesMenuConfig config}) async {
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