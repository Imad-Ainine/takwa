import 'package:quran_library/quran_library.dart' as ql;

import 'quran_models.dart';

/// Registers [kDefaultReciters] as quran_library's per-ayah reader list.
///
/// quran_library ships its own curated reader list
/// (`ReadersConstants.ayahReaderInfo`) that only overlaps 4 of the 7
/// reciters this app's own reciter picker already lists (Alafasy, Saad
/// Al-Ghamdi and Abu Bakr Al-Shatri aren't in it at all), each pointed at
/// a different audio host. Rather than cut reciters the picker already
/// promises, this replaces that list with a matching one built from the
/// same cdn.islamic.network layout the app used before adopting
/// quran_library's engine — `ReadersConstants.customAyahReaders` is the
/// library's supported way to swap it out, and it keeps the resulting
/// index order identical to [kDefaultReciters]'s, so a reciter's position
/// in that list doubles as its `ayahReaderIndex`.
class QuranRecitersSetup {
  const QuranRecitersSetup._();

  static bool _registered = false;

  static void register() {
    if (_registered) return;
    _registered = true;
    ql.ReadersConstants.customAyahReaders = [
      for (var i = 0; i < kDefaultReciters.length; i++)
        ql.ReaderInfo(
          index: i,
          name: kDefaultReciters[i].nameAr,
          readerNamePath: '128/${kDefaultReciters[i].id}',
          url: ql.ReadersConstants.ayahs1stSource,
        ),
    ];
  }

  /// Index of [reciterId] in [kDefaultReciters] — identical to its index
  /// in the reader list registered by [register] — or -1 if unknown.
  static int indexOf(String reciterId) =>
      kDefaultReciters.indexWhere((r) => r.id == reciterId);
}
