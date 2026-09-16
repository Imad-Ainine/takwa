/// حالة الصلاة
enum PrayerStatus {
  notDue, // لم يحن وقتها
  pending, // حان وقتها لم تُؤدَّ
  performed, // أُديت في وقتها
  qadaa, // قُضيت خارج الوقت
  missed, // فاتت
}

/// نوع الصيام
enum FastingType {
  none, // لم يصم
  fard, // فريضة (رمضان)
  nafl, // نافلة
  makruh, // أفطر بعذر
}

/// فئة المحظور
enum ProhibitionCategory {
  ghadhBasar, // غضّ البصر
  gheeba, // الغيبة
  nameema, // النميمة
  kadhb, // الكذب
  ghaDab, // الغضب
  idaatWaqt, // إضاعة الوقت
  custom, // مخصص
}

/// مستوى التقوى
enum TaqwaLevel {
  mubtadi, // مبتدئ  0–99
  salik, // سالك   100–299
  mujahid, // مجاهد  300–599
  mutaqi, // متقي   600+
}

/// The single source of truth for points → [TaqwaLevel] — was previously
/// duplicated (with the same 600/300/100 thresholds hardcoded twice) in
/// `StatsDao.getTaqwaLevel` and `MonthStats.level`.
TaqwaLevel taqwaLevelFor(int totalPoints) {
  if (totalPoints >= 600) return TaqwaLevel.mutaqi;
  if (totalPoints >= 300) return TaqwaLevel.mujahid;
  if (totalPoints >= 100) return TaqwaLevel.salik;
  return TaqwaLevel.mubtadi;
}
