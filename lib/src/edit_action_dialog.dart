import 'package:flutter/material.dart';

import '../circles_menu.dart';

class EditItemDialog extends StatefulWidget {
  final BaseMenuItemState data;
  final List<StateAction> actions;

  EditItemDialog({Key? key, required this.data, required this.actions});

  @override
  State<StatefulWidget> createState() {
    return _EditItemDialogState();
  }
}

class _EditItemDialogState extends State<EditItemDialog> {
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.all(0),
      titlePadding: EdgeInsets.all(8.0),
      title: Text(
        widget.data.title,
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      children: [
        Container(
          color: Theme.of(context).primaryColorLight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < widget.actions.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 16,
                    width: 3,
                    color: Colors.white,
                  ),
                MenuButton(
                  icon: widget.actions[i].icon,
                  enabled: widget.actions[i].enabledCallback != null
                      ? widget.actions[i].enabledCallback!()
                      : true,
                  onPressed: () async {
                    await widget.actions[i].callback();
                    setState(() {});
                    if (widget.actions[i].popAfterPress) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ]
            ],
          ),
        )
      ],
    );
  }
}

class MenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Icon icon;
  final bool enabled;

  MenuButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.all(0),
      onPressed: enabled ? onPressed : null,
      icon: icon,
      iconSize: 20,
    );
  }
}

Future<void> showEditItemDialog(
    {required BuildContext context,
    required BaseMenuItemState data,
    required List<StateAction> actions}) async {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation animation,
        Animation secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            child: EditItemDialog(data: data, actions: actions),
            top: data.y > 60 ? data.y - 30 : data.y + data.height + 60,
            left: 10,
          )
        ],
      );
    },
  );
}
