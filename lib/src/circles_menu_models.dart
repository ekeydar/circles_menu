import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseMenuItemState {
  double x;
  double y;
  bool isDeleted = false;
  bool showActions = false;
  bool isDragged = false;

  BaseMenuItemState({required this.x, required this.y});

  @mustCallSuper
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      // width and height are not really needed, just as extra (not used on restore)
      'width': width,
      'height': height,
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
}


class LabelMenuItemState extends BaseMenuItemState {
  double fontSize;
  Color color;
  String label;

  LabelMenuItemState(
      {required double x,
      required double y,
      required this.fontSize,
      required this.color,
      required this.label})
      : super(x: x, y: y);

  LabelMenuItemState.fromMap(Map<String, dynamic> m)
      : color = Color(m['colorValue']),
        fontSize = m['fontSize'],
        label = m['label'],
        super(x: m['x'], y: m['y']);

  Map<String, dynamic> toMap() {
    return super.toMap()..addAll({
      'fontSize': fontSize,
      'label': label,
      'colorValue': color.value,
    });
  }
  LabelMenuItemState clone() {
    return LabelMenuItemState(
      x: this.x,
      y: this.y,
      fontSize: this.fontSize,
      label: this.label,
      color: this.color,
    );
  }

  double get width => max(90, 20 + 0.6*fontSize * label.length);

  double get height => 50 + fontSize;

  bool get canIncr => fontSize < 34;
  bool get canDecr => fontSize > 16;
  void incr() => fontSize+=2;
  void decr() => fontSize-=2;
}

class ActionMenuItemState extends BaseMenuItemState {
  double radius;
  OpAction action;
  Color fillColor;

  ActionMenuItemState(
      {required double x,
      required double y,
      required this.radius,
      required this.action,
      required this.fillColor})
      : super(x: x, y: y);

  ActionMenuItemState.fromMap(Map<String, dynamic> m,
      {required Map<String, OpAction> actionsByCode})
      : action = actionsByCode[m['actionCode']]!,
        fillColor = Color(m['fillColorValue']),
        radius = m['radius'],
        super(x: m['x'], y: m['y']);

  ActionMenuItemState clone() {
    return ActionMenuItemState(
      x: this.x,
      y: this.y,
      action: this.action,
      fillColor: this.fillColor,
      radius: this.radius,
    );
  }

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
    return super.toMap()..addAll({
      'radius': radius,
      'actionCode': action.code,
      'fillColorValue': fillColor.value,
    });
  }

  Color? get borderColor => null;
}

class OpAction {
  final String title;
  final String code;
  final VoidCallback onPressed;
  final bool enabled;

  OpAction(
      {required this.title,
      required this.code,
      required this.onPressed,
      this.enabled = true});

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
  final String deleteAllConfirmation;
  final String resetConfirmation;
  final String approveDialogTitle;
  final String moveToEditMessage;
  final String cancelEditsConfirmation;
  final String editLabelTitle;
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
    this.deleteAllConfirmation =
        'Are you sure you want to delete the current menu',
    this.resetConfirmation =
        'Are you sure you want to delete the current menu and restore the defaults',
    this.approveDialogTitle = 'Action approval',
    this.cancelEditsConfirmation =
        'Are you sure you want to cancel the current edits',
    this.moveToEditMessage = 'Press the edit icon to edit the menu',
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
  final List<Map<String, dynamic>> actionMaps;
  final List<Map<String, dynamic>> labelMaps;
  final int version;

  RestoreFromStringData(
      {required this.actionMaps,
      required this.labelMaps,
      required this.version});

  RestoreFromStringData.empty()
      : version = 0,
        actionMaps = [],
        labelMaps = [];
}
