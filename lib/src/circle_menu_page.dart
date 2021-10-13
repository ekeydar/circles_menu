import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CircleMenuPage extends StatelessWidget {
  final List<Widget> items;
  final Widget buttons;
  final Color color;
  final int index;

  CircleMenuPage({
    required this.items,
    required this.buttons,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kDebugMode ? Colors.red.withAlpha(100) : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [this.buttons] + this.items,
      ),
    );
  }
}
