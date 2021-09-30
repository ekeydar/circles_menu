import 'package:flutter/material.dart';

import 'circles_menu_models.dart';
import 'circles_menu_utils.dart';

class CircleMenuButton extends StatefulWidget {
  final OpState data;
  final VoidCallback? onPressed;
  final VoidCallback onChange;
  final ScrollController controller;
  final CirclesMenuConfig config;
  final bool isInEdit;

  CircleMenuButton(
      {Key? key,
      required this.config,
      required this.isInEdit,
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
        //color: Colors.green.withAlpha(100),
        child:
            Stack(children: <Widget>[_getMainButton()] + _getActionButtons()),
      ),
    );
  }

  List<Widget> _getActionButtons() {
    OpState d = widget.data;
    List<Widget> result = [];
    if (widget.isInEdit && d.showActions && !d.isDragged) {
      result.add(CircleMenuActionButton(
        left: 0,
        top: 0,
        data: d,
        icon: Icon(Icons.color_lens_outlined),
        onPressed: () async {
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
        onPressed: () {
          d.isDeleted = true;
          widget.onChange();
        },
      ));
      if (d.canIncr) {
        result.add(CircleMenuActionButton(
          left: 0,
          bottom: 0,
          data: d,
          icon: Icon(Icons.zoom_in_outlined),
          onPressed: () {
            d.incr();
            widget.onChange();
          },
        ));
      }
      if (d.canDecr) {
        result.add(CircleMenuActionButton(
          right: 0,
          bottom: 0,
          data: d,
          icon: Icon(Icons.zoom_out_outlined),
          onPressed: () {
            d.decr();
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
      child: widget.isInEdit
          ? GestureDetector(
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
                    fillColor: widget.data.actualFillColor,
                    borderColor: widget.data.borderColor,
                  ),
                ),
                child: CircleButton(
                  radius: widget.data.radius,
                  child: widget.data.widget,
                  onPressed: null,
                  fillColor: widget.data.actualFillColor,
                  borderColor: widget.data.borderColor,
                ),
                childWhenDragging: Container(),
                onDragStarted: () {
                  widget.data.isDragged = true;
                  setState(() {});
                },
                onDragEnd: (details) {
                  widget.data.isDragged = false;
                  setState(() {
                    // debugPrint('details.offset = ${details.offset} widget.controller.offset = ${widget.controller.offset}');
                    double w = MediaQuery.of(context).size.width;
                    // debugPrint('width = $w');
                    bool isRtl =
                        Directionality.of(context) == TextDirection.rtl;
                    double offset = isRtl
                        ? w - widget.controller.offset
                        : widget.controller.offset;
                    widget.data.x = details.offset.dx + offset;
                    widget.data.y = details.offset.dy - 80;
                    widget.onChange();
                  });
                },
              ),
            )
          : GestureDetector(
              onLongPress: () {
                final snackBar = SnackBar(
                  content: Text(widget.config.moveToEditMessage),
                  backgroundColor: Colors.red,
                  duration: Duration(milliseconds: 1000),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              child: CircleButton(
                radius: widget.data.radius,
                child: widget.data.widget,
                onPressed: widget.data.action.enabled ? widget.onPressed : null,
                fillColor: widget.data.actualFillColor,
                borderColor: widget.data.borderColor,
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
          onPressed: widget.onPressed,
          child: widget.icon,
        ),
      ),
    );
  }
}
