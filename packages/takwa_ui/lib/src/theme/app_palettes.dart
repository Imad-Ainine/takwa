import 'package:flutter/material.dart';

/// Primitive tonal color ramps for the Takwa Design System.
///
/// Modeled after Shopify Polaris / IBM Carbon palettes: raw, theme-agnostic
/// color scales (10 steps each, 50 = lightest, 900 = darkest) from which the
/// semantic tokens in [AppColorsExtension] are derived. Ramps are anchored to
/// the brand colors so semantic tokens stay visually continuous:
///
/// | Ramp  | Anchor (semantic token)              |
/// |-------|--------------------------------------|
/// | gold  | `gold500` == `AppColorsExtension.gold` (brand primary) |
/// | teal  | `teal500` == `AppColorsExtension.teal` (brand secondary) |
/// | green | `green500` == `AppColorsExtension.success` |
/// | red   | `red500` == `AppColorsExtension.danger` |
/// | red   | `red800` == `AppColorsExtension.dangerText` (light) |
/// | gold  | `gold800` == `AppColorsExtension.goldText` (light) |
/// | teal  | `teal900` == `AppColorsExtension.tealText` (light) |
/// | yellow| `yellow800` == `AppColorsExtension.warningText` (light) |
///
/// Steps 50–300 are fill/background tints, 400–600 are interactive fills,
/// 700–900 are foreground/on-surface colors (the dark steps clear WCAG AA
/// on light surfaces).
abstract final class AppPalette {
  // ── Neutral (cool slate) ──
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF3A4453);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // ── Gold (brand primary) ──
  static const Color gold50 = Color(0xFFFBF8F0);
  static const Color gold100 = Color(0xFFF6EEDD);
  static const Color gold200 = Color(0xFFEEDFB9);
  static const Color gold300 = Color(0xFFE4C98A);
  static const Color gold400 = Color(0xFFD5B779);
  static const Color gold500 = Color(0xFFC8A96E);
  static const Color gold600 = Color(0xFFA88A54);
  static const Color gold700 = Color(0xFF8A6E3F);
  static const Color gold800 = Color(0xFF6B5320);
  static const Color gold900 = Color(0xFF503D15);

  // ── Teal (brand secondary) ──
  static const Color teal50 = Color(0xFFF0FAFA);
  static const Color teal100 = Color(0xFFD9F2F1);
  static const Color teal200 = Color(0xFFADE3E1);
  static const Color teal300 = Color(0xFF7CD4D0);
  static const Color teal400 = Color(0xFF54C2BD);
  static const Color teal500 = Color(0xFF3AAFA9);
  static const Color teal600 = Color(0xFF2E938E);
  static const Color teal700 = Color(0xFF257873);
  static const Color teal800 = Color(0xFF1A6B65);
  static const Color teal900 = Color(0xFF0F5C57);

  // ── Green (success) ──
  static const Color green50 = Color(0xFFF0FAF4);
  static const Color green100 = Color(0xFFDCF3E5);
  static const Color green200 = Color(0xFFB8E6CC);
  static const Color green300 = Color(0xFF8CD8AC);
  static const Color green400 = Color(0xFF67C78F);
  static const Color green500 = Color(0xFF4CAF7D);
  static const Color green600 = Color(0xFF3C9166);
  static const Color green700 = Color(0xFF2F7A52);
  static const Color green800 = Color(0xFF20613F);
  static const Color green900 = Color(0xFF174D31);

  // ── Red (danger / critical) ──
  static const Color red50 = Color(0xFFFEF3F3);
  static const Color red100 = Color(0xFFFDE4E4);
  static const Color red200 = Color(0xFFFACACA);
  static const Color red300 = Color(0xFFF5A6A6);
  static const Color red400 = Color(0xFFED8A8A);
  static const Color red500 = Color(0xFFE07070);
  static const Color red600 = Color(0xFFC25151);
  static const Color red700 = Color(0xFFB03A38);
  static const Color red800 = Color(0xFFA81E17);
  static const Color red900 = Color(0xFF7E1510);

  // ── Yellow (warning) ──
  static const Color yellow50 = Color(0xFFFEF9EE);
  static const Color yellow100 = Color(0xFFFDF0D8);
  static const Color yellow200 = Color(0xFFFAE0AE);
  static const Color yellow300 = Color(0xFFF5CC80);
  static const Color yellow400 = Color(0xFFEBB75F);
  static const Color yellow500 = Color(0xFFE0A044);
  static const Color yellow600 = Color(0xFFC08430);
  static const Color yellow700 = Color(0xFF9C6A1E);
  static const Color yellow800 = Color(0xFF7A5210);
  static const Color yellow900 = Color(0xFF5C3D0A);

  // ── Blue (informational) ──
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);

  // ── Full ramps, ordered 50 → 900 (for swatch strips / tooling) ──
  static const List<Color> neutral = [
    neutral50, neutral100, neutral200, neutral300, neutral400,
    neutral500, neutral600, neutral700, neutral800, neutral900,
  ];
  static const List<Color> gold = [
    gold50, gold100, gold200, gold300, gold400,
    gold500, gold600, gold700, gold800, gold900,
  ];
  static const List<Color> teal = [
    teal50, teal100, teal200, teal300, teal400,
    teal500, teal600, teal700, teal800, teal900,
  ];
  static const List<Color> green = [
    green50, green100, green200, green300, green400,
    green500, green600, green700, green800, green900,
  ];
  static const List<Color> red = [
    red50, red100, red200, red300, red400,
    red500, red600, red700, red800, red900,
  ];
  static const List<Color> yellow = [
    yellow50, yellow100, yellow200, yellow300, yellow400,
    yellow500, yellow600, yellow700, yellow800, yellow900,
  ];
  static const List<Color> blue = [
    blue50, blue100, blue200, blue300, blue400,
    blue500, blue600, blue700, blue800, blue900,
  ];
}
