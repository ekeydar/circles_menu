import 'package:flutter/material.dart';

import 'circles_menu_models.dart';
import 'circles_menu_utils.dart';
import 'edit_action_dialog.dart';

class MenuItemWidget extends StatefulWidget {
  final ActionMenuItemState data;
  final VoidCallback? onPressed;
  final VoidCallback onChange;
  final CirclesMenuConfig config;
  final bool isReadonly;
  final Widget child;

  MenuItemWidget({
    Key? key,
    required this.config,
    required this.isReadonly,
    required this.data,
    required this.onPressed,
    required this.onChange,
    required this.child,
  }) : super(key: key);

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
        //color: Colors.green,
        width: widget.data.width,
        height: widget.data.height,
        //color: Colors.green.withAlpha(100),
        child: Stack(children: <Widget>[_getMainButton()]),
      ),
    );
  }

  List<StateAction> _getStateActions() {
    BaseMenuItemState d = widget.data;
    return [
      StateAction(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).errorColor,
        ),
        callback: () async {
          d.isDeleted = true;
          widget.onChange();
        },
        popAfterPress: true,
      ),
      StateAction(
        icon: Icon(Icons.color_lens_outlined),
        callback: () async {
          Color? newColor = await pickColor(context,
              initialColor: d.color, config: widget.config);
          if (newColor != null) {
            d.color = newColor;
            widget.onChange();
          }
        },
      ),
      StateAction(
          icon: Icon(Icons.add),
          callback: () async {
            d.incr();
            widget.onChange();
          },
          enabledCallback: () => d.canIncr),
      StateAction(
        enabledCallback: () => d.canDecr,
        icon: Icon(Icons.remove),
        callback: () async {
          d.decr();
          widget.onChange();
        },
      ),
    ];
  }

  Widget _getMainButton() {
    ActionMenuItemState d = widget.data;
    return Positioned(
      top: 0,
      left: 0,
      child: GestureDetector(
        onTap: () {
          d.action.onPressed();
        },
        onLongPress: widget.isReadonly
            ? null
            : () async {
                await showEditItemDialog(
                  context: context,
                  data: widget.data,
                  actions: _getStateActions(),
                );
                //widget.data.showActions = !widget.data.showActions;
                //widget.onChange();
              },
        child: widget.isReadonly
            ? widget.child
            : Draggable(
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
