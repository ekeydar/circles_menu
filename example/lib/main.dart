import 'package:circles_menu/circles_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
         GlobalCupertinoLocalizations.delegate,
         GlobalMaterialLocalizations.delegate,
         GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
         Locale('he', 'IL'), // OR Locale('ar', 'AE') OR Other RTL locales
      ],
      locale: Locale('he', 'IL'), // OR Loc
      title: 'Circles Menu Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CirclesMenuExample(),
    );
  }
}

class CirclesMenuExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CirclesMenuExampleState();
}

class CirclesMenuExampleState extends State<CirclesMenuExample> {
  int disabledIndex = 1;
  String? defaultDump;

  late CirclesMenuConfig config;

  @override
  void initState() {
    config = CirclesMenuConfig(onEditDone: this.onEditDone);
    super.initState();
  }

  Future<void> onEditDone() async {
    final snackBar = SnackBar(
      content: Text('In edit done callback'),
      backgroundColor: Colors.red,
      duration: Duration(milliseconds: 500),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('demo widget'),
        ),
        body: CirclesMenu(
          actions: _getActions(context, disabledIndex: disabledIndex),
          config: config,
          defaultDump: defaultDump,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                  child: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      disabledIndex++;
                      if (disabledIndex > 15) {
                        disabledIndex = 1;
                      }
                      // debugPrint('disabledIndex = $disabledIndex');
                    });
                  }),
              SizedBox(
                width: 10,
              ),
              FloatingActionButton(
                  child: Icon(Icons.save_alt),
                  onPressed: () async {
                      defaultDump = await config.getCurrent();
                      setState(() {
                      });
                  }),
            ],
          ),
        ));
  }
}


List<OpAction> _getActions(context, {required int disabledIndex}) {
  ActionsCategory bigCat = ActionsCategory(
    icon: Icon(Icons.sports_tennis),
    code: 'big',
    prompt: true,
    promptText: 'really? really? really?'
  );
  List<OpAction> result = [];
  for (int x = 1; x <= 15; x++) {
    String title = 'this is an action with long name $x';
    OpAction oa = OpAction(
      code: 'action_$x',
      title: title,
      enabled: x != disabledIndex,
      category: x >= 10 ? bigCat : null,
      onPressed: () {
        final snackBar = SnackBar(
          content: Text('clicked on $title'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 500),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    );
    result.add(oa);
  }
  return result;
}
