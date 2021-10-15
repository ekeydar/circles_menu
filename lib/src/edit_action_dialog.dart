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
      //insetPadding: insetPadding,
      title: Text(widget.data.title),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var action in widget.actions)
                MenuButton(
                  icon: action.icon,
                  enabled: action.enabledCallback != null
                      ? action.enabledCallback!()
                      : true,
                  onPressed: () {
                    action.onPressed();
                    setState(() {});
                  },
                )
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).primaryColor,
        //textStyle: TextStyle(color: Theme.of(context).primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.0),
        ),
      ),
      child: icon,
      onPressed: enabled ? onPressed : null,
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
              top: data.y,
              left: 10,
            )
          ],
        );
      });
}
