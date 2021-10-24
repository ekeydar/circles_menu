import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PageData {
  List<ActionMenuItemState> actionsStates;
  List<LabelMenuItemState> labelsStates;
  int index;
  String? externalId;

  PageData(
      {this.externalId,
      required this.index,
      required this.actionsStates,
      required this.labelsStates});

  PageData.empty({int index = 0})
      : this.index = index,
        actionsStates = [],
        labelsStates = [];

  PageData.fromMap(Map<String, dynamic> m,
      {required Map<String, OpAction> actionsByCode})
      : index = m['index'] ?? 0,
        externalId = m['externalId'] ?? null,
        actionsStates = [],
        labelsStates = [] {
    actionsStates = List<ActionMenuItemState>.from(
      (m['states'] ?? [])
          .where((m) => actionsByCode.containsKey(m['actionCode']))
          .map(
            (m) => ActionMenuItemState.fromMap(
              m,
              actionsByCode: actionsByCode,
            ),
          ),
    );
    labelsStates = List<LabelMenuItemState>.from(
        m['labels'].map((m) => LabelMenuItemState.fromMap(m)));
  }

  bool get readonly => externalId != null;

  bool get isEmpty => actionsStates.isEmpty && labelsStates.isEmpty;

  bool get isNotEmpty => actionsStates.isNotEmpty || labelsStates.isNotEmpty;

  List<BaseMenuItemState> get allLabelsAndActions =>
      List<BaseMenuItemState>.from(actionsStates) +
      List<BaseMenuItemState>.from(labelsStates);

  void removeNotApplicableActions(Map<String, OpAction> actionsByCode) {
    this
        .actionsStates
        .removeWhere((st) => !actionsByCode.containsKey(st.action.code));
  }

  void removeDeleted() {
    actionsStates.removeWhere((d) => d.isDeleted);
    labelsStates.removeWhere((d) => d.isDeleted);
  }

  void updateActions(Map<String, OpAction> actionsByCode) {
    this.actionsStates.forEach((st) {
      String c = st.action.code;
      st.action = actionsByCode[c]!;
    });
  }

  void empty() {
    this.labelsStates.clear();
    this.actionsStates.clear();
  }

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> states =
        actionsStates.map((m) => m.toMap()).toList();
    List<Map<String, dynamic>> labels =
        labelsStates.map((m) => m.toMap()).toList();
    return {
      'states': states,
      'labels': labels,
      'index': this.index,
      'externalId': this.externalId
    };
  }
}

abstract class BaseMenuItemState {
  double x;
  double y;
  bool isDeleted = false;
  bool isDragged = false;
  int pageIndex; // zero based

  BaseMenuItemState(
      {required this.x, required this.y, required this.pageIndex});

  @mustCallSuper
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      // width and height are not really needed, just as extra (not used on restore)
      'width': width,
      'height': height,
      'pageIndex': pageIndex,
    };
  }

  double get width;

  double get height;

  bool get canIncr;

  bool get canDecr;

  void incr();

  void decr();

  Color get color;

  set color(Color c);

  double get maxX => x + width;

  double get maxY => y + height;

  String get title;
}

class LabelMenuItemState extends BaseMenuItemState {
  double fontSize;
  Color color;
  String label;

  String get title => label;

  LabelMenuItemState(
      {required double x,
      required double y,
      required int pageIndex,
      required this.fontSize,
      required this.color,
      required this.label})
      : super(x: x, y: y, pageIndex: pageIndex);

  LabelMenuItemState.fromMap(Map<String, dynamic> m)
      : color = Color(m['colorValue']),
        fontSize = m['fontSize'],
        label = m['label'],
        super(pageIndex: m['pageIndex'] ?? 0, x: m['x'], y: m['y']);

  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll({
        'fontSize': fontSize,
        'label': label,
        'colorValue': color.value,
      });
  }

  double get width => max(90, 20 + 0.6 * fontSize * label.length);

  double get height => 50 + fontSize;

  bool get canIncr => fontSize < 34;

  bool get canDecr => fontSize > 16;

  void incr() => fontSize += 2;

  void decr() => fontSize -= 2;
}

class ActionMenuItemState extends BaseMenuItemState {
  double radius;
  OpAction action;
  Color fillColor;

