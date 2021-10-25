import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'circles_menu_models.dart';

class CircleMenuPage extends StatelessWidget {
  final List<Widget> items;
  final int index;
  final int numPages;
  final PageData pageData;
  final CirclesMenuConfig config;

  CircleMenuPage({
    required Key key,
    required this.items,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (pageData.readonly)
              Icon(
                Icons.lock,
                size: 20,
              ),
            SizedBox(
              width: 10,
            ),
            Text(
              pageData.title,
              style: TextStyle(
                //fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pageData.color.withAlpha(100),
      child: Stack(
        clipBehavior: Clip.none,
        children: this.items + [this.titleWidget],
      ),
    );
  }
}
