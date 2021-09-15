import 'package:flutter/material.dart';

typedef WithOpStateCallback(OpState o1);

class OpState {
  double x;
  double y;
  double radius;
  final OpAction action;
  bool isDeleted = false;
  Color fillColor;
  bool showActions = false;

  bool get canIncrRadius => radius < 200;
  bool get canDecrRadius => radius > 70;
  
  String get text => action.title;

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
  final VoidCallback onPress;
  final bool showByDefault;

  OpAction({required this.title, required this.code, required this.onPress, required this.showByDefault});

  @override
  String toString() {
    return '$title ($code)';
  }
}

class CircleMenuConfig {
  final String loading;
  final String accept;
  final String cancel;
  final String pickAction;

  CircleMenuConfig({
    this.loading = 'loading',
    this.accept = 'accept',
    this.cancel = 'cancel',
    this.pickAction = 'pick action'
  });
}

