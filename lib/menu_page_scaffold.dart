import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'circles_menu.dart';

class MenuPageScaffold extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MenuPageScaffoldState();
}

class _MenuPageScaffoldState extends State<MenuPageScaffold> {
  bool _ready = false;
  late List<OpData> dataList;

  @override
  void initState() {
    super.initState();
    _buildOpDataList();
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
          onPressed: () {

          },
          onChange: () {
              _dumpOpDataList();
              setState(() {

              });
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
                        setState(() {

                        });
                      },
                      backgroundColor: Colors.red,
                      child: Icon(Icons.delete),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8),
                    child: FloatingActionButton(
                      onPressed: () {
                        int index = dataList.length;
                        dataList.add(
                          OpData(
                              text: 'balloon ${index+1}',
                              x: 100 + index*10,
                              y: 100,
                              radius: 100,
                          )
                        );
                        _dumpOpDataList();
                        setState(() {

                        });
                      },
                      backgroundColor: Colors.green,
                      child: Icon(Icons.add),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8),
                    child: FloatingActionButton(
                      onPressed: () {
                        debugPrint('size = ${MediaQuery.of(context).size}');
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

  Future<void> _dumpOpDataList() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String value = jsonEncode(dataList.map((m) => m.toMap()).toList());
    await sp.setString(spKey, value);
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
          .map(
            (m) => OpData(
          x: m['x'],
          y: m['y'],
          radius: m['radius'],
          text: m['text'],
        ),
      )
          .toList();
    }
    setState(() {
      _ready = true;
    });
  }
}
