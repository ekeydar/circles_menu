import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/circle_box.dart';
import 'src/circle_menu_page.dart';
import 'src/circles_menu_confirm.dart';
import 'src/circles_menu_item_widget.dart';
import 'src/circles_menu_models.dart';
import 'src/circles_menu_pick_action_dialog.dart';
import 'src/circles_menu_utils.dart';
import 'src/circles_to_grid.dart';
import 'src/indicator.dart';
import 'src/restore_helpers.dart';

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
  late String _clonedData;

  // late List<ActionMenuItemState> actionStatesList;
  //late List<LabelMenuItemState> labelStatesList;
  double initialOffset = 0;
  bool isInEdit = false;
  PageController _pageController = PageController();
  int currentPageIndex = 0;

  void clonePages() {
    _clonedData = jsonEncode(this.toMap());
  }

  void restorePagesFromClone() {
    Map<String, OpAction> actionsByCode = {
      for (var a in widget.actions) a.code: a
    };
    Map<String, dynamic> _clonedMap = jsonDecode(_clonedData);
    List<Map<String, dynamic>> pageMaps =
        List<Map<String, dynamic>>.from(_clonedMap['pages']);
    this.pageDataList = pageMaps
        .map(
          (m) => PageData.fromMap(m, actionsByCode: actionsByCode),
        )
        .toList();
  }

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
      List<Color> colors = [Colors.red, Colors.green, Colors.blue];
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
                  buttons: this.getButtons(context, pageIndex: pi),
                  color: colors[pi % colors.length],
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
        isInEdit: this.isInEdit,
        isReadonly: curPageData.readonly,
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
          borderColor: d.borderColor,
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

  List<Widget> getButtons(BuildContext context, {required int pageIndex}) {
    List<Widget> result = [];
    if (isInEdit) {
      Widget? startCenterWidget = getPageCenterColumn(
        pageIndex: pageIndex,
        numPages: curNumPages,
        isStartSide: true,
      );
      Widget? endCenterWidget = getPageCenterColumn(
        pageIndex: pageIndex,
        numPages: curNumPages,
        isStartSide: false,
      );
      if (startCenterWidget != null) {
        result.add(startCenterWidget);
      }
      if (endCenterWidget != null) {
        result.add(endCenterWidget);
      }
    }
    return result;
  }

  void squeezeAndSortPages() {
    pageDataList.removeWhere((p) => p.canBeSqueezed);
    if (pageDataList.length == 0) {
      pageDataList.add(PageData.empty());
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

  Widget _getGlobalEditRow() {
    return Row(
      mainAxisAlignment: mainAlignmentForBottom,
      children: reverseIfTrue(
        isRtl,
        [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8),
            child: FloatingActionButton(
              heroTag: 'circles_menu_approve_edit',
              onPressed: () async {
                this.isInEdit = false;
                this.onChange();
                this.squeezeAndSortPages();
                // animate to current page - to refresh indicators
                // instead of page deleted at end or middle
                this._pageController.animateToPage(
                      this.currentPageIndex,
                      duration: Duration(milliseconds: 10),
                      curve: Curves.easeIn,
                    );
                if (widget.config.onEditDone != null) {
                  widget.config.onEditDone!();
                }
              },
              backgroundColor: Colors.green,
              child: Icon(Icons.check),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8),
            child: FloatingActionButton(
              heroTag: 'circle_menu_cancel_edit',
              onPressed: () async {
                if (await askConfirmation(
                    context, widget.config.cancelEditsConfirmation,
                    config: widget.config)) {
                  setState(() {
                    this.restorePagesFromClone();
                  });
                }
              },
              backgroundColor: Colors.red,
              child: Icon(Icons.cancel),
            ),
          ),
          if (curPageData.externalId != null) ...[
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: FloatingActionButton(
                heroTag: 'circle_menu_lock_for_owner',
                onPressed: null,
                backgroundColor: Colors.red,
                tooltip: curPageData.isOwner ? (curPageData.displayTitle) : null,
                child: Icon(Icons.lock),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _getPageEditRow() {
    return Row(
      mainAxisAlignment: mainAlignmentForBottom,
      children: reverseIfTrue(
        isRtl,
        [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8),
            child: FloatingActionButton(
              heroTag: 'circle_menu_delete',
              onPressed: () async {
                if (await askConfirmation(
                    context, widget.config.emptyPageConfirmation,
                    config: widget.config)) {
                  curPageData.empty();
                  onChange();
                }
              },
              backgroundColor: Colors.red,
              child: Icon(Icons.delete),
            ),
          ),
          for (var cat in actionsCategories)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: FloatingActionButton(
                heroTag: 'circle_menu_add_${cat.code}',
                onPressed: () async {
                  OpAction? newAction = await pickAction(
                      widget.actions.where((a) => a.category == cat).toList());
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
          if (curPageData.actionsStates.isNotEmpty)
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
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8),
            child: FloatingActionButton(
              heroTag: 'circle_menu_edit_title',
              onPressed: () async {
                String? newTitle = await editText(
                  context,
                  initialText: curPageData.title,
                  config: widget.config,
                  title: widget.config.editPageTitle,
                );
                if (newTitle != null) {
                  curPageData.title = newTitle;
                }
                onChange();
              },
              backgroundColor: Colors.green,
              child: Icon(Icons.font_download_outlined),
            ),
          ),
        ],
      ),
    );
  }

  _getNonEditRow() {
    return Row(
      mainAxisAlignment: mainAlignmentForBottom,
      children: reverseIfTrue(
        isRtl,
        [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8),
            child: FloatingActionButton(
              heroTag: 'circles_menu_start_edit',
              onPressed: () async {
                // save the state before the start edit
                this.clonePages();
                setState(() {
                  this.isInEdit = true;
                });
              },
              backgroundColor: Colors.red,
              child: Icon(Icons.edit),
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
            if (isInEdit) ...[
              _getGlobalEditRow(),
              if (!curPageData.readonly) ...[
                SizedBox(height: 10),
                _getPageEditRow(),
              ]
            ],
            // if (isInEdit && curPageData.readonly)
            //   Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Padding(
            //         padding: const EdgeInsets.only(left: 8.0, right: 8),
            //         child: FloatingActionButton(
            //           heroTag: 'circles_menu_lock',
            //           onPressed: null,
            //           backgroundColor: Colors.red,
            //           child: Icon(Icons.lock),
            //         ),
            //       )
            //     ],
            //   ),
            if (!isInEdit) _getNonEditRow(),
            if (curNumPages > 1) ...[
              PagingIndicator(
                  activeIndex: currentPageIndex, count: curNumPages),
            ],
          ],
        ),
      ),
    );
  }

  Widget? getPageCenterColumn(
      {required int pageIndex,
      required bool isStartSide,
      required int numPages}) {
    bool addSwap = isStartSide && pageIndex > 0 ||
        numPages > 1 && !isStartSide && pageIndex < numPages - 1;
    bool addPlus = !isStartSide && pageIndex == numPages - 1;
    List<Widget> children = [
      if (addSwap)
        IconButton(
          onPressed: () async {
            bool cont = await askConfirmation(
              context,
              isStartSide
                  ? widget.config.swapWithPrevPageConfirmation
                  : widget.config.swapWithNextPageConfirmation,
              config: widget.config,
            );
            if (!cont) {
              return;
            }
            _swapPages(pageIndex, isStartSide ? pageIndex - 1 : pageIndex + 1);
            onChange();
          },
          icon: Icon(
            Icons.swap_horiz,
            size: 40,
          ),
        ),
      if (addPlus)
        IconButton(
          onPressed: () async {
            pageDataList.add(PageData.empty(index: pageDataList.length));
            onChange();
            this._pageController.animateToPage(
                  pageDataList.length - 1,
                  duration: Duration(milliseconds: 10),
                  curve: Curves.easeIn,
                );
          },
          icon: Icon(
            Icons.add,
            size: 40,
          ),
        ),
    ];
    if (children.isEmpty) {
      return null;
    }
    return Align(
      alignment: isStartSide ? Alignment.topRight : Alignment.topLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: children,
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
          ),
        )
        .toList();
    this.squeezeAndSortPages();
  }

  void _swapPages(int pageIndex1, int pageIndex2) {
    PageData p1 = pageDataList[pageIndex1];
    PageData p2 = pageDataList[pageIndex2];
    p1.index = pageIndex2;
    p2.index = pageIndex1;
    pageDataList.sort((p1, p2) => p1.index.compareTo(p2.index));
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
