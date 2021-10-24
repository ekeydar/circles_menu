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
import 'src/label_menu_button.dart';

export 'src/circles_menu_models.dart';

const int DUMP_VERSION = 4;

class CirclesMenu extends StatefulWidget {
  final CirclesMenuConfig config;
  final List<OpAction> actions;
  final String? initialDump;
  final String? defaultDump;

  CirclesMenu(
      {Key? key,
      CirclesMenuConfig? config,
      required this.actions,
      this.initialDump,
      this.defaultDump})
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
    List<Map<String, dynamic>> _clonedPages =
        List<Map<String, dynamic>>.from(jsonDecode(_clonedData));
    pageDataList = _clonedPages
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
                  index: pi,
                  numPages: curNumPages,
                  items: this.getItems(pageIndex: pi),
                  buttons: this.getButtons(context, pageIndex: pi),
                  color: colors[pi % colors.length],
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
    for (LabelMenuItemState d in curPageData.labelsStates) {
      result.add(MenuItemWidget(
        config: widget.config,
        isInEdit: this.isInEdit,
        data: d,
        onChange: this.onChange,
        onPressed: null,
        child: LabelMenuButton(
          config: widget.config,
          data: d,
          isInEdit: this.isInEdit,
          onChange: this.onChange,
        ),
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
    pageDataList.removeWhere((p) => p.canBeDeleted);
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

  Widget getBottomActions() {
    int pageIndex = this.currentPageIndex;
    PageData curPageData = this.pageDataList[pageIndex];
    bool isRtl = Directionality.of(context) == TextDirection.rtl;
    MainAxisAlignment mainAlignment =
        isRtl ? MainAxisAlignment.end : MainAxisAlignment.start;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (curNumPages > 1)
              PagingIndicator(activeIndex: pageIndex, count: curNumPages),
            if (isInEdit) ...[
              Row(
                mainAxisAlignment: mainAlignment,
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
                    // if (widget.defaultDump != null)
                    //   Padding(
                    //     padding: const EdgeInsets.only(left: 8.0, right: 8),
                    //     child: FloatingActionButton(
                    //       heroTag: 'circle_menu_reset',
                    //       onPressed: () async {
                    //         if (await askConfirmation(
                    //             context, widget.config.resetConfirmation,
                    //             config: widget.config)) {
                    //           await _buildPages(reset: true);
                    //           onChange();
                    //         }
                    //       },
                    //       backgroundColor: Colors.red,
                    //       child: Icon(Icons.auto_delete),
                    //     ),
                    //   ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: mainAlignment,
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
                            OpAction? newAction = await pickAction(widget
                                .actions
                                .where((a) => a.category == cat)
                                .toList());
                            if (newAction != null) {
                              curPageData.actionsStates.add(
                                ActionMenuItemState(
                                  pageIndex: pageIndex,
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
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8),
                      child: FloatingActionButton(
                        heroTag: 'circle_menu_add_label',
                        onPressed: () async {
                          String? newText = await editText(
                            context,
                            config: widget.config,
                          );
                          if (newText != null) {
                            curPageData.labelsStates.add(
                              LabelMenuItemState(
                                pageIndex: pageIndex,
                                label: newText,
                                fontSize: 20,
                                x: initialOffset +
                                    100 +
                                    curPageData.labelsStates.length * 10,
                                y: MediaQuery.of(context).size.height - 350,
                                color: Theme.of(context).primaryColor,
                              ),
                            );
                            onChange();
                          }
                        },
                        backgroundColor: Colors.green,
                        child: Icon(Icons.font_download_outlined),
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
                      )
                  ],
                ),
              ),
            ],
            if (!isInEdit)
              Row(
                mainAxisAlignment: mainAlignment,
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
              )
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
    String? dumpText;
    if (!sp.containsKey(widget.config.spKey)) {
      dumpText = widget.initialDump ?? widget.defaultDump;
    } else {
      dumpText = sp.getString(widget.config.spKey);
    }
    RestoreFromStringData restoreData = restoreFromStringSafe(dumpText);
    this.pageDataList = restoreData.pagesMaps
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

  RestoreFromStringData restoreFromStringSafe(String? dumpText) {
    if (dumpText == null) {
      return RestoreFromStringData.empty();
    }
    try {
      Map<String, dynamic> dump = jsonDecode(dumpText);
      int version = dump['version'];
      return RestoreFromStringData(
          version: version,
          pagesMaps: List<Map<String, dynamic>>.from(dump['pages'] ?? []));
    } catch (ex, stacktrace) {
      debugPrint('ex = $ex');
      debugPrint('$stacktrace');
      return RestoreFromStringData.empty();
    }
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
