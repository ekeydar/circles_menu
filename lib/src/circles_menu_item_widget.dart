import 'package:flutter/material.dart';

import 'circles_menu_models.dart';
import 'circles_menu_utils.dart';
import 'edit_action_dialog.dart';

class MenuItemWidget extends StatefulWidget {
  final BaseMenuItemState data;
  final VoidCallback? onPressed;
  final VoidCallback onChange;
  final CirclesMenuConfig config;
  final bool isInEdit;
  final Widget child;

  MenuItemWidget({
    Key? key,
    required this.config,
    required this.isInEdit,
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
      if (widget.data is LabelMenuItemState)
        StateAction(
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
      StateAction(
        icon: Icon(Icons.delete_outline),
        onPressed: () {
          d.isDeleted = true;
          widget.onChange();
        },
        popAfterPress: true,
      ),
      StateAction(
          icon: Icon(Icons.add),
          onPressed: () {
            d.incr();
            widget.onChange();
          },
          enabledCallback: () => d.canIncr),
      StateAction(
        enabledCallback: () => d.canDecr,
        icon: Icon(Icons.remove),
        onPressed: () {
          d.decr();
          widget.onChange();
        },
      ),
    ];
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
              onLongPress: () async {
                await showEditItemDialog(
                  context: context,
                  data: widget.data,
                  actions: _getStateActions(),
                );
                //widget.data.showActions = !widget.data.showActions;
                //widget.onChange();
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
