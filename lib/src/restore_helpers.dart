List<Map<String, dynamic>> getStartMenuPages(
  Map<String, dynamic>? saved,
  List<Map<String, dynamic>> readonlyPages,
) {
  List<Map<String, dynamic>> pages = List<Map<String, dynamic>>.from(
      saved == null ? [] : (saved['pages'] ?? []));
  for (var p in readonlyPages) {
    mergeReadonlyPage(pages, p);
  }
  return pages;
}

mergeReadonlyPage(List<Map<String, dynamic>> pages, Map<String, dynamic> pm) {
  // check if map with externalId exists
  // if so, copy the index to the new one and delete the old one (in case there were updates)
  // otherwise, just add at the end
  if (pm['externalId'] == null) {
    return;
  }
  int prevPmIndex =
      pages.indexWhere((m) => m['externalId'] == pm['externalId']);
  int newIndex = prevPmIndex >= 0 ? pages[prevPmIndex]['index'] : pages.length;
  pm['index'] = newIndex;
  if (prevPmIndex >= 0) {
    pages.removeAt(prevPmIndex);
  }
  pages.add(pm);
}
