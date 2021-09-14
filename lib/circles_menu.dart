import 'package:anim1/circle_menu_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'circle_menu_models.dart';

const String spKey = 'circleButtons';

class CirclesMenu extends StatefulWidget {
  final List<OpState> dataList;
  final WithOpStateCallback onPressed;
  final VoidCallback onChange;

  CirclesMenu({Key? key, required this.dataList, required this.onPressed, required this.onChange});

  @override
  State<StatefulWidget> createState() => _CirclesMenuState();
}


class _CirclesMenuState extends State<CirclesMenu> {
  ScrollController _controller = ScrollController();
  double xOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      xOffset = _controller.offset;
    });
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _controller,
      child: Container(
        color: Colors.red.withAlpha(100),
        width: MediaQuery.of(context).size.width * 2,
        child: Stack(
            clipBehavior: Clip.none,
              children: [getButtonsContainer(context)] + widget.dataList
                    .map(
                      (d) => CircleMenuButton(
                        data: d,
                        onPressed: () {
                          widget.onPressed(d);
                        },
                        onChange: widget.onChange,
                        controller: _controller,
                      ),
                    )
                    .toList()),
      ),
    );
  }

  Widget getButtonsContainer(context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {});
                  },
                  backgroundColor: Colors.red,
                  child: Icon(Icons.delete),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: FloatingActionButton(
                  onPressed: () async {
                      setState(() {});
                  },
                  backgroundColor: Colors.green,
                  child: Icon(Icons.add),
                ),
              ),
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8),
                  child: FloatingActionButton(
                    onPressed: () {
                      // debugPrint('size = ${MediaQuery.of(context).size}');
                    },
                    backgroundColor: Colors.green,
                    child: Icon(Icons.bug_report_outlined),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

