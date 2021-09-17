import 'package:circles_menu/circles_menu.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CirclesMenuExample(),
    );
  }
}

class CirclesMenuExample extends StatelessWidget {
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

