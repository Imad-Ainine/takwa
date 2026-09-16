import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran_library/quran_library.dart' as ql;

/// Registers "التفسير الميسر" (Tafsir Al-Muyassar) as a selectable tafsir
/// inside quran_library's [ql.TafsirCtrl].
///
/// quran_library ships a large bundled/downloadable tafsir & translation set
/// (QUL — Quranic Universal Library), but Al-Muyassar isn't part of it —
/// verified against both the in-package tafsir list and the library's own
/// download host (github.com/alheekmahlib/Islamic_database releases). The
/// library's supported way to add a tafsir it doesn't ship is
/// [ql.TafsirCtrl.addCustomTafsirEntries], so this loads Al-Muyassar's text
/// (bundled as a local asset — a complete, verified 6236-ayah dataset) and
/// registers it through that same API, rather than building a separate
/// bespoke tafsir system alongside the library's.
class MuyassarTafsirLoader {
  const MuyassarTafsirLoader._();

  /// Display name used both when registering the entry and when looking it
  /// back up (e.g. to preselect it before opening the tafsir sheet).
  static const String name = 'التفسير الميسر';

  static const String _assetPath = 'assets/tafsir/muyassar_ar.json';
  static const String _fileName = 'muyassar_ar';

  static bool _attempted = false;

  /// Loads the asset and registers it with [ql.TafsirCtrl], unless an entry
  /// with this name is already registered (either from an earlier call this
  /// run, or restored from a previous app run — TafsirCtrl persists custom
  /// entries across restarts).
  ///
  /// Safe to call multiple times; safe to call before the reader screen
  /// ever opens. Never throws — a failure here just means "التفسير الميسر"
  /// won't appear in the tafsir list for this run.
  static Future<void> register() async {
    if (_attempted) return;
    _attempted = true;

    final ctrl = ql.TafsirCtrl.instance;
    if (ctrl.tafsirAndTranslationsItems.any((e) => e.name == name)) {
      return;
    }

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final List<dynamic> rows = json.decode(raw) as List<dynamic>;
      final items = <ql.TafsirTableData>[
        for (var i = 0; i < rows.length; i++)
          ql.TafsirTableData(
            id: i,
            surahNum: rows[i]['s'] as int,
            ayahNum: rows[i]['a'] as int,
            tafsirText: rows[i]['t'] as String,
            // Not used for lookups on custom tafsirs (TafsirCtrl matches by
            // surah/ayah, not page, for isCustom entries) — 0 is fine.
            pageNum: 0,
          ),
      ];

      // Append rather than insert at the front: TafsirCtrl's `radioValue`
      // (the currently-selected tafsir/translation index) is computed from
      // the list as it stood when TafsirCtrl initialized — which already
      // happened by the time this runs (QuranLibrary.init() completes
      // before this is called). Inserting anywhere but the end would shift
      // every later index and silently point radioValue at the wrong item.
      final entry = ql.CustomTafsirEntry(
        name: name,
        model: ql.TafsirNameModel(
          name: name,
          fileName: _fileName,
          bookName: 'التفسير الميسر - مجمع الملك فهد لطباعة المصحف الشريف',
          databaseName: '$_fileName.json',
          isCustom: true,
          isTranslation: false,
          type: ql.TafsirFileType.json,
        ),
        items: items,
        index: ctrl.tafsirAndTranslationsItems.length,
      );

      await ctrl.addCustomTafsirEntries([entry]);
    } catch (e) {
      developer.log(
        'Failed to register Tafsir Al-Muyassar: $e',
        name: 'MuyassarTafsirLoader',
      );
    }
  }

  /// Index of the Al-Muyassar entry in [ql.TafsirCtrl.tafsirAndTranslationsItems],
  /// or -1 if it hasn't been registered (e.g. [register] failed or hasn't
  /// run yet).
  static int indexIn(ql.TafsirCtrl ctrl) =>
      ctrl.tafsirAndTranslationsItems.indexWhere((e) => e.name == name);
}
