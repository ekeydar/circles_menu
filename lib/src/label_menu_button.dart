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
    return Container(
      height: widget.data.height,
      width: widget.data.width,
      color: Colors.purple.withAlpha(30),
      child: Text(
          widget.data.label
      ),
    );
  }
}
