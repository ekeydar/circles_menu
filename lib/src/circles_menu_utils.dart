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
    },
  );
}

Future<String?> editText(BuildContext context,
    {String? initialText, required CirclesMenuConfig config}) async {
  TextEditingController controller = TextEditingController(text: initialText);
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(config.editLabelTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            suffixIcon: IconButton(
                onPressed: () {
                  controller.text = '';
                },
                icon: Icon(Icons.clear)),
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

Future<double?> editSize(BuildContext context,
    {required double curSize,
    required double minSize,
    required double maxSize,
    required CirclesMenuConfig config}) async {
  return await showDialog<double>(
    context: context,
    builder: (context) {
      return EditSizeDialog(
        minSize: minSize,
        maxSize: maxSize,
        initialSize: curSize,
        config: config,
      );
    },
  );
}

class EditSizeDialog extends StatefulWidget {
  final double initialSize;
  final double minSize;
  final double maxSize;
  final CirclesMenuConfig config;

  EditSizeDialog(
      {Key? key,
      required this.config,
      required this.initialSize,
      required this.minSize,
      required this.maxSize})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _EditSizeDialogState();
}

class _EditSizeDialogState extends State<EditSizeDialog> {
  late double _result;

  @override
  void initState() {
    _result = widget.initialSize;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actions: [
        TextButton(
          child: Text(widget.config.cancel),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        TextButton(
          child: Text(widget.config.accept),
          onPressed: () {
            Navigator.of(context).pop(_result);
          },
        ),
      ],
      title: Text(widget.config.editSizeTitle),
      content: Column(
        children: [
          Text(
            _result.toString(),
          ),
          Slider(
            value: _result.toDouble(),
            min: widget.minSize.toDouble(),
            max: widget.maxSize.toDouble(),
            onChanged: (double v) {
              setState(
                () {
                  _result = v;
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
