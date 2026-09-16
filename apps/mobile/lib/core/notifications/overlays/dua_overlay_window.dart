import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Helper لإظهار/إخفاء overlay الأدعية
/// (يستخدم نفس UnifiedOverlayWindow كـ entry point)
class DuaOverlayNotification {
  static Future<bool?> isShowing() => FlutterOverlayWindow.isActive();

  /// يُظهر الـ Overlay من يمين الشاشة في المنتصف العمودي.
  static Future<void> show() async {
    final isActive = await FlutterOverlayWindow.isActive();
    if (isActive) await FlutterOverlayWindow.closeOverlay();

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: 'أدعية تقوى',
      overlayContent: 'دعاء اليوم',
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.topCenter,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
    );

    // نرسل البيانات بعد برهة لضمان عمل الـ Listener في الـ Isolate الآخر
    Future.delayed(const Duration(milliseconds: 500), () {
      FlutterOverlayWindow.shareData({'type': 'dua'});
    });
  }

  static Future<void> dismiss() => FlutterOverlayWindow.closeOverlay();
}
