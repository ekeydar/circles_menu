import 'dart:math';

import 'package:flutter/material.dart';

import 'circles_menu_edit_button.dart';
import 'circles_menu_models.dart';
import 'circles_menu_utils.dart';

class MenuItemWidget extends StatefulWidget {
  final BaseMenuItemState data;
  final VoidCallback? onPressed;
  final VoidCallback onChange;
  final ScrollController controller;
  final CirclesMenuConfig config;
  final bool isInEdit;
  final Widget child;

  MenuItemWidget(
      {Key? key,
      required this.config,
      required this.isInEdit,
      required this.data,
      required this.onPressed,
      required this.onChange,
      required this.child,
      required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  @override
  Widget build(BuildContext context) {
    double cx = widget.data.x;
    double cy = widget.data.y;
    return Positioned(
      left: cx,
      top: cy,
      child: Container(
        width: widget.data.width,
        height: widget.data.height,
        //color: Colors.green.withAlpha(100),
        child:
            Stack(children: <Widget>[_getMainButton()] + _getActionButtons()),
      ),
    );
  }

  List<Widget> _getActionButtons() {
    BaseMenuItemState d = widget.data;
    List<Widget> result = [];
    double minSide = min(widget.data.width, widget.data.height);
    double innerRadius = min(minSide / 6, 20);
    //debugPrint('$minSide = $minSide $innerRadius = $innerRadius');
    if (widget.isInEdit && d.showActions && !d.isDragged) {
      result.add(
        CircleMenuActionButton(
          radius: innerRadius,
          left: 0,
          top: 0,
          icon: Icon(Icons.color_lens_outlined),
          onPressed: () async {
            Color? newColor = await pickColor(context,
                initialColor: d.color, config: widget.config);
            if (newColor != null) {
              d.color = newColor;
              d.showActions = false;
              widget.onChange();
            }
          },
        ),
      );

      if (widget.data is LabelMenuItemState)
        result.add(
          CircleMenuActionButton(
            radius: innerRadius,
            left: widget.data.width/2 - innerRadius,
            top: 0,
            icon: Icon(Icons.font_download_outlined),
            onPressed: () async {
              LabelMenuItemState ld = widget.data as LabelMenuItemState;
              String? newText = await editText(
                context,
                config: widget.config,
                initialText: ld.label,
              );
              if (newText != null) {
                ld.label = newText;
                widget.onChange();
              }
            },
          ),
        );
      result.add(
        CircleMenuActionButton(
          radius: innerRadius,
          left: widget.data.width - 2 * innerRadius,
          top: 0,
          icon: Icon(Icons.delete_outline),
          onPressed: () {
            d.isDeleted = true;
            widget.onChange();
          },
        ),
      );
      if (d.canIncr) {
        result.add(CircleMenuActionButton(
          radius: innerRadius,
          left: 0,
          top: widget.data.height - 2 * innerRadius,
          icon: Icon(Icons.zoom_in_outlined),
          onPressed: () {
            d.incr();
            widget.onChange();
          },
        ));
      }
      if (d.canDecr) {
        result.add(CircleMenuActionButton(
          radius: innerRadius,
          top: widget.data.height - 2 * innerRadius,
          left: widget.data.width - 2 * innerRadius,
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
    BaseMenuItemState d = widget.data;
    VoidCallback? onPressed =
        d is ActionMenuItemState ? d.action.onPressed : null;
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
                  child: widget.child,
                ),
                child: widget.child,
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
              child: GestureDetector(
                onTap: onPressed,
                child: widget.child,
              ),
            ),
    );
  }
}
