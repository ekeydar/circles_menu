import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../circle_box.dart';
import '../circles_menu_confirm.dart';
import '../circles_menu_models.dart';
import '../circles_menu_utils.dart';

class PagesScreen extends StatefulWidget {
  final CirclesMenuConfig config;
  final List<PageData> pages;

  const PagesScreen({
    Key? key,
    required this.config,
    required this.pages,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PagesScreenState();
  }
}

class _PagesScreenState extends State<PagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.editPages),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ReorderableListView(
              shrinkWrap: true,
              onReorder: (int oldIndex, int newIndex) {
                PageData p = widget.pages[oldIndex];
                widget.pages.insert(newIndex, p);
                widget.pages
                    .removeAt(oldIndex < newIndex ? oldIndex : oldIndex + 1);
                _fixPages();
                setState(() {});
              },
              children: widget.pages.map((page) => getListItem(page)).toList(),
            ),
            Card(
              elevation: 1,
              child: ListTile(
                onTap: () async {
                  String? title = await editText(
                    context,
                    config: widget.config,
                    title: widget.config.editPageTitle,
                  );
                  if (title != null) {
                    widget.pages.add(
                      PageData(
                        title: title,
                        index: widget.pages.length,
                        externalId: null,
                        actionsStates: [],
                        isOwner: false,
                        color: PageData.defaultColor,
                      ),
                    );
                    setState(() {});
                  }
                },
                title: Text(widget.config.addPage),
                leading: const Icon(
                  Icons.add,
                  color: Colors.green,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget getListItem(PageData page) {
    bool isDismissible = !page.readonly;
    Widget child = Card(
        key: isDismissible ? null : ValueKey(page),
        elevation: 5,
        child: ListTile(
          leading: GestureDetector(
            onTap: !page.notEditable
                ? () async {
                    Color? c = await pickColor(
                      context,
                      initialColor: page.color,
                      config: widget.config,
                    );
                    if (c != null) {
                      setState(() {
                        page.color = c;
                      });
                    }
                  }
                : null,
            child: CircleBox(
              borderColor: Colors.grey,
              fillColor: page.color,
              child: const SizedBox.shrink(),
              radius: 14,
            ),
          ),
          title: Row(
            children: [
              Text(page.title),
              if (!page.readonly)
                IconButton(
                    onPressed: () async {
                      String? newTitle = await editText(
                        context,
                        config: widget.config,
                        title: widget.config.editPageTitle,
                        initialText: page.title,
                      );
                      if (newTitle != null) {
                        setState(() {
                          page.title = newTitle;
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                    )),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (page.readonly) const Icon(Icons.lock),
              Text('${page.actionsStates.length}'),
            ],
          ),
        ));
    if (!isDismissible) {
      return child;
    }
    return Dismissible(
      confirmDismiss: (DismissDirection direction) async {
        String p = widget.config.deletePageConfirmation;
        String t = page.title;
        return await askConfirmation(
          context,
          '$p: $t',
          config: widget.config,
        );
      },
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Icon(Icons.delete),
          ),
        ),
      ),
      onDismissed: (DismissDirection direction) {
        setState(() {
          widget.pages.remove(page);
          _fixPages();
        });
      },
      key: ValueKey(page),
      child: child,
    );
  }

  _fixPages() {
    if (widget.pages.isEmpty) {
      widget.pages.add(
        PageData.empty(
          title: widget.config.defaultPageTitle,
        ),
      );
    }
    widget.pages.forEachIndexed((index, p) {
      p.index = index;
    });
  }
}
