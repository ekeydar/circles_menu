import 'dart:convert';
import 'package:collection/collection.dart';

import 'circle_menu_button.dart';
import 'pick_action_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'circle_menu_models.dart';

const String spKey = 'circleButtons';

class CirclesMenu extends StatefulWidget {
  final CircleMenuConfig config;
  final List<OpAction> actions;

  CirclesMenu({Key? key, CircleMenuConfig? config, required this.actions})
      : this.config = config ?? CircleMenuConfig();

  @override
  State<StatefulWidget> createState() => _CirclesMenuState();
}

class _CirclesMenuState extends State<CirclesMenu> {
  ScrollController _controller = ScrollController();
  double xOffset = 0;
  bool _ready = false;
  late List<OpState> dataList;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    _controller.addListener(() {
      xOffset = _controller.offset;
    });
    await _buildOpStateList();
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _controller,
        child: Container(
          //color: Colors.red.withAlpha(100),
          width: MediaQuery.of(context).size.width,
          child: Stack(
              clipBehavior: Clip.none,
              children: [getButtons(context)] +
                  dataList
                      .map(
                        (d) => CircleMenuButton(
                          config: widget.config,
                          data: d,
                          onPressed: () {
                            d.action.onPress();
                          },
                          onChange: () {
                            dataList.removeWhere((d) => d.isDeleted);
                            _dumpOpStateList();
                            setState(() {});
                          },
                          controller: _controller,
                        ),
                      )
                      .toList()),
        ),
      );
    } else {
      return Center(child: Text(widget.config.loading));
    }
  }

  Widget getButtons(context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: FloatingActionButton(
                heroTag: 'circle_menu_delete',
                onPressed: () {
                  dataList.clear();
                  _dumpOpStateList();
                  setState(() {});
                },
                backgroundColor: Colors.red,
                child: Icon(Icons.delete),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: FloatingActionButton(
                heroTag: 'circle_menu_reset',
                onPressed: () async {
                  await _buildOpStateList(reset: true);
                  _dumpOpStateList();
                  setState(() {});
                },
                backgroundColor: Colors.red,
                child: Icon(Icons.auto_delete),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: FloatingActionButton(
                heroTag: 'circle_menu_add',
                onPressed: () async {
                  OpAction? newAction = await pickAction();
                  if (newAction != null) {
                    int index = dataList.length;
                    dataList.add(
                      OpState(
                        action: newAction,
                        x: 100 + index * 10,
                        y: MediaQuery.of(context).size.height - 200,
                        radius: 100,
                        fillColor: Theme.of(context).primaryColor,
                      ),
                    );
                    _dumpOpStateList();
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
                  heroTag: 'circle_menu_debug',
                  onPressed: () {
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
      ),
    );
  }

  Future<void> _dumpOpStateList() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String value = jsonEncode(dataList.map((m) => m.toMap()).toList());
    await sp.setString(spKey, value);
  }

  Future<void> _buildOpStateList({bool reset=false}) async {
    Map<String, OpAction> actionsByCode = Map<String, OpAction>();
    widget.actions.forEach((a) {
      actionsByCode[a.code] = a;
    });
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (reset || !sp.containsKey(spKey)) {
      dataList = widget.actions.where(
          (a) => a.showByDefault
      ).mapIndexed((index, a) => OpState(
          x: 20.0 + 110*(index ~/ 4),
          y : 100 + 110*(index % 4),
          radius: 100,
          fillColor: Theme.of(context).primaryColor,
          action: a,
      )).toList();
    } else {
      String text = sp.getString(spKey)!;
      List<Map<String, dynamic>> dataMaps = List<Map<String, dynamic>>.from(
        jsonDecode(text),
      );
      dataList = dataMaps
          .where((m) => actionsByCode.containsKey(m['actionCode']))
          .map(
            (m) => OpState(
              x: m['x'],
              y: m['y'],
              radius: m['radius'],
              action: actionsByCode[m['actionCode']]!,
              fillColor: Color(
                  m['fillColorValue'] ?? Theme.of(context).primaryColor.value),
            ),
          )
          .toList();
    }
  }

  Future<OpAction?> pickAction() async {
    Set<String> curCodes = dataList.map((d) => d.action.code).toSet();
    List<OpAction> actions =
        widget.actions.where((a) => !curCodes.contains(a.code)).toList();
    actions.sort((a1, a2) => a1.title.compareTo(a2.title));
    return await showDialog<OpAction>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PickActionDialog(
            actions: actions,
            config: widget.config,
          );
        });
  }
}
