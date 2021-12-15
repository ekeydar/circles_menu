import 'package:flutter/material.dart';

import 'circle_box.dart';


class CircleMenuActionButton extends StatefulWidget {
  final Icon icon;
  final VoidCallback onPressed;
  final double radius;
  final double top;
  //final double? right;
  //final double? bottom;
  final double left;

  const CircleMenuActionButton(
      {Key? key,
      required this.icon,
      required this.top,
      required this.left,
      required this.radius,
      required this.onPressed})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CircleMenuActionButtonState();
}

class _CircleMenuActionButtonState extends State<CircleMenuActionButton> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      //right: widget.right,
      //bottom: widget.bottom,
      child: Align(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: CircleBox(
            fillColor: Colors.red,
            borderColor: null,
            radius: widget.radius,
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}
