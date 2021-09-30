import 'package:circles_menu/src/circle_box.dart';
import 'package:flutter/material.dart';


class CircleMenuActionButton extends StatefulWidget {
  final Icon icon;
  final VoidCallback onPressed;
  final double radius;
  final double top;
  //final double? right;
  //final double? bottom;
  final double left;

  CircleMenuActionButton(
      {Key? key,
        required this.icon,
        required this.top,
        //this.right,
        required this.left,
        //this.bottom,
        required this.radius,
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
