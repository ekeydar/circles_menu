import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: prefer_generic_function_type_aliases
typedef Future<OpAction?> PickActionCallback(
  BuildContext context, {
  required ActionsCategory category,
  required ActionsProvider actionsProvider,
  required Set<String> curCodes,
  required CirclesMenuConfig config,
});

class PageData {
  static Color defaultColor = Colors.white;
  List<ActionMenuItemState> actionsStates;
  int index;
  String? externalId;
  bool isOwner;
  String title;
  Color color;

  PageData({
    required this.externalId,
    required this.isOwner,
    required this.index,
    required this.actionsStates,
    required this.title,
    required this.color,
  });

  factory PageData.empty({int index = 0, required String title}) {
    return PageData(
      index: index,
      isOwner: false,
      externalId: null,
      title: title,
      color: PageData.defaultColor,
      actionsStates: [],
    );
  }

  factory PageData.fromMap(Map<String, dynamic> m,
      {required ActionsProvider actionsProvider,
      required String defaultTitle}) {
    List<ActionMenuItemState> actionsStates = List<ActionMenuItemState>.from(
      (m['states'] ?? [])
          .where((m) => !actionsProvider.isNotApplicable(m['actionCode']))
          .map(
            (m) => ActionMenuItemState.fromMap(
              m,
              actionsProvider: actionsProvider,
            ),
          ),
    );
    String? externalId = m['externalId'];
    bool isOwner = m['isOwner'] ?? false;
    return PageData(
        index: m['index'] ?? 0,
        externalId: externalId,
        isOwner: isOwner,
        title: m['title'] ?? defaultTitle,
        actionsStates: actionsStates,
        color: m['colorValue'] != null
            ? Color(m['colorValue'])
            : PageData.defaultColor);
  }

  bool get notEditable => externalId != null && !isOwner;

  bool get readonly => externalId != null;

  bool get canBeSqueezed => false; //actionsStates.isEmpty && !isOwner;

  void removeNotApplicableActions() {
    actionsStates.removeWhere(
      (st) => st.actionsProvider.isNotApplicable(st.actionCode),
    );
  }

  void removeDeleted() {
    actionsStates.removeWhere((d) => d.isDeleted);
  }

  void resetEditInProgress() {
    for (var s in actionsStates) {
      s.editInProgress = false;
    }
  }

  void empty() {
    actionsStates.clear();
  }

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> states =
        actionsStates.map((m) => m.toMap()).toList();
    return {
      'states': states,
      'index': index,
      'externalId': externalId,
      'isOwner': isOwner,
      'title': title,
      'colorValue': color.value,
    };
  }

  @override
  String toString() {
    return '$index: $title';
  }
}

abstract class BaseMenuItemState {
  double x;
  double y;
  bool isDeleted = false;
  bool isDragged = false;

  BaseMenuItemState({required this.x, required this.y});

  @mustCallSuper
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      // width and height are not really needed, just as extra (not used on restore)
      'width': width,
      'height': height,
    };
  }

  double get width;

  double get height;

  bool get canIncr;

  bool get canDecr;

  void incr();

  void decr();

  Color get color;

  set color(Color c);

  double get maxX => x + width;

  double get maxY => y + height;

  String get title;
}

class ActionMenuItemState extends BaseMenuItemState {
  double radius;
  final String actionCode;
  Color fillColor;
  bool editInProgress = false;
  bool showEditBox = false;
  final ActionsProvider actionsProvider;

  OpAction get action => actionsProvider.getActionByCode(actionCode);

  @override
  String get title => action.title;

  ActionMenuItemState(
      {required double x,
      required double y,
      required this.actionsProvider,
      required this.radius,
      required this.actionCode,
      required this.fillColor})
      : super(x: x, y: y);

  ActionMenuItemState.fromMap(Map<String, dynamic> m,
      {required this.actionsProvider})
      : actionCode = m['actionCode']!,
        fillColor = Color(m['fillColorValue']),
        radius = m['radius'],
        super(x: m['x'], y: m['y']);

