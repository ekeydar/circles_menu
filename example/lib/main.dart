import 'package:circles_menu/circles_menu.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // localizationsDelegates: [
      //   GlobalCupertinoLocalizations.delegate,
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      // ],
      // supportedLocales: [
      //   Locale('he', 'IL'), // OR Locale('ar', 'AE') OR Other RTL locales
      // ],
      // locale: Locale('he', 'IL'), // OR Loc
      title: 'Circles Menu Demo',
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
      ),
    );
  }

  List<OpAction> _getActions(context) {
    List<OpAction> result = [];
    for (var x = 1; x <= 15; x++) {
      String title = 'balloon $x';
      OpAction oa = OpAction(
        code: 'action_$x',
        title: title,
        enabled: x % 7 != 0,
        onPressed: () {
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
