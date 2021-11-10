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
      locale: Locale('he', 'IL'),
      // OR Loc
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

class MyActionsProvider extends ActionsProvider {
  late List<OpAction> actions;
  late List<ActionsCategory> categories;
  int disabledIndex = 1;
  final ActionPressedCallback onActionPressed;

  @override
  bool isDisabled(String code) => 'action_$disabledIndex' == code;

  @override
  bool isNotApplicable(String code) => false;

  MyActionsProvider({required this.onActionPressed}) {
    actions = _getActions();
    categories = [
      ActionsCategory(icon: Icon(Icons.add), title: 'small', code: 'small'),
      ActionsCategory(
          icon: Icon(Icons.sports_tennis), title: 'big', code: 'big')
    ];
  }

  @override
  List<OpAction> getActions() {
    return actions;
  }

  OpAction getActionByCode(String code) {
    int index = int.parse(code.replaceAll('action_', ''), radix: 10);
    String title = 'פעולה מספר ' + index.toString();
    return OpAction(
      title: title,
      code: code,
    );
  }

  String getActionCategoryCode(String code) {
    int index = int.parse(code.replaceAll('action_', ''), radix: 10);
    return index < 10 ? 'small' : 'big';
  }

  @override
  void actionPressed(String code) {
    this.onActionPressed(code);
  }

  @override
  List<ActionsCategory> getCategories() {
    return categories;
  }
}

class CirclesMenuExampleState extends State<CirclesMenuExample> {
  String? defaultDump;

  late CirclesMenuConfig config;
  late MyActionsProvider myActionsProvider;

  @override
  void initState() {
    config = CirclesMenuConfig(onEditDone: this.onEditDone);
    myActionsProvider =
        MyActionsProvider(onActionPressed: this.onActionPressed);
    super.initState();
  }

  void onActionPressed(String code) {
    final snackBar = SnackBar(
      content: Text('clicked on $code'),
      backgroundColor: Colors.red,
      duration: Duration(milliseconds: 500),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
          actionsProvider: myActionsProvider,
          config: config,
          readonlyPagesMaps: [],
          pickActionCallback: myPickAction,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                  heroTag: 'main',
                  child: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      myActionsProvider.disabledIndex++;
                      if (myActionsProvider.disabledIndex > 15) {
                        myActionsProvider.disabledIndex = 1;
                      }
                      // debugPrint('disabledIndex = $disabledIndex');
                    });
                  }),
              SizedBox(
                width: 10,
              ),
              FloatingActionButton(
                  heroTag: 'main_save',
                  child: Icon(Icons.save_alt),
                  onPressed: () async {
                    defaultDump = await config.getCurrent();
                    setState(() {});
                  }),
            ],
          ),
        ));
  }
}

Future<OpAction?> myPickAction(
  BuildContext context, {
  required ActionsCategory category,
  required ActionsProvider actionsProvider,
  required Set<String> curCodes,
  required CirclesMenuConfig config,
}) async {
  if (category.title == 'big') {
    OpAction? a = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PickBigActionScreen(
          category: category,
        ),
      ),
    );
    return a;
  }
  return await pickActionSimple(
    context,
    category: category,
    actionsProvider: actionsProvider,
    curCodes: curCodes,
    config: config,
  );
}


List<OpAction> _getActions() {
  List<OpAction> result = [];
  Set<int> numbers = {};
  for (int x = 1; x <= 15; x++) {
    numbers.add(x);
  }
  for (var x in numbers.toList()..sort()) {
    String title = 'פעולה מספר ' + x.toString();
    OpAction oa = OpAction(
      code: 'action_$x',
      title: title,
    );
    result.add(oa);
  }
  return result;
}

class PickBigActionScreen extends StatelessWidget {
  final ActionsCategory category;

  PickBigActionScreen({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('pick big action'),
        ),
        body: Column(
          children: [
            for (var i = 10; i < 20; i++)
              ElevatedButton(
                  onPressed: () {
                    String title = 'פעולה מספר ' + i.toString();
                    Navigator.of(context).pop(
                      OpAction(
                        code: 'action_$i',
                        title: title,
                      ),
                    );
                  },
                  child: Text('פעולה מספר ' + i.toString()))
          ],
        ));
  }
}
