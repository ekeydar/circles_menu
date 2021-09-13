import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'circle_menu_models.dart';
import 'circles_menu.dart';

class MenuPageScaffold extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MenuPageScaffoldState();
}

class _MenuPageScaffoldState extends State<MenuPageScaffold> {
  bool _ready = false;
  late List<OpData> dataList;
  late Map<String, OpAction> actionsByCode;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint('_ready = $_ready dataList.length = ${dataList.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text('demo widget'),
      ),
      body: _ready
          ? CirclesMenu(
              dataList: dataList,
              onPressed: () {},
              onChange: () {
                dataList.removeWhere((d) => d.isDeleted);
                _dumpOpDataList();
                setState(() {});
              })
          : Center(
              child: Text('loading...'),
            ),
      floatingActionButton: _ready
          ? Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8),
                    child: FloatingActionButton(
                      onPressed: () {
                        dataList.clear();
                        _dumpOpDataList();
                        setState(() {});
                      },
                      backgroundColor: Colors.red,
                      child: Icon(Icons.delete),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8),
                    child: FloatingActionButton(
                      onPressed: () async {
                        OpAction? newAction = await pickAction();
                        //debugPrint('action = $newAction');
                        if (newAction != null) {
                          int index = dataList.length;
                          dataList.add(OpData(
                              action: newAction,
                              x: 100 + index * 10,
                              y: 100,
                              radius: 100,
                              fillColor: Theme.of(context).primaryColor,
                          ));
                          _dumpOpDataList();
                          setState(() {});
                        }
                      },
                      backgroundColor: Colors.green,
                      child: Icon(Icons.add),
                    ),
                  ),
                  if (kDebugMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8),
                    child: FloatingActionButton(
                      onPressed: () {
                        // debugPrint('size = ${MediaQuery.of(context).size}');
                        for (var d in dataList) {
                          debugPrint('${d.text}: ${d.x} ${d.y}');
                        }
                      },
                      backgroundColor: Colors.green,
                      child: Icon(Icons.bug_report_outlined),
                    ),
                  )
                ],
              ),
            )
          : null,
    );
  }

  Future<OpAction?> pickAction() async {
    Set<String> curCodes = dataList.map((d) => d.action.code).toSet();
    List<OpAction> actions = List<OpAction>.from(this.actionsByCode.values)
        .where((a) => !curCodes.contains(a.code))
        .toList();
    actions.sort((a1, a2) => a1.title.compareTo(a2.title));
    return await showDialog<OpAction>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            actions: [
              TextButton(
                child: Text('cancel'),
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
              ),
            ],
            title: Text('pick category'),
            content: SingleChildScrollView(
              child: Column(
                children: actions.map(
                    (a) => ListTile(
                      title: Text(a.title),
                      onTap: () {
                        Navigator.of(context).pop(a);
                      },
                    )
                ).toList()
              ),
            ),
          );
        });
  }

  Future<void> _dumpOpDataList() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String value = jsonEncode(dataList.map((m) => m.toMap()).toList());
    await sp.setString(spKey, value);
  }

  Future<void> _prepare() async {
    await _buildActions();
    await _buildOpDataList();
    setState(() {
      _ready = true;
    });
  }

  Future<void> _buildActions() async {
    actionsByCode = Map<String, OpAction>();
    for (var x = 1; x <= 10; x++) {
      OpAction oa = OpAction(code: 'action_$x', title: 'balloon $x');
      actionsByCode[oa.code] = oa;
    }
  }

  Future<void> _buildOpDataList() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? text = sp.getString(spKey);
    if (text == null) {
      dataList = [];
    } else {
      List<Map<String, dynamic>> dataMaps = List<Map<String, dynamic>>.from(
        jsonDecode(text),
      );
      dataList = dataMaps
          .where((m) => actionsByCode.containsKey(m['actionCode']))
          .map(
            (m) => OpData(
              x: m['x'],
              y: m['y'],
              radius: m['radius'],
              action: actionsByCode[m['actionCode']]!,
              fillColor: Color(m['fillColorValue'] ?? Theme.of(context).primaryColor.value),
            ),
          )
          .toList();
    }
  }
}

