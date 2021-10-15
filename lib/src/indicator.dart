import 'package:flutter/material.dart';

class PagingIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;

  PagingIndicator({
    Key? key,
    required this.activeIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < this.count; i++)
              PagingSingleIndicator(isActive: i == activeIndex)
          ],
        ),
      ),
    );
  }
}

class PagingSingleIndicator extends StatelessWidget {
  final bool isActive;

  PagingSingleIndicator({Key? key, required this.isActive}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(horizontal: 4.0),
        height: isActive ? 10 : 8.0,
        width: isActive ? 12 : 8.0,
        decoration: BoxDecoration(
          boxShadow: [
            isActive
                ? BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.72),
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                    offset: Offset(
                      0.0,
                      0.0,
                    ),
                  )
                : BoxShadow(
                    color: Colors.transparent,
                  )
          ],
          shape: BoxShape.circle,
          color: isActive
              ? Theme.of(context).primaryColor
              : Colors.white, //Theme.of(context).primaryColor : Colors.white,
        ),
      ),
    );
  }
}
