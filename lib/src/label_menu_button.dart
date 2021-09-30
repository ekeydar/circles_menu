import 'package:flutter/material.dart';

import 'circles_menu_models.dart';

class LabelMenuButton extends StatefulWidget {
  final LabelMenuItemState data;
  final VoidCallback onChange;
  final ScrollController controller;
  final CirclesMenuConfig config;
  final bool isInEdit;

  LabelMenuButton(
      {Key? key,
      required this.config,
      required this.isInEdit,
      required this.data,
      required this.onChange,
      required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LabelMenuButtonState();
}

class _LabelMenuButtonState extends State<LabelMenuButton> {
  @override
  Widget build(BuildContext context) {
    double cx = widget.data.x;
    double cy = widget.data.y;
    return Positioned(
      left: cx,
      top: cy,
      child: Container(
        height: widget.data.fontSize + 50,
        width: 100,
        color: Colors.purple.withAlpha(30),
        child:
            Stack(children: <Widget>[_getMainButton()] + _getActionButtons()),
      ),
    );
  }

  List<Widget> _getActionButtons() {
    return [];
  }

  Widget _getMainButton() {
    return Positioned(
      top: 0,
      left: 0,
      child: TextButton(
        child: Text(
          widget.data.label,
        ),
        onPressed: null,
      ),
    );
  }
}
