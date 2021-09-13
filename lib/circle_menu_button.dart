import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'circle_menu_models.dart';

class CircleMenuButton extends StatefulWidget {
  final OpData data;
  final VoidCallback? onPressed;
  final VoidCallback onChange;
  final ScrollController controller;

  CircleMenuButton(
      {Key? key,
      required this.data,
      required this.onPressed,
      required this.onChange,
      required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CircleMenuButtonState();
}

class _CircleMenuButtonState extends State<CircleMenuButton> {
  late double cx;
  late double cy;
  late double radius;

  @override
  void initState() {
    cx = this.widget.data.x;
    cy = this.widget.data.y;
    radius = this.widget.data.radius;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: cx,
      top: cy - 80,
      child: GestureDetector(
        onLongPress: () async {
          debugPrint('long pressed');
          String? result = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(cx + 10, cy + 10, cx + 10, cy + 10),
            items: [
              PopupMenuItem<String>(
                  child: const Text('Delete'), value: 'delete'),
              PopupMenuItem<String>(
                  child: const Text('Change color'), value: 'color'),
            ],
            elevation: 8.0,
          );
          if (result == 'delete') {
            widget.data.isDeleted = true;
            widget.onChange();
          }
          if (result == 'color') {
            Color? c = await pickColor();
            if (c != null) {
              widget.data.fillColor = c;
              widget.onChange();
            }
          }
        },
        child: Draggable(
          feedback: Container(
            child: CircleButton(
              radius: this.radius,
              child: widget.data.widget,
              onPressed: null,
              fillColor: widget.data.fillColor,
              borderColor: widget.data.borderColor,
            ),
          ),
          child: CircleButton(
            radius: this.radius,
            child: widget.data.widget,
            onPressed: widget.onPressed,
            fillColor: widget.data.fillColor,
            borderColor: widget.data.borderColor,
          ),
          childWhenDragging: Container(),
          onDragEnd: (details) {
            setState(() {
              cx = details.offset.dx + widget.controller.offset;
              cy = details.offset.dy;
              // debugPrint('cx = $cx');
              widget.data.x = cx;
              widget.data.y = cy;
              widget.onChange();
            });
          },
        ),
      ),
    );
  }

  Future<Color?> pickColor() async {
    Color newColor = widget.data.fillColor;
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
                child: Text('cancel'),
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
              ),
              TextButton(
                child: Text('accept'),
                onPressed: () {
                  Navigator.of(context).pop(newColor);
                },
              ),
            ],
          );
        });
  }
}

class CircleButton extends StatelessWidget {
  final double radius;
  final Widget child;
  final VoidCallback? onPressed;
  final Color fillColor;
  final Color? borderColor;

  CircleButton(
      {required this.radius,
      required this.child,
      required this.onPressed,
      required this.fillColor,
      required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      child: new RawMaterialButton(
        fillColor: fillColor,
        shape: new CircleBorder(
            side: borderColor != null
                ? BorderSide(
                    color: borderColor!,
                    width: 3,
                  )
                : BorderSide.none),
        elevation: 0.0,
        child: child,
        onPressed: onPressed,
      ),
    );
  }
}
