import 'dart:convert';

import 'package:flutter/foundation.dart';

class RestoreFromStringData {
  final List<Map<String, dynamic>> pagesMaps;
  final int version;

  RestoreFromStringData({required this.pagesMaps, required this.version});

  RestoreFromStringData.empty()
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

RestoreFromStringData restoreFromStringSafe({
  required String? dumpText,
  required List<String>? readonlyPagesTexts,
}) {
  // the dump text is the user dumps (either from external DB or from shared_preferences)
  // readonlyPagesTexts is dump of readonly pages (with external id), they will be merge and combined
  RestoreFromStringData fromInitial = _restoreFromInitial(dumpText);
  late List<Map<String, dynamic>> readonlyPageMaps;
  try {
    readonlyPageMaps = (readonlyPagesTexts ?? []).map((t) {
      return Map<String, dynamic>.from(jsonDecode(t));
    }).toList();
  } catch (ex, stacktrace) {
    debugPrint('ex = $ex\nstacktrace = $stacktrace');
    readonlyPageMaps = [];
  }
  for (var m in readonlyPageMaps) {
    fromInitial.mergeReadonlyPage(m);
  }
  return fromInitial;
}

RestoreFromStringData _restoreFromInitial(String? dumpText) {
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
