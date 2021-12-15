import 'dart:math';

import 'package:flutter/material.dart';

import 'circles_menu_models.dart';

class MenuItemWidget extends StatefulWidget {
  final ActionMenuItemState data;
  final VoidCallback onChange;
  final EditChangedCallback onEditChange;
  final CirclesMenuConfig config;
  final bool isReadonly;
  final Widget child;

  const MenuItemWidget({
    Key? key,
    required this.config,
    required this.isReadonly,
    required this.data,
    required this.onChange,
    required this.child,
    required this.onEditChange,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  Offset? dragOffset;

  @override
  Widget build(BuildContext context) {
    double cx = widget.data.x;
    double cy = widget.data.y;
    return Positioned(
      left: cx,
      top: cy,
      // ignore: sized_box_for_whitespace
      child: Container(
        //color: Colors.green,
        width: widget.data.width,
        height: widget.data.height,
        //color: Colors.green.withAlpha(100),
        child: Stack(
          children: <Widget>[
            _getMainButton(),
          ],
        ),
      ),
    );
  }

  Widget _getMainButton() {
    ActionMenuItemState d = widget.data;
    return Positioned(
      top: 0,
      left: 0,
      child: GestureDetector(
        onTap: d.actionsProvider.isDisabled(d.action.code)
            ? null
            : () {
                debugPrint('HERE');
                d.actionsProvider.actionPressed(d.action.code);
              },
        child: widget.isReadonly
            ? widget.child
            : LongPressDraggable(
                feedback: Container(
                  child: widget.child,
                ),
                child: widget.child,
                childWhenDragging: Container(),
                onDragStarted: () {
                  widget.data.isDragged = true;
                  widget.onEditChange(widget.data, isStart: true);
                  dragOffset = null;
                },
                onDragUpdate: (DragUpdateDetails details) {
                  if (dragOffset == null) {
                    dragOffset = details.globalPosition;
                  } else {
                    double distX =
                        pow(details.globalPosition.dx - dragOffset!.dx, 2)
                            .toDouble();
                    double distY =
                        pow(details.globalPosition.dy - dragOffset!.dy, 2)
                            .toDouble();
                    double dist = sqrt(distX + distY);
                    if (dist > 30) {
                      widget.data.showEditBox = false;
                      widget.onChange();
                    }
                  }
                },
                onDragEnd: (DraggableDetails details) {
                  widget.data.isDragged = false;
                  setState(() {
                    // double w = MediaQuery.of(context).size.width;
                    // debugPrint('w = $w details.offset = ${details.offset} widget.controller.offset = ${widget.controller.offset}');
                    // bool isRtl =
                    //     Directionality.of(context) == TextDirection.rtl;
                    double newX =
                        details.offset.dx; // # + widget.controller.offset;
                    // if (isRtl) {
                    //   newX = w - newX;
                    // }
                    widget.data.x = newX;
                    widget.data.y = details.offset.dy - 80;
                    widget.onChange();
                  });
                },
              ),
      ),
    );
  }
}
