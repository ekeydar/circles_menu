import 'dart:convert';

import 'package:anim1/circle_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CirclesMenu extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CirclesMenuState();
}

class OpData {
  double x;
  double y;
  double radius;
  final bool isAdd;
  final String? text;

  OpData(
      {required this.x,
      required this.y,
      required this.radius,
      required this.text,
      required this.isAdd});

  Widget get widget {
    if (this.isAdd) {
      return Icon(
        Icons.add,
        color: Colors.white,
      );
    }
    return Text(
      this.text!,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white),
    );
  }
}

class _CirclesMenuState extends State<CirclesMenu> {
  bool _ready = false;
  late List<OpData> dataList;

  @override
  void initState() {
    super.initState();
    _buildOpDataList();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ready = $_ready');
    if (_ready) {
      return Stack(
        children: dataList
            .map((d) => CircleMenuButton(
          data: d,
          onPressed: () {
            _handleButton(d);
          },
        ))
            .toList()
      );
    } else {
      return Center(
        child: Text('loading'),
      );
    }
  }

  void _handleButton(OpData data) {
    if (data.isAdd) {
      dataList.add(
        OpData(
          x: data.x + data.radius,
          y: data.y + data.radius,
          radius: data.radius,
          text: 'זמני',
          isAdd: false,
        )
      );
      setState(() {

      });
    }
  }

  Future<void> _buildOpDataList() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? text = sp.getString('circleButtons');
    if (text == null) {
      dataList = [
        OpData(
          x: 100,
          y: 100,
          radius: 100,
          isAdd: true,
          text: null,
        )
      ];
    } else {
      List<Map<String, dynamic>> dataMaps = jsonDecode(text);
      dataList = dataMaps
          .map(
            (m) =>
            OpData(
              x: m['x'],
              y: m['y'],
              radius: m['radius'],
              isAdd: m['isAdd'],
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
