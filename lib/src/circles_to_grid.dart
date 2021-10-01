import 'dart:math';

import 'package:circles_menu/circles_menu.dart';
import 'package:collection/collection.dart';

const double PAD_Y = 10;
const double PAD_X = 10;

void modifyCirclesToGrid(List<ActionMenuItemState> states) {
  double minY = 10000000;
  double minX = 10000000;
  double maxY = 0;
  double maxHeight = 0;
  double minHeight = 10000000;
  double maxWidth = 0;
  for (var s in states) {
    minX = min(minX, s.x);
    maxWidth = max(maxWidth, s.width);
    minY = min(minY, s.y);
    maxY = max(maxY, s.y + s.height);
    maxHeight = max(maxHeight, s.height);
    minHeight = min(minHeight, s.height);
  }
  states.sort((s1, s2) => _compareInGrid(s1, s2, minHeight: minHeight));
  int maxInCol = (((maxY + PAD_Y) - minY) / (PAD_Y + maxHeight)).floor();
  states.forEachIndexed((index, s) {
      int indexInCol = index % maxInCol;
      int indexInRow = index ~/ maxInCol;
      s.x = minX + indexInRow * (maxWidth + PAD_X);
      s.y = minY + indexInCol * (maxHeight + PAD_Y);
  });
}

int _compareInGrid(ActionMenuItemState s1, ActionMenuItemState s2, {required double minHeight}) {
  // we want to compare first by x, but make "equal" if the distance is less < 20
  if ((s1.x - s2.x).abs() > minHeight - 20) {
    return s1.x.compareTo(s2.x);
  }
  return s1.y.compareTo(s2.y);
}