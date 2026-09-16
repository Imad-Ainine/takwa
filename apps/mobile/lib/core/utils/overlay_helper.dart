import 'package:flutter_overlay_window/flutter_overlay_window.dart' as ow;

class OverlayHelper {
  /// type: 'all' | 'adhkar' | 'dua'
  static Future<void> show({String type = 'all'}) async {
    final hasPermission = await ow.FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) return;

    final isActive = await ow.FlutterOverlayWindow.isActive();
    if (isActive) {
      // الـ overlay مفتوح بالفعل، فقط غيّر المحتوى
      ow.FlutterOverlayWindow.shareData({'type': type});
      return;
    }

    await ow.FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      flag: ow.OverlayFlag.defaultFlag,
      alignment: ow.OverlayAlignment.center,
      visibility: ow.NotificationVisibility.visibilityPublic,
      positionGravity: ow.PositionGravity.none,
      height: ow.WindowSize.matchParent,
      width: ow.WindowSize.matchParent,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    ow.FlutterOverlayWindow.shareData({'type': type});
  }
}
