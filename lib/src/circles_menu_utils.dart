import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'circles_menu_models.dart';

Future<Color?> pickColor(BuildContext context,
    {required Color initialColor, required CirclesMenuConfig config}) async {
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
    },
  );
}

Future<String?> editText(BuildContext context,
    {String? initialText,
    required CirclesMenuConfig config,
    required String title}) async {
  TextEditingController controller = TextEditingController(text: initialText);
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: IconButton(
                onPressed: () {
                  controller.text = '';
                },
                icon: const Icon(Icons.clear)),
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
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      );
    },
  );
}

List<Widget> reverseIfTrue(bool cond, List<Widget> l) {
  return cond ? l.reversed.toList() : l;
}
