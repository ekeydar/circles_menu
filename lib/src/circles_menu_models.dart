import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      {required Map<String, OpAction> actionsByCode,
      required ActionsProvider actionsProvider,
      required String defaultTitle}) {
    List<ActionMenuItemState> actionsStates = List<ActionMenuItemState>.from(
      (m['states'] ?? [])
          .where((m) => actionsByCode.containsKey(m['actionCode']))
          .map(
            (m) => ActionMenuItemState.fromMap(
              m,
              actionsProvider: actionsProvider,
              actionsByCode: actionsByCode,
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

  void removeNotApplicableActions(Map<String, OpAction> actionsByCode) {
    this
        .actionsStates
        .removeWhere((st) => !actionsByCode.containsKey(st.action.code));
  }

  void removeDeleted() {
    actionsStates.removeWhere((d) => d.isDeleted);
  }

  void resetEditInProgress() {
    actionsStates.forEach((s) {
      s.editInProgress = false;
    });
  }

  void empty() {
    this.actionsStates.clear();
  }

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> states =
        actionsStates.map((m) => m.toMap()).toList();
    return {
      'states': states,
      'index': this.index,
      'externalId': this.externalId,
      'isOwner': this.isOwner,
      'title': this.title,
      'colorValue': this.color.value,
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
      {required Map<String, OpAction> actionsByCode,
      required this.actionsProvider})
      : actionCode = m['actionCode']!,
        fillColor = Color(m['fillColorValue']),
        radius = m['radius'],
        super(x: m['x'], y: m['y']);

  Color get color => fillColor;

  set color(Color c) {
    fillColor = c;
  }

  double get width => radius * 2;

  double get height => width;

  bool get canIncr => radius < 100;

  bool get canDecr => radius > 35;

  void incr() {
    radius += 5;
  }

  void decr() {
    radius -= 5;
  }

  String get text => action.title;

  Color get actualFillColor => this.actionsProvider.isDisabled(action.code)
      ? fillColor.withAlpha(100)
      : fillColor;

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
    return this.text;
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
    return this.title;
  }
}

class OpAction {
  final String title;
  final String code;
  final String categoryCode;

  OpAction({
    required this.title,
    required this.code,
    required this.categoryCode,
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
    return sp.getString(this.spKey);
  }
}

typedef bool BoolCallback();
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

typedef void ActionPressedCallback(String code);

abstract class ActionsProvider {
  List<OpAction> getActions();

  bool isDisabled(String code) => false;

  OpAction getActionByCode(String code);

  void actionPressed(String code);

  List<ActionsCategory> getCategories();
}
