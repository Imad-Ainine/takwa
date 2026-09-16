import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// Note: overlayMain entry point has been moved to main.dart
// to ensure the plugin can correctly discover it in all environments.

class AdhkarOverlayNotification {
  /// يُظهر الـ Overlay من يمين الشاشة في المنتصف العمودي.
  static Future<void> show() async {
    final bool isActive = await FlutterOverlayWindow.isActive();
    if (isActive) await FlutterOverlayWindow.closeOverlay();

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: 'أذكار تقوى',
      overlayContent: 'ذكر اليوم',
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.topCenter,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
    );

    // نرسل البيانات بعد برهة لضمان عمل الـ Listener في الـ Isolate الآخر
    Future.delayed(const Duration(milliseconds: 500), () {
      FlutterOverlayWindow.shareData({'type': 'adhkar'});
    });
  }

  /// يُغلق الـ Overlay.
  static Future<void> dismiss() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
