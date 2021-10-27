import 'package:flutter/material.dart';

import '../circles_menu.dart';

class EditItemDialog extends StatefulWidget {
  final ActionMenuItemState data;
  final List<StateAction> actions;
  final EditChangedCallback onEditChange;

  EditItemDialog({
    Key? key,
    required this.data,
    required this.actions,
    required this.onEditChange,
  });

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
      title: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              widget.onEditChange(
                widget.data,
                isStart: false,
              );
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.data.title,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
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
