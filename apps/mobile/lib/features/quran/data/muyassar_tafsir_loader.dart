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
  /// with this name is already registered from an earlier call this run.
  ///
  /// Safe to call multiple times; safe to call before the reader screen
  /// ever opens. Never throws — a failure here just means "التفسير الميسر"
  /// won't appear in the tafsir list for this run.
  static Future<void> register() async {
    if (_attempted) return;
    _attempted = true;

    final ctrl = ql.TafsirCtrl.instance;
    // Checked against `customTafsirEntries` (what `fetchData` reads), not the
    // menu list: the failure fixed below leaves a name in the menu list with
    // no entry behind it, and trusting the menu list alone would skip
    // re-registering and keep rendering an empty tafsir.
    if (ctrl.customTafsirEntries.any((e) => e.name == name)) return;
    ctrl.tafsirAndTranslationsItems.removeWhere(
      (e) => e.isCustom && e.name == name,
    );

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

      // Not `ctrl.addCustomTafsirEntries([entry])`, which the package cannot
      // actually use here: it feeds this one index to both
      // `tafsirAndTranslationsItems.insert(index, …)` (length 45, valid) and
      // `customTafsirEntries.insert(index, …)` (empty, invalid), so the second
      // throws `RangeError: Only valid value is 0: 45`, the method swallows it,
      // and the entry never lands in the list `fetchData` reads — the tafsir
      // shows up in the menu but renders no text. Appending to both lists
      // directly is the same registration without the out-of-range insert.
      // `_persistCustoms` is deliberately skipped: this runs from a bundled
      // asset on every launch, and its restore path has the same bug.
      ctrl.tafsirAndTranslationsItems.add(entry.model);
      ctrl.customTafsirEntries.add(entry);
      ctrl.update(['tafsirs_menu_list']);
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
