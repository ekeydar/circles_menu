import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'circles_menu_models.dart';
import 'circles_menu_utils.dart';
import 'edit_action_dialog.dart';

class CircleMenuPage extends StatelessWidget {
  final List<Widget> items;
  final int index;
  final int numPages;
  final PageData pageData;
  final CirclesMenuConfig config;
  final VoidCallback onChange;
  final EditChangedCallback onEditChange;

  CircleMenuPage({
    required Key key,
    required this.items,
    required this.index,
    required this.numPages,
    required this.pageData,
    required this.config,
    required this.onChange,
    required this.onEditChange,
  }) : super(key: key);

  List<StateAction> _getStateActions(
      BuildContext context, ActionMenuItemState d) {
    return [
      StateAction(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).errorColor,
        ),
        callback: () async {
          d.isDeleted = true;
          this.onChange();
        },
      ),
      StateAction(
        icon: Icon(Icons.color_lens_outlined),
        callback: () async {
          Color? newColor =
              await pickColor(context, initialColor: d.color, config: config);
          if (newColor != null) {
            d.color = newColor;
            onChange();
          }
        },
      ),
      StateAction(
          icon: Icon(Icons.add),
          callback: () async {
            d.incr();
            onChange();
          },
          enabledCallback: () => d.canIncr),
      StateAction(
        enabledCallback: () => d.canDecr,
        icon: Icon(Icons.remove),
        callback: () async {
          d.decr();
          onChange();
        },
      ),
    ];
  }

  Widget? getEditWidget(BuildContext context) {
    late ActionMenuItemState data;
    try {
      data = pageData.actionsStates.firstWhere((d) => d.editInProgress);
    } on StateError {
      return null;
    }
    if (!data.showEditBox) {
      return null;
    }
    List<StateAction> actions = _getStateActions(context, data);
    return Positioned(
      child: EditItemDialog(
        data: data,
        actions: actions,
        onEditChange: this.onEditChange,
      ),
      top: data.y > 200 ? data.y - 120 : data.y + 120,
      left: 10,
    );
  }

  Widget getTitleWidget() {
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
    Widget? editWidget = getEditWidget(context);
    Widget titleWidget = getTitleWidget();
    return Container(
      color: pageData.color.withAlpha(100),
      child: Stack(
        clipBehavior: Clip.none,
        children: this.items +
            [titleWidget] +
            (editWidget != null ? [editWidget] : []),
      ),
    );
  }
}
