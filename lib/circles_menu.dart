import 'package:anim1/circle_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const String spKey = 'circleButtons';

class CirclesMenu extends StatefulWidget {
  final List<OpData> dataList;
  final VoidCallback onPressed;
  final VoidCallback onChange;

  CirclesMenu({Key? key, required this.dataList, required this.onPressed, required this.onChange});

  @override
  State<StatefulWidget> createState() => _CirclesMenuState();
}

class OpData {
  double x;
  double y;
  double radius;
  final String text;

  Map<String, dynamic> toMap() {
    return {'x': x, 'y': y, 'radius': radius, 'text': text};
  }

  OpData({
    required this.x,
    required this.y,
    required this.radius,
    required this.text,
  });

  Widget get widget {
    return Text(
      this.text,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white),
    );
  }

  Color get fillColor => Colors.blue;

  Color? get borderColor => null;
}

class _CirclesMenuState extends State<CirclesMenu> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        color: Colors.red.withAlpha(100),
        width: 2000,
        child: Stack(
            clipBehavior: Clip.none,
            children: widget.dataList
                    .map(
                      (d) => CircleMenuButton(
                        data: d,
                        onPressed: widget.onPressed,
                        onChange: widget.onChange,
                      ),
                    )
                    .toList()),
      ),
    );
  }
}
