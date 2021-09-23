import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef WithOpStateCallback(OpState o1);

class OpState {
  double x;
  double y;
  double radius;
  OpAction action;
  bool isDeleted = false;
  Color fillColor;
  bool showActions = false;
  bool isDragged = false;

  bool get canIncrRadius => radius < 100;
  bool get canDecrRadius => radius > 35;
  
  String get text => action.title;

  Color get actualFillColor => action.enabled ? fillColor : fillColor.withAlpha(100);

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'radius': radius,
      'actionCode': action.code,
      'fillColorValue': fillColor.value,
    };
  }

  OpState(
      {required this.x,
      required this.y,
      required this.radius,
      required this.action,
      required this.fillColor});

  Widget get widget {
    return Text(
      this.text,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white),
    );
  }

  Color? get borderColor => null;
}

class OpAction {
  final String title;
  final String code;
  final VoidCallback onPressed;
  final bool enabled;

  OpAction({required this.title, required this.code, required this.onPressed, this.enabled = true});

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
    this.deleteAllConfirmation = 'Are you sure you want to delete the current menu',
    this.resetConfirmation = 'Are you sure you want to delete the current menu and restore the defaults',
    this.approveDialogTitle = 'Action approval',
    this.moveToEditMessage = 'Press the edit icon to edit the menu',
    this.spKey = 'circleButtons',
    this.onEditDone,
  });

  Future<String?> getCurrent() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString(this.spKey);
  }
}

