import 'package:circles_menu/src/circle_box.dart';
import 'package:flutter/material.dart';

import 'circles_menu_models.dart';

class CircleMenuActionButton extends StatefulWidget {
  final Icon icon;
  final ActionMenuItemState data;
  final VoidCallback onPressed;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  CircleMenuActionButton(
      {Key? key,
        required this.icon,
        required this.data,
        this.top,
        this.right,
        this.left,
        this.bottom,
        required this.onPressed});

  @override
  State<StatefulWidget> createState() => _CircleMenuActionButtonState();
}

class _CircleMenuActionButtonState extends State<CircleMenuActionButton> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      right: widget.right,
      bottom: widget.bottom,
      child: Align(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: CircleBox(
            fillColor: Colors.red,
            borderColor: null,
            radius: 20,
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}
