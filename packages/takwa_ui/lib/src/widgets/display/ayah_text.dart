import 'package:flutter/material.dart';
import '../../theme/context_extensions.dart';

/// Specialized widget for rendering sacred Qur'anic verses with proper RTL typography and tashkeel line-height safety.
class AyahText extends StatelessWidget {
  final String text;
  final int? ayahNumber;
  final double? fontSize;
  final Color? color;
  final TextAlign textAlign;

  const AyahText({
    super.key,
    required this.text,
    this.ayahNumber,
    this.fontSize,
    this.color,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final verseStyle = typography.quranicVerse.copyWith(
      fontSize: fontSize ?? typography.quranicVerse.fontSize,
      color: color ?? colors.textPrimary,
    );

    final fullText = ayahNumber != null
        ? '$text \uFD3E${_toArabicDigits(ayahNumber!)}\uFD3F'
        : text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        fullText,
        textAlign: textAlign,
        style: verseStyle,
      ),
    );
  }

  static String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicDigits[int.parse(digit)])
        .join();
  }
}
