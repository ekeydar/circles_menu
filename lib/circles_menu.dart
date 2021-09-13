import 'package:anim1/circle_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'circle_menu_models.dart';

const String spKey = 'circleButtons';

class CirclesMenu extends StatefulWidget {
  final List<OpData> dataList;
  final VoidCallback onPressed;
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
              children: widget.dataList
                    .map(
                      (d) => CircleMenuButton(
                        data: d,
                        onPressed: widget.onPressed,
                        onChange: widget.onChange,
                        controller: _controller,
                      ),
                    )
                    .toList()),
      ),
    );
  }
}
