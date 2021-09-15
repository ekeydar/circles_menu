import 'package:anim1/circles_menu_utils.dart';
import 'package:flutter/material.dart';

import 'circles_menu_models.dart';

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
      child: Container(
        width: widget.data.radius * 2,
        height: widget.data.radius * 2,
        color: Colors.green.withAlpha(100),
        child:
            Stack(children: <Widget>[_getMainButton()] + _getActionButtons()),
      ),
    );
  }

  List<Widget> _getActionButtons() {
    OpState d = widget.data;
    List<Widget> result = [];
    if (d.showActions && !d.isDragged) {
      result.add(CircleMenuActionButton(
        left: 0,
        top: 0,
        data: d,
        icon: Icon(Icons.color_lens_outlined),
        onPress: () async {
          Color? newColor = await pickColor(context,
              initialColor: d.fillColor, config: widget.config);
          if (newColor != null) {
            d.fillColor = newColor;
            d.showActions = false;
            widget.onChange();
          }
        },
      ));
      result.add(CircleMenuActionButton(
        right: 0,
        top: 0,
        data: d,
        icon: Icon(Icons.delete_outline),
        onPress: () {
          d.isDeleted = true;
          widget.onChange();
        },
      ));
      if (d.canIncrRadius) {
        result.add(CircleMenuActionButton(
          left: 0,
          bottom: 0,
          data: d,
          icon: Icon(Icons.zoom_in_outlined),
          onPress: () {
            d.radius += 5;
            widget.onChange();
          },
        ));
      }
      if (d.canDecrRadius) {
        result.add(CircleMenuActionButton(
          right: 0,
          bottom: 0,
          data: d,
          icon: Icon(Icons.zoom_out_outlined),
          onPress: () {
            d.radius -= 5;
            widget.onChange();
          },
        ));
      }
    }
    return result;
  }

  Widget _getMainButton() {
    return Positioned(
      top: 0,
      left: 0,
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
          onDragStarted: () {
              widget.data.isDragged = true;
              setState(() {

              });
          },
          onDragEnd: (details) {
            widget.data.isDragged = false;
            setState(() {
              // debugPrint('cx = $cx');
              widget.data.x = details.offset.dx + widget.controller.offset;
              widget.data.y = details.offset.dy - 80;
              widget.onChange();
            });
          },
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
      width: radius * 2,
      height: radius * 2,
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
  final VoidCallback onPress;
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
      required this.onPress});

  @override
  State<StatefulWidget> createState() => CircleMenuActionButtonState();
}

class CircleMenuActionButtonState extends State<CircleMenuActionButton> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      right: widget.right,
      bottom: widget.bottom,
      child: Align(
        alignment: Alignment.center,
        child: CircleButton(
          fillColor: Colors.red,
          borderColor: null,
          radius: 20,
          onPressed: widget.onPress,
          child: widget.icon,
        ),
      ),
    );
  }
}