  String get title => action.title;

  ActionMenuItemState(
      {required double x,
      required double y,
      required int pageIndex,
      required this.radius,
      required this.action,
      required this.fillColor})
      : super(x: x, y: y, pageIndex: pageIndex);

  ActionMenuItemState.fromMap(Map<String, dynamic> m,
      {required Map<String, OpAction> actionsByCode})
      : action = actionsByCode[m['actionCode']]!,
        fillColor = Color(m['fillColorValue']),
        radius = m['radius'],
        super(x: m['x'], y: m['y'], pageIndex: m['pageIndex'] ?? 0);

  Color get color => fillColor;

  set color(Color c) {
    fillColor = c;
  }

  double get width => radius * 2;

  double get height => width;

  bool get canIncr => radius < 100;

  bool get canDecr => radius > 35;

  void incr() {
    radius += 5;
  }

  void decr() {
    radius -= 5;
  }

  String get text => action.title;

  Color get actualFillColor =>
      action.enabled ? fillColor : fillColor.withAlpha(100);

  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll({
        'radius': radius,
        'actionCode': action.code,
        'fillColorValue': fillColor.value,
      });
  }

  Color? get borderColor => null;

  @override
  String toString() {
    return this.text;
  }
}

class ActionsCategory {
  final Widget icon;
  final String code;
  final int order;

  ActionsCategory({required this.icon, required this.code, this.order = 100});

  static ActionsCategory defaultCategory = ActionsCategory(
    icon: Icon(Icons.add),
    code: 'default',
    order: 1,
  );

  @override
  String toString() {
    return this.code;
  }
}

class OpAction {
  final String title;
  final String code;
  final VoidCallback onPressed;
  final bool enabled;
  final ActionsCategory category;

  static IconData defaultIconData = Icons.add;

  OpAction(
      {required this.title,
      required this.code,
      required this.onPressed,
      ActionsCategory? category,
      this.enabled = true})
      : this.category = category ?? ActionsCategory.defaultCategory;

  @override
  String toString() {
    return '$title ($code)';
  }
}

class CirclesMenuConfig {
  // translations/texts
  final String loading;
  final String accept;
  final String cancel;
  final String pickAction;
  final String emptyPageConfirmation;
  final String resetConfirmation;
  final String approveDialogTitle;
  final String moveToEditMessage;
  final String cancelEditsConfirmation;
  final String editLabelTitle;
  final String swapWithNextPageConfirmation;
  final String swapWithPrevPageConfirmation;

  // key to hold the data in shared preferences
  final String spKey;

  // this function is called whenever the edit is Done, if you want to persist
  // after it is saved to the shared preferences
  final VoidCallback? onEditDone;

  CirclesMenuConfig({
    this.loading = 'Loading',
    this.accept = 'Accept',
    this.cancel = 'Cancel',
    this.pickAction = 'Pick action',
    this.emptyPageConfirmation =
        'Are you sure you want to empty the current page',
    this.resetConfirmation =
        'Are you sure you want to delete the current menu and restore the defaults',
    this.approveDialogTitle = 'Action approval',
    this.cancelEditsConfirmation =
        'Are you sure you want to cancel the current edits',
    this.moveToEditMessage = 'Press the edit icon to edit the menu',
    this.swapWithPrevPageConfirmation =
        'Replace this page with the previous page?',
    this.swapWithNextPageConfirmation = 'Replace this page with the next page?',
    this.editLabelTitle = 'Edit label',
    this.spKey = 'circleButtons',
    this.onEditDone,
  });

  Future<String?> getCurrent() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString(this.spKey);
  }
}

class RestoreFromStringData {
  final List<Map<String, dynamic>> pagesMaps;
  final int version;

  RestoreFromStringData({required this.pagesMaps, required this.version});

  RestoreFromStringData.empty()
      : version = 0,
        pagesMaps = [];
}

typedef bool BoolCallback();

class StateAction {
  final Icon icon;
  final AsyncCallback callback;
  final BoolCallback? enabledCallback;
  final bool popAfterPress;

  StateAction(
      {required this.icon,
      required this.callback,
      this.enabledCallback,
      this.popAfterPress = false});
}
