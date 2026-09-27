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
        // `id` is what the tafsir sheet matches on: TafsirPagesBuild looks an
        // ayah up as `tafseerList.firstWhere((e) => e.id == ayahUQNumber)`,
        // where ayahUQNumber is the 1-based global ayah number (Al-Fatiha 1:1
        // is 1, Al-Baqarah 2:1 is 8). The asset is in canonical mushaf order
        // (verified: 6236 rows, one per ayah, none empty), so row i is ayah
        // i+1. A 0-based id would show the next ayah's tafsir text.
        for (var i = 0; i < rows.length; i++)
          ql.TafsirTableData(
            id: i + 1,
            surahNum: rows[i]['s'] as int,
            ayahNum: rows[i]['a'] as int,
            tafsirText: rows[i]['t'] as String,
            // Only read by the page-filtered fetch path (fetchTafsirPage),
            // which the sheet doesn't use; TafsirCtrl.fetchData ignores
            // pageNum for custom entries.
            pageNum: 0,
          ),
      ];

      // Must land in the tafsir section of the list, not at the end:
      // TafsirCtrl treats any index >= `translationsStartIndex` as a
      // translation (`isCurrentATranslation`), which makes `fetchData` skip
      // the custom-entry branch and instead try to open
      // `<appDir>/muyassar_ar.json` — a file that isn't there, since this
      // tafsir is bundled as an asset. The result is an empty `tafseerList`
      // and a bottom sheet that renders `SizedBox.shrink()`, i.e. a blank
      // body under a selected "التفسير الميسر" chip.
      // Inserting *at* translationsStartIndex pushes every translation one
      // slot right, so `translationsStartIndex` itself moves up by one and
      // this entry ends up just inside the tafsir range.
      final insertAt = ctrl.tafsirAndTranslationsItems.indexWhere(
        (e) => e.isTranslation,
      );
      final at = insertAt == -1
          ? ctrl.tafsirAndTranslationsItems.length
          : insertAt;
      // radioValue was resolved against the list before the shift; keep it
      // pointing at the same entry it selected at startup.
      if (ctrl.radioValue.value >= at) ctrl.radioValue.value++;

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
        index: at,
      );

      // Not `ctrl.addCustomTafsirEntries([entry])`, which the package cannot
      // actually use here: it feeds this one index to both
      // `tafsirAndTranslationsItems.insert(index, …)` (length 45, valid) and
      // `customTafsirEntries.insert(index, …)` (empty, invalid), so the second
      // throws `RangeError: Only valid value is 0: 45`, the method swallows it,
      // and the entry never lands in the list `fetchData` reads — the tafsir
      // shows up in the menu but renders no text. Inserting into both lists
      // directly is the same registration without the out-of-range insert.
      // `_persistCustoms` is deliberately skipped: this runs from a bundled
      // asset on every launch, and its restore path has the same bug.
      ctrl.tafsirAndTranslationsItems.insert(at, entry.model);
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
