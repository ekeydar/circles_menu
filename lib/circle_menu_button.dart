import 'package:anim1/circles_menu.dart';
import 'package:flutter/material.dart';

class CircleMenuButton extends StatefulWidget {
  final OpData data;
  final VoidCallback? onPressed;

  CircleMenuButton({Key? key, required this.data, required this.onPressed}) : super(key: key);

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
      child: Draggable(
        feedback: Container(
          child: CircleButton(
            radius: this.radius,
            child: widget.data.widget,
            onPressed: null,
          ),
        ),
        child: CircleButton(
          radius: this.radius,
            child: widget.data.widget,
            onPressed: widget.onPressed,
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            cx = details.offset.dx;
            cy = details.offset.dy;
            widget.data.x = cx;
            widget.data.y = cy;
          });
        },
      ),
    );
  }
}

class CircleButton extends StatelessWidget {
  final double radius;
  final Widget child;
  final VoidCallback? onPressed;
  CircleButton({required this.radius, required this.child, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      child: new RawMaterialButton(
        fillColor: Colors.blue,
        shape: new CircleBorder(),
        elevation: 0.0,
        child: child,
        onPressed: onPressed,
      ),
    );
  }
}
