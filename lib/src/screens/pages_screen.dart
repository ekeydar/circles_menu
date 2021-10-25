import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../circles_menu_confirm.dart';
import '../circles_menu_models.dart';
import '../circles_menu_utils.dart';

class PagesScreen extends StatefulWidget {
  final CirclesMenuConfig config;
  final List<PageData> pages;

  PagesScreen({
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
                widget.pages.forEachIndexed((index, p) {
                  p.index = index;
                });
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
                    widget.pages.add(PageData(
                      title: title,
                      index: widget.pages.length,
                      externalId: null,
                      actionsStates: [],
                      isOwner: false,
                    ));
                    setState(() {});
                  }
                },
                title: Text(widget.config.addPage),
                leading: Icon(
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
    Widget child = Card(
        elevation: 5,
        child: ListTile(
          title: Text(page.title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (page.externalId != null) Icon(Icons.lock),
              Text('${page.actionsStates.length}'),
            ],
          ),
        ));
    if (page.externalId != null) {
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
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(left: 32.0, right: 32.0),
            child: Icon(Icons.delete),
          ),
        ),
      ),
      onDismissed: (DismissDirection direction) {
        setState(() {
          widget.pages.remove(page);
        });
      },
      key: ValueKey(page),
      child: child,
    );
  }
}
