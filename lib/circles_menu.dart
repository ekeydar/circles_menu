import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/circles_menu_button.dart';
import 'src/circles_menu_confirm.dart';
import 'src/circles_menu_models.dart';
import 'src/circles_menu_pick_action_dialog.dart';

export 'src/circles_menu_models.dart';


class CirclesMenu extends StatefulWidget {
  final CircleMenuConfig config;
  final List<OpAction> actions;

  CirclesMenu({Key? key, CircleMenuConfig? config, required this.actions})
      : this.config = config ?? CircleMenuConfig();

  @override
  State<StatefulWidget> createState() => _CirclesMenuState();
}

class _CirclesMenuState extends State<CirclesMenu> {
  late ScrollController _controller;
  double xOffset = 0;
  bool _ready = false;
  late List<OpState> dataList;
  double initialOffset = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    await Future.delayed(Duration(milliseconds: 2));
    double w = MediaQuery.of(context).size.width;
    initialOffset = w/2;
    _controller = ScrollController(initialScrollOffset: initialOffset);
    xOffset = initialOffset;
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
      Map<String, OpAction> actionsByCode = {for (var a in widget.actions) a.code: a};
      dataList.removeWhere((st) => !actionsByCode.containsKey(st.action.code));
      dataList.forEach((st) {
          String c = st.action.code;
          st.action = actionsByCode[c]!;
      });
      return Scrollbar(
        controller: _controller,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _controller,
          child: Container(
            color: kDebugMode ? Colors.red.withAlpha(100) : null,
            width: MediaQuery.of(context).size.width * 2,
            child: Stack(
                clipBehavior: Clip.none,
                children: [getButtons(context)] + getCirclesAndActions()
            )
          ),
        ),
      );
    } else {
      return Center(child: Text(widget.config.loading));
    }
  }

  List<Widget> getCirclesAndActions() {
    List<Widget> result = [];
    for (var d in dataList) {
      result.add(CircleMenuButton(
        config: widget.config,
        data: d,
        onPressed: () {
          if (d.action.enabled) {
            d.action.onPressed();
          }
        },
        onChange: () {
          dataList.removeWhere((d) => d.isDeleted);
          _dumpOpStateList();
          setState(() {});
        },
        controller: _controller,
      ));
    }
    return result;
  }

  Widget getButtons(context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: FloatingActionButton(
                heroTag: 'circle_menu_delete',
                onPressed: () async {
                  if (await askConfirmation(context, widget.config.deleteAllConfirmation, config: widget.config)) {
                    dataList.clear();
                    _dumpOpStateList();
                    setState(() {});
                  }
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
                  if (await askConfirmation(context, widget.config.resetConfirmation, config: widget.config)) {
                    await _buildOpStateList(reset: true);
                    _dumpOpStateList();
                    setState(() {});
                  }
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
                        x: initialOffset + 100 + index * 10,
                        y: MediaQuery.of(context).size.height - 350,
                        radius: 50,
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
    await sp.setString(widget.config.spKey, value);
  }

  Future<void> _buildOpStateList({bool reset=false}) async {
    Map<String, OpAction> actionsByCode = Map<String, OpAction>();
    widget.actions.forEach((a) {
      actionsByCode[a.code] = a;
    });
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (reset || !sp.containsKey(widget.config.spKey)) {
      dataList = widget.actions.where(
          (a) => a.showByDefault
      ).mapIndexed((index, a) => OpState(
          x: initialOffset + 10.0 + 110*(index ~/ 4),
          y : 10 + 110*(index % 4),
          radius: 50,
          fillColor: Theme.of(context).primaryColor,
          action: a,
      )).toList();
    } else {
      String text = sp.getString(widget.config.spKey)!;
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
