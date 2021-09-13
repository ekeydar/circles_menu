import 'package:flutter/material.dart';

class OpData {
  double x;
  double y;
  double radius;
  final OpAction action;
  bool isDeleted = false;
  Color fillColor;

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

  OpData(
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

  OpAction({required this.title, required this.code});

  @override
  String toString() {
    return '$title ($code)';
  }
}
