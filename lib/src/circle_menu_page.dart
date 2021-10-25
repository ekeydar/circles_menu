import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'circles_menu_models.dart';

class CircleMenuPage extends StatelessWidget {
  final List<Widget> items;
  final Color color;
  final int index;
  final int numPages;
  final PageData pageData;
  final CirclesMenuConfig config;

  CircleMenuPage({
    required Key key,
    required this.items,
    required this.color,
    required this.index,
    required this.numPages,
    required this.pageData,
    required this.config,
  }) : super(key: key);

  Widget get titleWidget {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          pageData.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kDebugMode ? this.color.withAlpha(100) : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: this.items + [this.titleWidget],
      ),
    );
  }
}
