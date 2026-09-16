import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class TimezoneResolver {
  static bool _initialized = false;

  static void ensureInitialized() {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      _initialized = true;
    }
  }

  /// Resolve timezone from coordinates
  static String resolveFromCoordinates(double lat, double lng) {
    // Africa / Arab region zones
    if (lng >= -6 && lng <= 37 && lat >= 15 && lat <= 38) {
      // شمال أفريقيا
      if (lng < 10) return 'Africa/Algiers'; // الجزائر، المغرب
      if (lng < 20) return 'Africa/Tunis'; // تونس، ليبيا
      return 'Africa/Cairo'; // مصر
    }
    if (lng >= 37 && lng <= 60 && lat >= 12 && lat <= 38) {
      // الخليج والشرق الأوسط
      if (lng < 44) return 'Asia/Riyadh'; // السعودية، اليمن
      if (lng < 52) return 'Asia/Kuwait'; // الكويت، العراق
      if (lat > 23) return 'Asia/Dubai'; // الإمارات، عُمان
      return 'Asia/Aden';
    }
    if (lat > 30 && lng >= 33 && lng <= 42) {
      return 'Asia/Jerusalem'; // فلسطين، الأردن
    }
    if (lat > 33 && lng >= 35 && lng <= 42) {
      return 'Asia/Beirut'; // لبنان، سوريا
    }

    // Default: UTC offset guess
    final offsetHours = (lng / 15).round();
    if (offsetHours >= 0) {
      return 'Etc/GMT${offsetHours > 0 ? "-$offsetHours" : ""}';
    }
    return 'Etc/GMT+${offsetHours.abs()}';
  }

  /// Set local timezone
  static void setLocalTimezone(String tzName) {
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // fallback to UTC
      tz.setLocalLocation(tz.UTC);
    }
  }
}
