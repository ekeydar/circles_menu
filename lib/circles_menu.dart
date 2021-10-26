import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/circle_box.dart';
import 'src/circle_menu_page.dart';
import 'src/circles_menu_item_widget.dart';
import 'src/circles_menu_models.dart';
import 'src/circles_menu_pick_action_dialog.dart';
import 'src/circles_menu_utils.dart';
import 'src/circles_to_grid.dart';
import 'src/indicator.dart';
import 'src/restore_helpers.dart';
import 'src/screens/pages_screen.dart';

export 'src/circles_menu_models.dart';

const int DUMP_VERSION = 4;

class CirclesMenu extends StatefulWidget {
  final CirclesMenuConfig config;
  final List<OpAction> actions;
  final Map<String, dynamic>? extSavedMap;
  final List<Map<String, dynamic>> readonlyPagesMaps;

  CirclesMenu(
      {Key? key,
      CirclesMenuConfig? config,
      required this.actions,
      this.extSavedMap,
      required this.readonlyPagesMaps})
      : this.config = config ?? CirclesMenuConfig();

  @override
  State<StatefulWidget> createState() => _CirclesMenuState();
}

class _CirclesMenuState extends State<CirclesMenu> {
  bool _ready = false;
  late List<PageData> pageDataList;

  // late List<ActionMenuItemState> actionStatesList;
  //late List<LabelMenuItemState> labelStatesList;
  double initialOffset = 0;
  PageController _pageController = PageController();
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  int get curNumPages => pageDataList.length;

  Future<void> _prepare() async {
    await Future.delayed(Duration(milliseconds: 2));
    initialOffset = 0;
    await _buildPages();
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      // debugPrint('menuWidth = $menuWidth');
      Map<String, OpAction> actionsByCode = {
        for (var a in widget.actions) a.code: a
      };
      for (var p in pageDataList) {
        p.removeNotApplicableActions(actionsByCode);
      }
      for (var p in pageDataList) {
        p.updateActions(actionsByCode);
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
                  pageData: this.pageDataList[pi],
                  index: pi,
                  numPages: curNumPages,
                  items: this.getItems(pageIndex: pi),
                  config: widget.config,
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

  void onChange() {
    for (var p in pageDataList) {
      p.removeDeleted();
    }
    if (this.currentPageIndex >= pageDataList.length) {
      this.currentPageIndex = pageDataList.length - 1;
    }
    _dumpStates();
    setState(() {});
  }

  List<Widget> getItems({required int pageIndex}) {
    List<Widget> result = [];
    PageData curPageData = this.pageDataList[pageIndex];
    for (var d in curPageData.actionsStates) {
      result.add(MenuItemWidget(
        config: widget.config,
        data: d,
        isReadonly: curPageData.notEditable,
        onPressed: () {
          if (d.action.enabled) {
            d.action.onPressed();
          }
        },
        child: CircleBox(
          radius: d.radius,
          child: Text(
            d.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText1!.apply(
                  color: Colors.white,
                ),
          ),
          fillColor: d.actualFillColor,
        ),
        onChange: this.onChange,
      ));
    }
    return result;
  }

  List<ActionsCategory> get actionsCategories {
    List<ActionsCategory> icons =
        widget.actions.map((a) => a.category).toSet().toList();
    return icons..sort((c1, c2) => c1.order.compareTo(c2.order));
  }

  void squeezeAndSortPages() {
    pageDataList.removeWhere((p) => p.canBeSqueezed);
    if (pageDataList.length == 0) {
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
    if (this.currentPageIndex >= pageDataList.length) {
      this.currentPageIndex = pageDataList.length - 1;
    }
  }

  PageData get curPageData {
    return this.pageDataList[currentPageIndex];
  }

  bool get isRtl => Directionality.of(context) == TextDirection.rtl;

  MainAxisAlignment get mainAlignmentForBottom =>
      isRtl ? MainAxisAlignment.end : MainAxisAlignment.start;

  Widget _getPageEditRow() {
    return Row(
      mainAxisAlignment: mainAlignmentForBottom,
      children: reverseIfTrue(
        isRtl,
        [
          if (!curPageData.notEditable) ...[
            for (var cat in actionsCategories)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: FloatingActionButton(
                  heroTag: 'circle_menu_add_${cat.code}',
                  onPressed: () async {
                    OpAction? newAction = await pickAction(widget.actions
                        .where((a) => a.category == cat)
                        .toList());
                    if (newAction != null) {
                      curPageData.actionsStates.add(
                        ActionMenuItemState(
                          action: newAction,
                          x: initialOffset +
                              100 +
                              curPageData.actionsStates.length * 10,
                          y: MediaQuery.of(context).size.height - 350,
                          radius: 50,
                          fillColor: Theme.of(context).primaryColor,
                        ),
                      );
                      onChange();
                    }
                  },
                  backgroundColor: Colors.green,
                  child: cat.icon,
                ),
              ),
            if (curPageData.actionsStates.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: FloatingActionButton(
                  heroTag: 'circle_menu_auto_order',
                  onPressed: () async {
                    modifyCirclesToGrid(curPageData.actionsStates);
                    onChange();
                  },
                  backgroundColor: Colors.green,
                  child: Icon(Icons.grid_on),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8),
            child: FloatingActionButton(
              heroTag: 'circles_menu_settings',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: RouteSettings(name: 'TripObsScreen'),
                    builder: (context) =>
                        PagesScreen(config: widget.config, pages: pageDataList),
                  ),
                );
                onChange();
              },
              backgroundColor: Colors.green,
              child: Icon(Icons.settings),
            ),
          ),
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: FloatingActionButton(
                heroTag: 'circle_menu_debug',
                onPressed: () async {
                  await _debugStates();
                },
                backgroundColor: Colors.green,
                child: Icon(Icons.bug_report_outlined),
              ),
            )
        ],
      ),
    );
  }

  Widget getBottomActions() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 10),
            _getPageEditRow(),
            if (curNumPages > 1) ...[
              PagingIndicator(
                  activeIndex: currentPageIndex, count: curNumPages),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pages': [for (var p in this.pageDataList) p.toMap()],
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
      'version': DUMP_VERSION,
    };
  }

  Future<void> _debugStates() async {
    Map<String, dynamic> data = this.toMap();
    String debugData = JsonEncoder.withIndent('    ').convert(data);
    debugPrint('data = $debugData');
  }

  Future<void> _dumpStates() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    Map<String, dynamic> data = this.toMap();
    String value = jsonEncode(data);
    await sp.setString(widget.config.spKey, value);
  }

  Future<void> _buildPages() async {
    Map<String, OpAction> actionsByCode = {
      for (var a in widget.actions) a.code: a
    };
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
    this.pageDataList = pagesMaps
        .map(
          (m) => PageData.fromMap(
            m,
            actionsByCode: actionsByCode,
            defaultTitle: widget.config.defaultPageTitle,
          ),
        )
        .toList();
    this.squeezeAndSortPages();
  }

  Future<OpAction?> pickAction(List<OpAction> actions) async {
    PageData curPageData = pageDataList[currentPageIndex];
    Set<String> curCodes = pageDataList.fold(
      <String>{},
      (curSet, p) => curSet.union(
        p.actionsStates.map((s) => s.action.code).toSet(),
      ),
    );
    curPageData.actionsStates.map((d) => d.action.code).toSet();
    actions.sort((a1, a2) => a1.title.compareTo(a2.title));
    return await showDialog<OpAction>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PickActionDialog(
            actions: actions,
            config: widget.config,
            curCodes: curCodes,
          );
        });
  }
}
