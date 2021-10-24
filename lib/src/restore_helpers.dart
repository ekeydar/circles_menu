import 'dart:convert';

import 'package:flutter/foundation.dart';

class RestoreData {
  final List<Map<String, dynamic>> pagesMaps;
  final int version;

  RestoreData({required this.pagesMaps, required this.version});

  RestoreData.empty()
      : version = 0,
        pagesMaps = [];

  mergeReadonlyPage(Map<String, dynamic> pm) {
    // check if map with externalId exists
    // if so, copy the index to the new one and delete the old one (in case there were updates)
    // otherwise, just add at the end
    if (pm['externalId'] == null) {
      return;
    }
    int prevPmIndex =
        pagesMaps.indexWhere((m) => m['externalId'] == pm['externalId']);
    int newIndex =
        prevPmIndex >= 0 ? pagesMaps[prevPmIndex]['index'] : pagesMaps.length;
    pm['index'] = newIndex;
    if (prevPmIndex >= 0) {
      pagesMaps.removeAt(prevPmIndex);
    }
    pagesMaps.add(pm);
  }
}

RestoreData buildRestoreData({
  required String? dumpText,
  required List<Map<String, dynamic>> readonlyPagesMaps,
}) {
  // the dump text is the user dumps (either from external DB or from shared_preferences)
  // readonlyPagesTexts is dump of readonly pages (with external id), they will be merge and combined
  RestoreData fromInitial = _restoreFromInitial(dumpText);
  Set<String> externalIds = <String>{};
  for (var m in readonlyPagesMaps) {
    if (m['externalId'] != null) {
      fromInitial.mergeReadonlyPage(m);
      externalIds.add(m['externalId']);
    }
  }
  // remove pages with externalId if it does not appear any more
  fromInitial.pagesMaps.removeWhere(
      (m) => m['externalId'] != null && !externalIds.contains(m['externalId']));
  return fromInitial;
}

RestoreData _restoreFromInitial(String? dumpText) {
  if (dumpText == null) {
    return RestoreData.empty();
  }
  try {
    Map<String, dynamic> dump = jsonDecode(dumpText);
    int version = dump['version'];
    return RestoreData(
        version: version,
        pagesMaps: List<Map<String, dynamic>>.from(dump['pages'] ?? []));
  } catch (ex, stacktrace) {
    debugPrint('ex = $ex');
    debugPrint('$stacktrace');
    return RestoreData.empty();
  }
}
