import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/circle_box.dart';
import 'src/circle_menu_page.dart';
import 'src/circles_menu_item_widget.dart';
import 'src/circles_menu_models.dart';
import 'src/circles_menu_pick_action_dialog.dart';
import 'src/circles_to_grid.dart';
import 'src/restore_helpers.dart';
import 'src/screens/pages_screen.dart';

export 'src/circles_menu_models.dart';
export 'src/circles_menu_pick_action_dialog.dart' show pickActionSimple;

// ignore: constant_identifier_names
const int DUMP_VERSION = 4;

class SettingsItem {
  final String title;
  final Widget icon;
  final AsyncCallback onSelected;

  SettingsItem({
    required this.title,
    required this.icon,
    required this.onSelected,
  });
}

class CirclesMenu extends StatefulWidget {
  final CirclesMenuConfig config;
  final ActionsProvider actionsProvider;
  final Map<String, dynamic>? extSavedMap;
  final List<Map<String, dynamic>> readonlyPagesMaps;
  final PickActionCallback? pickActionCallback;

  CirclesMenu({Key? key,
    CirclesMenuConfig? config,
    required this.actionsProvider,
    this.extSavedMap,
    required this.readonlyPagesMaps,
    this.pickActionCallback
  })
  // ignore: unnecessary_this
      : this.config = config ?? CirclesMenuConfig(),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _CirclesMenuState();
}

class _CirclesMenuState extends State<CirclesMenu> {
  bool _ready = false;
  late List<PageData> pageDataList;

  // late List<ActionMenuItemState> actionStatesList;
  //late List<LabelMenuItemState> labelStatesList;
  double initialOffset = 0;
  final PageController _pageController = PageController();
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  int get curNumPages => pageDataList.length;

