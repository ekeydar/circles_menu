import 'package:flutter/material.dart';

import 'circle_menu_models.dart';

class CircleMenuButton extends StatefulWidget {
  final OpState data;
  final VoidCallback? onPressed;
  final VoidCallback onChange;
  final ScrollController controller;
  final CircleMenuConfig config;

  CircleMenuButton(
      {Key? key,
      required this.config,
      required this.data,
      required this.onPressed,
      required this.onChange,
      required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CircleMenuButtonState();
}

class _CircleMenuButtonState extends State<CircleMenuButton> {
  // @override
  // void initState() {
  //   cx = this.widget.data.x;
  //   cy = this.widget.data.y;
  //   radius = this.widget.data.radius;
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    double cx = widget.data.x;
    double cy = widget.data.y;
    return Positioned(
      left: cx,
      top: cy,
      child: Align(
        child: GestureDetector(
          onLongPress: () {
              widget.data.showActions = !widget.data.showActions;
              widget.onChange();
          },
          child: Draggable(
            feedback: Container(
              child: CircleButton(
                radius: widget.data.radius,
                child: widget.data.widget,
                onPressed: null,
                fillColor: widget.data.fillColor,
                borderColor: widget.data.borderColor,
              ),
            ),
            child: CircleButton(
              radius: widget.data.radius,
              child: widget.data.widget,
              onPressed: widget.onPressed,
              fillColor: widget.data.fillColor,
              borderColor: widget.data.borderColor,
            ),
            childWhenDragging: Container(),
            onDragEnd: (details) {
              setState(() {
                // debugPrint('cx = $cx');
                widget.data.x = details.offset.dx + widget.controller.offset;
                widget.data.y = details.offset.dy - 80;
                widget.onChange();
              });
            },
          ),
        ),
      ),
    );
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

class CircleMenuActionButton extends StatefulWidget {
  final Icon icon;
  final OpState data;
  final int index;
  final VoidCallback onPress;
  CircleMenuActionButton({Key? key, required this.icon, required this.data, required this.index, required this.onPress});

  @override
  State<StatefulWidget> createState() => CircleMenuActionButtonState();
}

class CircleMenuActionButtonState extends State<CircleMenuActionButton> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: widget.index < 2 ? widget.data.y - 20 : widget.data.y + widget.data.radius - 20,
        left: (widget.index % 2) == 0 ? widget.data.x : widget.data.x + widget.data.radius - 40,
        child: Align(
          alignment: Alignment.center,
          child: CircleButton(
            fillColor: Colors.red,
            borderColor: null,
            radius: 40,
            onPressed: widget.onPress,
            child: widget.icon,
          ),
        ),
    );
  }

}