  @override
  Color get color => fillColor;

  @override
  set color(Color c) {
    fillColor = c;
  }

  @override
  double get width => radius * 2;

  @override
  double get height => width;

  @override
  bool get canIncr => radius < 100;

  @override
  bool get canDecr => radius > 35;

  @override
  void incr() {
    radius += 5;
  }

  @override
  void decr() {
    radius -= 5;
  }

  String get text => action.title;

  Color get actualFillColor => actionsProvider.isDisabled(action.code)
      ? fillColor.withAlpha(100)
      : fillColor;

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll({
        'radius': radius,
        'actionCode': action.code,
        'fillColorValue': fillColor.value,
      });
  }

  @override
  String toString() {
    return text;
  }
}

class ActionsCategory {
  final Widget icon;
  final String title;
  final String code;
  final int order;

  ActionsCategory(
      {required this.icon,
      required this.title,
      required this.code,
      this.order = 100});

  @override
  String toString() {
    return title;
  }
}

class OpAction {
  final String title;
  final String code;

  OpAction({
    required this.title,
    required this.code,
  });

  @override
  String toString() {
    return '$title ($code)';
  }
}

class CirclesMenuConfig {
  // translations/texts
  final String loading;
  final String accept;
  final String cancel;
  final String pickAction;
  final String deletePageConfirmation;
  final String resetConfirmation;
  final String approveDialogTitle;
  final String moveToEditMessage;
  final String cancelEditsConfirmation;
  final String editPageTitle;
  final String swapWithNextPageConfirmation;
  final String swapWithPrevPageConfirmation;
  final String editPages;
  final String addPage;
  final String devInfo;
  final String arrangeInGrid;
  final String defaultPageTitle;

  // builder for the pick action
  PickActionCallback? pickActionCallback;

  // key to hold the data in shared preferences
  final String spKey;

  // this function is called whenever the edit is Done, if you want to persist
  // after it is saved to the shared preferences
  final VoidCallback? onEditDone;

  CirclesMenuConfig({
    this.loading = 'Loading',
    this.accept = 'Accept',
    this.cancel = 'Cancel',
    this.pickAction = 'Pick action',
    this.deletePageConfirmation = 'Are you sure you want to delete the page',
    this.resetConfirmation =
        'Are you sure you want to delete the current menu and restore the defaults',
    this.approveDialogTitle = 'Action approval',
    this.cancelEditsConfirmation =
        'Are you sure you want to cancel the current edits',
    this.moveToEditMessage = 'Press the edit icon to edit the menu',
    this.editPages = 'Edit pages',
    this.swapWithPrevPageConfirmation =
        'Replace this page with the previous page?',
    this.swapWithNextPageConfirmation = 'Replace this page with the next page?',
    this.editPageTitle = 'Edit page title',
    this.addPage = 'add page',
    this.defaultPageTitle = 'shortcuts screen',
    this.arrangeInGrid = 'arrange in grid',
    this.devInfo = 'dev info',
    this.spKey = 'circleButtons',
    this.onEditDone,
  });

  Future<String?> getCurrent() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString(spKey);
  }
}

// ignore: prefer_generic_function_type_aliases
typedef bool BoolCallback();
// ignore: prefer_generic_function_type_aliases
typedef void EditChangedCallback(ActionMenuItemState p,
    {required bool isStart});

class StateAction {
  final Icon icon;
  final AsyncCallback callback;
  final BoolCallback? enabledCallback;

  StateAction({
    required this.icon,
    required this.callback,
    this.enabledCallback,
  });
}

// ignore: prefer_generic_function_type_aliases
typedef void ActionPressedCallback(String code);

abstract class ActionsProvider {
  List<OpAction> getActions();

  bool isDisabled(String code);

  bool isNotApplicable(String code);

  OpAction getActionByCode(String code);

  void actionPressed(String code);

  List<ActionsCategory> getCategories();

  String getActionCategoryCode(String code);
}
