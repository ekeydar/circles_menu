import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CircleMenuPage extends StatelessWidget {
  final List<Widget> items;
  final List<Widget> buttons;
  final Color color;
  final int index;

  CircleMenuPage({
    required Key key,
    required this.items,
    required this.buttons,
    required this.color,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kDebugMode ? this.color.withAlpha(100) : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: this.buttons + this.items,
      ),
    );
  }
}
