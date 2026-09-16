import 'package:quran_library/quran_library.dart';

class QuranUtils {
  static String getVerse(int surahNumber, int verseNumber) {
    try {
      final ctrl = QuranCtrl.instance;
      // Find the verse in the global ayahs list
      // Note: surahNumber in quran_library starts from 1, same as verseNumber
      final ayah = ctrl.ayahs.firstWhere(
        (a) => a.surahNumber == surahNumber && a.ayahNumber == verseNumber,
      );
      return ayah.text;
    } catch (e) {
      return "";
    }
  }

  static String getBasmala() {
    return "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ";
  }
}
