import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'circle_menu_models.dart';
import 'circles_menu.dart';

class MenuPageScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('demo widget'),
      ),
      body: CirclesMenu(
          actions: _getActions(),
      )
    );
  }

  List<OpAction> _getActions() {
    List<OpAction> result = [];
    for (var x = 1; x <= 10; x++) {
      OpAction oa = OpAction(
        code: 'action_$x',
        title: 'balloon $x',
        onPress: () => debugPrint('clicked $x'),
      );
      result.add(oa);
    }
    return result;
  }
}