import 'package:flutter/material.dart';

import 'circles_menu_models.dart';

Future<bool> askConfirmation(BuildContext context,  String msg, {required CircleMenuConfig config}) async {
    return await showDialog<bool>(context: context, builder: (BuildContext context) {
        return AlertDialog(
            title: Text(config.approveDialogTitle),
            content: Text(msg),
            actions: [
                TextButton(
                    child: Text(config.accept),
                    onPressed: () {
                        Navigator.of(context).pop(true);
                    },
                ),
                TextButton(
                    child: Text(config.cancel),
                    onPressed: () {
                        Navigator.of(context).pop(false);
                    },
                )
            ],
        );
    }) ?? false;
}
