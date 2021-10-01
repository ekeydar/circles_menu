import 'dart:convert';
import 'dart:math';

import 'package:circles_menu/src/circles_to_grid.dart';

import 'src/circles_menu_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/circle_box.dart';
import 'src/circles_menu_item_widget.dart';
import 'src/circles_menu_confirm.dart';
import 'src/circles_menu_models.dart';
import 'src/circles_menu_pick_action_dialog.dart';
import 'src/label_menu_button.dart';

export 'src/circles_menu_models.dart';

const int DUMP_VERSION = 2;

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
  bool _ready = false;
  late List<ActionMenuItemState> actionStatesList;
  late List<LabelMenuItemState> labelStatesList;
  List<ActionMenuItemState> _beforeActionStatesList = [];
  List<LabelMenuItemState> _beforeLabelStatesList = [];
  double initialOffset = 0;
  bool isInEdit = false;
  late double menuWidth;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    await Future.delayed(Duration(milliseconds: 2));
    initialOffset = 0;
    _controller = ScrollController(initialScrollOffset: initialOffset);
    await _buildStateLists();
    setState(() {
      _ready = true;
    });
  }

  double get pageWidth => MediaQuery.of(context).size.width;

  double getMinWidth() {
    double maxX = (List<BaseMenuItemState>.from(this.labelStatesList) +
            List<BaseMenuItemState>.from(this.actionStatesList))
        .fold(1, (soFar, s2) => max(soFar, s2.x + s2.width));
    return max(maxX + 50, pageWidth);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      // debugPrint('menuWidth = $menuWidth');
      Map<String, OpAction> actionsByCode = {
        for (var a in widget.actions) a.code: a
      };
      actionStatesList
          .removeWhere((st) => !actionsByCode.containsKey(st.action.code));
      actionStatesList.forEach((st) {
        String c = st.action.code;
        st.action = actionsByCode[c]!;
      });

      return Scrollbar(
        controller: _controller,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: Directionality.of(context) == TextDirection.rtl,
          controller: _controller,
          child: Container(
              color: kDebugMode ? Colors.red.withAlpha(100) : null,
              width: menuWidth,
              child: Stack(
                  clipBehavior: Clip.none,
                  children: [getButtons(context)] + getItems())),
        ),
      );
    } else {
      return Center(
        child: Text(
          widget.config.loading,
        ),
      );
    }
  }

  void onChange() {
    actionStatesList.removeWhere((d) => d.isDeleted);
    labelStatesList.removeWhere((d) => d.isDeleted);
    _dumpStates();
    setState(() {});
  }

  List<Widget> getItems() {
    List<Widget> result = [];
    for (var d in actionStatesList) {
      result.add(MenuItemWidget(
        config: widget.config,
        data: d,
        isInEdit: this.isInEdit,
        onPressed: () {
          if (d.action.enabled) {
            d.action.onPressed();
          }
        },
        child: CircleBox(
          radius: d.radius,
          child: Text(
            d.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText1!.apply(
                  color: Colors.white,
                ),
          ),
          fillColor: d.actualFillColor,
          borderColor: d.borderColor,
        ),
        onChange: this.onChange,
        controller: _controller,
      ));
    }
    for (var d in labelStatesList) {
      result.add(MenuItemWidget(
        config: widget.config,
        isInEdit: this.isInEdit,
        controller: _controller,
        data: d,
        onChange: this.onChange,
        onPressed: null,
        child: LabelMenuButton(
          config: widget.config,
          data: d,
          isInEdit: this.isInEdit,
          onChange: this.onChange,
          controller: _controller,
        ),
      ));
    }
    return result;
  }

  Widget getButtons(context) {
    bool isRtl = Directionality.of(context) == TextDirection.rtl;
    MainAxisAlignment mainAlignment =
        isRtl ? MainAxisAlignment.end : MainAxisAlignment.start;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: (isInEdit)
              ? Column(
                  mainAxisAlignment: mainAlignment,
                  children: [
                    Row(
                      mainAxisAlignment: mainAlignment,
                      children: reverseIfTrue(isRtl, [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8),
                          child: FloatingActionButton(
                            heroTag: 'circles_menu_approve_edit',
                            onPressed: () async {
                              if (widget.config.onEditDone != null) {
                                widget.config.onEditDone!();
                              }
                              setState(() {
                                this.isInEdit = false;
                                this.actionStatesList.forEach((s) {
                                  s.showActions = false;
                                });
                              });
                            },
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8),
                          child: FloatingActionButton(
                            heroTag: 'circle_menu_cancel_edit',
                            onPressed: () async {
                              if (await askConfirmation(context,
                                  widget.config.cancelEditsConfirmation,
                                  config: widget.config)) {
                                setState(() {
                                  this.actionStatesList = this
                                      ._beforeActionStatesList
                                      .map((d) => d.clone())
                                      .toList();
                                  this.labelStatesList = this
                                      ._beforeLabelStatesList
                                      .map((d) => d.clone())
                                      .toList();
                                });
                              }
                            },
                            backgroundColor: Colors.red,
                            child: Icon(Icons.cancel),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8),
                          child: FloatingActionButton(
                            heroTag: 'circle_menu_add_page',
                            onPressed: () async {
                              menuWidth += pageWidth;
                              setState(() {});
                            },
                            backgroundColor: Colors.green,
                            child: Icon(Icons.zoom_out_map_outlined),
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: mainAlignment,
                      children: reverseIfTrue(
                        isRtl,
                        [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8),
                            child: FloatingActionButton(
                              heroTag: 'circle_menu_delete',
                              onPressed: () async {
                                if (await askConfirmation(context,
                                    widget.config.deleteAllConfirmation,
                                    config: widget.config)) {
                                  actionStatesList.clear();
                                  labelStatesList.clear();
                                  onChange();
                                }
                              },
                              backgroundColor: Colors.red,
                              child: Icon(Icons.delete),
                            ),
                          ),
                          if (widget.defaultDump != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8),
                              child: FloatingActionButton(
                                heroTag: 'circle_menu_reset',
                                onPressed: () async {
                                  if (await askConfirmation(
                                      context, widget.config.resetConfirmation,
                                      config: widget.config)) {
                                    await _buildStateLists(reset: true);
                                    onChange();
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
                                  int index = actionStatesList.length;
                                  actionStatesList.add(
                                    ActionMenuItemState(
                                      action: newAction,
                                      x: initialOffset + 100 + index * 10,
                                      y: MediaQuery.of(context).size.height -
                                          350,
                                      radius: 50,
                                      fillColor: Theme.of(context).primaryColor,
                                    ),
                                  );
                                  onChange();
                                }
                              },
                              backgroundColor: Colors.green,
                              child: Icon(Icons.add),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8),
                            child: FloatingActionButton(
                              heroTag: 'circle_menu_add_label',
                              onPressed: () async {
                                String? newText = await editText(
                                  context,
                                  config: widget.config,
                                );
                                if (newText != null) {
                                  int index = actionStatesList.length;
                                  labelStatesList.add(
                                    LabelMenuItemState(
                                      label: newText,
                                      fontSize: 20,
                                      x: initialOffset + 100 + index * 10,
                                      y: MediaQuery.of(context).size.height -
                                          350,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  );
                                  onChange();
                                }
                              },
                              backgroundColor: Colors.green,
                              child: Icon(Icons.font_download_outlined),
                            ),
                          ),
                          if (this.actionStatesList.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8),
                            child: FloatingActionButton(
                              heroTag: 'circle_menu_auto_order',
                              onPressed: () async {
                                  modifyCirclesToGrid(this.actionStatesList);
                                  onChange();
                              },
                              backgroundColor: Colors.green,
                              child: Icon(Icons.grid_on),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: mainAlignment,
                  children: reverseIfTrue(isRtl, [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8),
                      child: FloatingActionButton(
                        heroTag: 'circles_menu_start_edit',
                        onPressed: () async {
                          // save the state before the start edit
                          this._beforeActionStatesList = this
                              .actionStatesList
                              .map((d) => d.clone())
                              .toList();
                          this._beforeLabelStatesList = this
                              .labelStatesList
                              .map((d) => d.clone())
                              .toList();
                          setState(() {
                            this.isInEdit = true;
                          });
                        },
                        backgroundColor: Colors.red,
                        child: Icon(Icons.edit),
                      ),
                    ),
                    if (kDebugMode)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8),
                        child: FloatingActionButton(
                          heroTag: 'circle_menu_debug',
                          onPressed: () async {
                            await _debugStates();
                          },
                          backgroundColor: Colors.green,
                          child: Icon(Icons.bug_report_outlined),
                        ),
                      )
                  ]),
                )
          //     if (!isInEdit && kDebugMode)
          //       Padding(
          //         padding: const EdgeInsets.only(left: 8.0, right: 8),
          //         child: FloatingActionButton(
          //           heroTag: 'circle_menu_debug',
          //           onPressed: () async {
          //             await _debugStates();
          //           },
          //           backgroundColor: Colors.green,
          //           child: Icon(Icons.bug_report_outlined),
          //         ),
          //       )
          //   ],
          // ),
          ),
    );
  }

  Future<void> _debugStates() async {
    List<Map<String, dynamic>> states =
        actionStatesList.map((m) => m.toMap()).toList();
    List<Map<String, dynamic>> labels =
        labelStatesList.map((m) => m.toMap()).toList();
    Map<String, dynamic> data = {
      'states': states,
      'labels': labels,
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
      'version': DUMP_VERSION,
    };
    String debugData = JsonEncoder.withIndent('    ').convert(data);
    debugPrint('data = $debugData');
  }

  Future<void> _dumpStates() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> states =
        actionStatesList.map((m) => m.toMap()).toList();
    List<Map<String, dynamic>> labels =
        labelStatesList.map((m) => m.toMap()).toList();

    Map<String, dynamic> data = {
      'states': states,
      'labels': labels,
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
      'version': DUMP_VERSION,
    };
    String value = jsonEncode(data);
    await sp.setString(widget.config.spKey, value);
  }

  Future<void> _buildStateLists({bool reset = false}) async {
    Map<String, OpAction> actionsByCode = {
      for (var a in widget.actions) a.code: a
    };
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
          (m) => ActionMenuItemState.fromMap(
            m,
            actionsByCode: actionsByCode,
          ),
        )
        .toList();
    labelStatesList = restoreData.labelMaps
        .map((m) => LabelMenuItemState.fromMap(m))
        .toList();
    menuWidth = getMinWidth();
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
          labelMaps: List<Map<String, dynamic>>.from(dump['labels'] ?? []),
          actionMaps: List<Map<String, dynamic>>.from(dump['states']));
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
