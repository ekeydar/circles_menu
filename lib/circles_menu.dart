import 'dart:convert';

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

const int DUMP_VERSION = 1;

class CirclesMenu extends StatefulWidget {
  final CirclesMenuConfig config;
  final List<OpAction> actions;
  final String? initialDump;
  final String? defaultDump;

  CirclesMenu(
      {Key? key,
      CirclesMenuConfig? config,
      required this.actions,
      this.initialDump,
      this.defaultDump})
      : this.config = config ?? CirclesMenuConfig();

  @override
  State<StatefulWidget> createState() => _CirclesMenuState();
}

class _CirclesMenuState extends State<CirclesMenu> {
  late ScrollController _controller;
  double xOffset = 0;
  bool _ready = false;
  late List<ActionMenuItemState> actionStatesList;
  List<ActionMenuItemState> _beforeDataList = [];
  double initialOffset = 0;
  bool isInEdit = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    await Future.delayed(Duration(milliseconds: 2));
    double w = MediaQuery.of(context).size.width;
    initialOffset = w / 2;
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
      Map<String, OpAction> actionsByCode = {
        for (var a in widget.actions) a.code: a
      };
      actionStatesList.removeWhere((st) => !actionsByCode.containsKey(st.action.code));
      actionStatesList.forEach((st) {
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
                  children: [getButtons(context)] + getCirclesAndActions())),
        ),
      );
    } else {
      return Center(child: Text(widget.config.loading));
    }
  }

  List<Widget> getCirclesAndActions() {
    List<Widget> result = [];
    for (var d in actionStatesList) {
      result.add(CircleMenuButton(
        config: widget.config,
        data: d,
        isInEdit: this.isInEdit,
        onPressed: () {
          if (d.action.enabled) {
            d.action.onPressed();
          }
        },
        onChange: () {
          actionStatesList.removeWhere((d) => d.isDeleted);
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
                heroTag: 'circles_menu_toggle_edit',
                onPressed: () async {
                  if (this.isInEdit) {
                    if (widget.config.onEditDone != null) {
                      widget.config.onEditDone!();
                    }
                  } else {
                    // save the state before the start edit
                    this._beforeDataList = this.actionStatesList.map((d) => d.clone()).toList();
                  }
                  setState(() {
                    this.isInEdit = !this.isInEdit;
                    if (!this.isInEdit) {
                      this.actionStatesList.forEach((s) {
                        s.showActions = false;
                      });
                    }
                  });
                },
                backgroundColor: isInEdit ? Colors.green : Colors.red,
                child: Icon(isInEdit ? Icons.check : Icons.edit),
              ),
            ),
            if (isInEdit)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: FloatingActionButton(
                  heroTag: 'circle_menu_cancel_edit',
                  onPressed: () async {
                    if (await askConfirmation(
                        context, widget.config.cancelEditsConfirmation,
                        config: widget.config)) {
                      setState(() {
                        this.actionStatesList = this._beforeDataList.map((d) => d.clone()).toList();
                      });
                    }
                  },
                  backgroundColor: Colors.red,
                  child: Icon(Icons.cancel),
                ),
              ),
            if (isInEdit)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: FloatingActionButton(
                  heroTag: 'circle_menu_delete',
                  onPressed: () async {
                    if (await askConfirmation(
                        context, widget.config.deleteAllConfirmation,
                        config: widget.config)) {
                      actionStatesList.clear();
                      _dumpOpStateList();
                      setState(() {});
                    }
                  },
                  backgroundColor: Colors.red,
                  child: Icon(Icons.delete),
                ),
              ),
            if (isInEdit && widget.defaultDump != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: FloatingActionButton(
                  heroTag: 'circle_menu_reset',
                  onPressed: () async {
                    if (await askConfirmation(
                        context, widget.config.resetConfirmation,
                        config: widget.config)) {
                      await _buildOpStateList(reset: true);
                      _dumpOpStateList();
                      setState(() {});
                    }
                  },
                  backgroundColor: Colors.red,
                  child: Icon(Icons.auto_delete),
                ),
              ),
            if (isInEdit)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: FloatingActionButton(
                  heroTag: 'circle_menu_add',
                  onPressed: () async {
                    OpAction? newAction = await pickAction();
                    if (newAction != null) {
                      int index = actionStatesList.length;
                      actionStatesList.add(
                        ActionMenuItemState(
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
            if (!isInEdit && kDebugMode)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: FloatingActionButton(
                  heroTag: 'circle_menu_debug',
                  onPressed: () async {
                    await _dumpOpStateList(debug: true);
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

  Future<void> _dumpOpStateList({bool debug = false}) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> states = List<Map<String, dynamic>>.from(
        actionStatesList.map((m) => m.toMap()).toList());
    Map<String, dynamic> data = {
      'states': states,
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
      'version': DUMP_VERSION,
    };
    String value = jsonEncode(data);
    await sp.setString(widget.config.spKey, value);
    if (debug) {
      String debugData = JsonEncoder.withIndent('    ').convert(data);
      print('data = $debugData');
    }
  }

  Future<void> _buildOpStateList({bool reset = false}) async {
    Map<String, OpAction> actionsByCode = Map<String, OpAction>();
    widget.actions.forEach((a) {
      actionsByCode[a.code] = a;
    });
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? dumpText;
    if (reset) {
      dumpText = widget.defaultDump;
    } else if (!sp.containsKey(widget.config.spKey)) {
      dumpText = widget.initialDump ?? widget.defaultDump;
    } else {
      dumpText = sp.getString(widget.config.spKey);
    }
    RestoreFromStringData restoreData = restoreFromStringSafe(dumpText);
    actionStatesList = restoreData.actionMaps
        .where((m) => actionsByCode.containsKey(m['actionCode']))
        .map(
          (m) => ActionMenuItemState(
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

  RestoreFromStringData restoreFromStringSafe(String? dumpText) {
    if (dumpText == null) {
      return RestoreFromStringData.empty();
    }
    try {
      Map<String, dynamic> dump = jsonDecode(dumpText);
      int version = dump['version'];
        return RestoreFromStringData(
          version: version,
          labelMaps: dump['labels'] ?? [],
          actionMaps: dump['states']
        );
    } catch (ex, stacktrace) {
      debugPrint('ex = $ex');
      debugPrint('$stacktrace');
      return RestoreFromStringData.empty();
    }
  }

  Future<OpAction?> pickAction() async {
    Set<String> curCodes = actionStatesList.map((d) => d.action.code).toSet();
    List<OpAction> actions = List<OpAction>.from(widget.actions);
    actions.sort((a1, a2) => a1.title.compareTo(a2.title));
    return await showDialog<OpAction>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PickActionDialog(
            actions: actions,
            config: widget.config,
            curCodes: curCodes,
          );
        });
  }
}
