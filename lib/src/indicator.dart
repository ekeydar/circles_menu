import 'package:flutter/material.dart';

class PagingIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;

  const PagingIndicator({
    Key? key,
    required this.activeIndex,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < count; i++)
              PagingSingleIndicator(isActive: i == activeIndex)
          ],
        ),
      ),
    );
  }
}

class PagingSingleIndicator extends StatelessWidget {
  final bool isActive;

  const PagingSingleIndicator({Key? key, required this.isActive})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ignore: sized_box_for_whitespace
    return Container(
      height: 10,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        height: isActive ? 10 : 8.0,
        width: isActive ? 12 : 8.0,
        decoration: BoxDecoration(
          boxShadow: [
            isActive
                ? BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.72),
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                    offset: const Offset(
                      0.0,
                      0.0,
                    ),
                  )
                : const BoxShadow(
                    color: Colors.transparent,
                  )
          ],
          shape: BoxShape.circle,
          color: isActive
              ? Theme.of(context).primaryColor
              : const Color.fromRGBO(200, 200, 200,
                  1), //Theme.of(context).primaryColor : Colors.white,
        ),
      ),
    );
  }
}
