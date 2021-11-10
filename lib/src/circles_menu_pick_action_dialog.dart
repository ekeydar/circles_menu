import 'package:flutter/material.dart';

import 'circles_menu_models.dart';

Future<OpAction?> pickActionSimple(
  BuildContext context, {
  required ActionsCategory category,
  required ActionsProvider actionsProvider,
  required Set<String> curCodes,
  required CirclesMenuConfig config,
}) async {
  List<OpAction> catActions = actionsProvider
      .getActions()
      .where(
          (a) => actionsProvider.getActionCategoryCode(a.code) == category.code)
      .toList()
    ..sort((a1, a2) => a1.title.compareTo(a2.title));
  return await showDialog<OpAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PickActionDialog(
        actions: catActions,
        config: config,
        curCodes: curCodes,
      );
    },
  );
}

class PickActionDialog extends StatefulWidget {
  final List<OpAction> actions;
  final CirclesMenuConfig config;
  final Set<String> curCodes;

  PickActionDialog(
      {required this.actions, required this.curCodes, required this.config});

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
                            icon: Icon(Icons.clear)),
                      ),
                    )
                  ] +
                  widget.actions
                      .where((a) =>
                          _controller.text.length == 0 ||
                          a.title.contains(_controller.text))
                      .map((a) => ListTile(
                            title: Text(a.title),
                            trailing: widget.curCodes.contains(a.code)
                                ? Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  )
                                : null,
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