  Future<void> _prepare() async {
    await Future.delayed(const Duration(milliseconds: 2));
    initialOffset = 0;
    await _buildPages();
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      for (var p in pageDataList) {
        p.removeNotApplicableActions();
      }
      return Stack(
        children: [
          PageView(
            onPageChanged: (int newPageIndex) {
              setState(() {
                currentPageIndex = newPageIndex;
              });
            },
            controller: _pageController,
            children: [
              for (var pi = 0; pi < curNumPages; pi++)
                CircleMenuPage(
                  key: Key('$pi/$curNumPages'),
                  pageData: pageDataList[pi],
                  index: pi,
                  numPages: curNumPages,
                  items: getItems(pageIndex: pi),
                  config: widget.config,
                  onChange: onChange,
                  onEditChange: onEditChange,
                ),
            ],
          ),
          getBottomActions(),
        ],
      );
    } else {
      return Center(
        child: Text(
          widget.config.loading,
        ),
      );
    }
  }

  void onEditChange(ActionMenuItemState data, {required bool isStart}) {
    for (var p in pageDataList) {
      p.resetEditInProgress();
    }
    if (isStart) {
      data.editInProgress = true;
      data.showEditBox = true;
    }
    onChange();
  }

  void onChange() {
    for (var p in pageDataList) {
      p.removeDeleted();
    }
    if (currentPageIndex >= pageDataList.length) {
      currentPageIndex = pageDataList.length - 1;
    }
    _dumpStates();
    setState(() {});
  }

  List<Widget> getItems({required int pageIndex}) {
    List<Widget> result = [];
    PageData curPageData = pageDataList[pageIndex];
    for (var d in curPageData.actionsStates) {
      result.add(
        MenuItemWidget(
          config: widget.config,
          data: d,
          isReadonly: curPageData.notEditable,
          onEditChange: onEditChange,
          child: CircleBox(
            radius: d.radius,
            child: Text(
              d.text,
              textAlign: TextAlign.center,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyText1!
                  .apply(
                color: Colors.white,
              ),
            ),
            fillColor: d.actualFillColor,
          ),
          onChange: onChange,
        ),
      );
    }
    return result;
  }

  List<ActionsCategory> get actionsCategories {
    return widget.actionsProvider.getCategories();
  }

  void squeezeAndSortPages() {
    pageDataList.removeWhere((p) => p.canBeSqueezed);
    if (pageDataList.isEmpty) {
      pageDataList.add(
        PageData.empty(
          title: widget.config.defaultPageTitle,
        ),
      );
    }
    pageDataList.sort((p1, p2) => p1.index.compareTo(p2.index));
    for (int i = 0; i < pageDataList.length; i++) {
      pageDataList[i].index = i;
    }
    if (currentPageIndex >= pageDataList.length) {
      currentPageIndex = pageDataList.length - 1;
    }
  }

  PageData get curPageData {
    return pageDataList[currentPageIndex];
  }

  bool get isRtl => Directionality.of(context) == TextDirection.rtl;

  Widget _getSettingsButton() {
    List<SettingsItem?> items = [];
    items.add(
      SettingsItem(
        title: widget.config.editPages,
        icon: const Icon(Icons.settings),
        onSelected: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                PagesScreen(
                  config: widget.config,
                  pages: pageDataList,
                ),
          ));
        },
      ),
    );
    if (!curPageData.notEditable) {
      items.add(null);
      for (var ac in actionsCategories) {
        items.add(
          SettingsItem(
            title: ac.title,
            icon: ac.icon,
            onSelected: () async {
              await pickAndCreateNew(ac);
            },
          ),
        );
      }
      if (curPageData.actionsStates.length > 1) {
        items.add(null);
        items.add(
          SettingsItem(
            title: widget.config.arrangeInGrid,
            icon: const Icon(Icons.grid_on),
            onSelected: () async {
              modifyCirclesToGrid(curPageData.actionsStates);
            },
          ),
        );
      }
      if (kDebugMode) {
        items.add(SettingsItem(
            icon: const Icon(Icons.bug_report_outlined),
            title: widget.config.devInfo,
            onSelected: () async {
              await _debugStates();
            }));
      }
    }
    return FloatingActionButton(
      heroTag: 'settings_button',
      onPressed: () {},
      backgroundColor: Colors.green,
      child: PopupMenuButton<SettingsItem>(
        initialValue: null,
        child: const Icon(Icons.settings),
        onSelected: (SettingsItem sa) async {
          await sa.onSelected();
          onChange();
        },
        itemBuilder: (context) {
          List<PopupMenuEntry<SettingsItem>> menuItems = [];
          for (var si in items) {
            if (si != null) {
              menuItems.add(
                PopupMenuItem<SettingsItem>(
                  child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(si.title),
                      leading: si.icon),
                  value: si,
                ),
              );
            } else {
              menuItems.add(const PopupMenuDivider());
            }
          }
          return menuItems;
        },
      ),
    );
  }

  Future<void> pickAndCreateNew(ActionsCategory cat) async {
    Set<String> curCodes = pageDataList.fold(
      <String>{},
          (curSet, p) =>
          curSet.union(
            p.actionsStates.map((s) => s.action.code).toSet(),
          ),
    );
    PickActionCallback pickAction = widget.pickActionCallback ??
        pickActionSimple;
    OpAction? newAction = await pickAction(
      context,
      category: cat
      actionsProvider: widget.actionsProvider,
      curCodes: curCodes,
      config: widget.config,
    );
    if (newAction != null) {
      curPageData.actionsStates.add(
        ActionMenuItemState(
          actionsProvider: widget.actionsProvider,
          actionCode: newAction.code,
          x: initialOffset + 100 + curPageData.actionsStates.length * 10,
          y: MediaQuery
              .of(context)
              .size
              .height - 350,
          radius: 50,
          fillColor: Theme
              .of(context)
              .primaryColor,
        ),
      );
      onChange();
    }
  }

  Widget getBottomActions() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _getSettingsButton(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pages': [for (var p in pageDataList) p.toMap()],
      'timestampMs': DateTime
          .now()
          .millisecondsSinceEpoch,
      'version': DUMP_VERSION,
    };
  }

  Future<void> _debugStates() async {
    Map<String, dynamic> data = toMap();
    String debugData = const JsonEncoder.withIndent('    ').convert(data);
    debugPrint('data = $debugData');
  }

  Future<void> _dumpStates() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    Map<String, dynamic> data = toMap();
    String value = jsonEncode(data);
    await sp.setString(widget.config.spKey, value);
  }

  Future<void> _buildPages() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? localSavedText = sp.getString(widget.config.spKey);
    Map<String, dynamic>? savedMap;
    if (localSavedText != null) {
      try {
        savedMap = jsonDecode(localSavedText);
      } catch (ex, stacktrace) {
        debugPrint('$ex\n$stacktrace');
        savedMap = null;
      }
    }
    savedMap ??= widget.extSavedMap;
    List<Map<String, dynamic>> pagesMaps = getStartMenuPages(
      savedMap,
      widget.readonlyPagesMaps,
    );
    pageDataList = pagesMaps
        .map(
          (m) =>
          PageData.fromMap(
            m,
            actionsProvider: widget.actionsProvider,
            defaultTitle: widget.config.defaultPageTitle,
          ),
    )
        .toList();
    squeezeAndSortPages();
  }
}
