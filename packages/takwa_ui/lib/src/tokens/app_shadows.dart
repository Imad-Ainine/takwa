import 'package:flutter/material.dart';

/// Static shadow presets and ambient bloom tokens.
abstract final class AppShadows {
  AppShadows._();

  /// Soft, diffuse card shadow.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  /// Elevated modal and sheet shadow.
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, -4),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  /// Warm gold glow for active prayer or Ramadan mode.
  static const List<BoxShadow> goldGlow = [
    BoxShadow(
      color: Color(0x33C8A96E),
      offset: Offset(0, 2),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  /// Serene teal ambient glow for recitation audio and bookmarks.
  static const List<BoxShadow> tealGlow = [
    BoxShadow(
      color: Color(0x2E3AAFA9),
      offset: Offset(0, 2),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
}
