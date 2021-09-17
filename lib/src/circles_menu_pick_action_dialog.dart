import 'package:flutter/material.dart';

import 'circles_menu_models.dart';

class PickActionDialog extends StatefulWidget {
  final List<OpAction> actions;
  final CircleMenuConfig config;
  PickActionDialog({required this.actions, required this.config});

  @override
  State<StatefulWidget> createState() => _PickActionDialogState();
}


class _PickActionDialogState extends State<PickActionDialog> {
  late TextEditingController _controller;
  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actions: [
        TextButton(
          child: Text(widget.config.cancel),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
      ],
      title: Text(widget.config.pickAction),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
              children: <Widget>[
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                        onPressed: () {
                          _controller.text = '';
                          setState(() {});
                        },
                        icon: Icon(Icons.clear)
                    ),
                  ),
                )
              ] + widget.actions
                  .where((a) => _controller.text.length == 0 || a.title.contains(_controller.text))
                  .map((a) =>
                  ListTile(
                    title: Text(a.title),
                    onTap: () {
                      Navigator.of(context).pop(a);
                    },
                  ))
                  .toList()),
        ),
      ),
    );
  }
}