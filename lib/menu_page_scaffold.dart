import 'package:flutter/material.dart';

import 'circles_menu.dart';

class MenuPageScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('demo widget'),
        ),
        body: CirclesMenu(
          actions: _getActions(context),
        ));
  }

  List<OpAction> _getActions(context) {
    List<OpAction> result = [];
    for (var x = 1; x <= 15; x++) {
      String title = 'balloon $x';
      OpAction oa = OpAction(
        code: 'action_$x',
        title: title,
        onPress: () {
          final snackBar = SnackBar(
            content: Text('clicked on $title'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 500),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
        showByDefault: x <= 10,
      );
      result.add(oa);
    }
    return result;
  }
}
