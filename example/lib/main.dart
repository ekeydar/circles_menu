import 'package:circles_menu/circles_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he', 'IL'), // OR Locale('ar', 'AE') OR Other RTL locales
      ],
      locale: const Locale('he', 'IL'),
      // OR Loc
      title: 'Circles Menu Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CirclesMenuExample(),
    );
  }
}

class CirclesMenuExample extends StatefulWidget {
  const CirclesMenuExample({Key? key}) : super(key: key);

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
      ActionsCategory(
          icon: const Icon(Icons.add), title: 'small', code: 'small'),
      ActionsCategory(
          icon: const Icon(Icons.sports_tennis), title: 'big', code: 'big')
    ];
  }

  @override
  List<OpAction> getActions() {
    return actions;
  }

  @override
  OpAction getActionByCode(String code) {
    int index = int.parse(code.replaceAll('action_', ''), radix: 10);
    String title = 'פעולה מספר ' + index.toString();
    return OpAction(
      title: title,
      code: code,
    );
  }

  @override
  String getActionCategoryCode(String code) {
    int index = int.parse(code.replaceAll('action_', ''), radix: 10);
    return index < 10 ? 'small' : 'big';
  }

  @override
  void actionPressed(String code) {
    onActionPressed(code);
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
    config = CirclesMenuConfig(onEditDone: onEditDone);
    myActionsProvider = MyActionsProvider(onActionPressed: onActionPressed);
    super.initState();
  }

  void onActionPressed(String code) {
    final snackBar = SnackBar(
      content: Text('clicked on $code'),
      backgroundColor: Colors.red,
      duration: const Duration(milliseconds: 500),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> onEditDone() async {
    const snackBar = SnackBar(
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
          title: const Text('demo widget'),
        ),
        body: CirclesMenu(
          actionsProvider: myActionsProvider,
          config: config,
          readonlyPagesMaps: const [],
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
                  child: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      myActionsProvider.disabledIndex++;
                      if (myActionsProvider.disabledIndex > 15) {
                        myActionsProvider.disabledIndex = 1;
                      }
                      // debugPrint('disabledIndex = $disabledIndex');
                    });
                  }),
              const SizedBox(
                width: 10,
              ),
              FloatingActionButton(
                  heroTag: 'main_save',
                  child: const Icon(Icons.save_alt),
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

  const PickBigActionScreen({Key? key, required this.category})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('pick big action'),
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
