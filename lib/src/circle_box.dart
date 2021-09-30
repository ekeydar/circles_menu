import 'package:flutter/material.dart';

class CircleBox extends StatelessWidget {
  final double radius;
  final Widget child;
  final Color fillColor;
  final Color? borderColor;

  CircleBox(
      {required this.radius,
      required this.child,
      required this.fillColor,
      required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
      ),
      child: Center(
        child: child,
      ),
    );
  }
}
