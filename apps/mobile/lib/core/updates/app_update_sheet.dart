import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/updates/apk_installer.dart';
import 'package:takwa/core/updates/release_info.dart';
import 'package:takwa/core/updates/update_check_service.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Opens the in-app updater. Safe to call from anywhere holding a context —
/// including the notification router, which may fire during a cold start.
Future<void> showAppUpdateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AppUpdateSheet(),
  );
}

enum _Phase { loading, ready, downloading, handedOff, failed, unavailable }

class _AppUpdateSheet extends ConsumerStatefulWidget {
  const _AppUpdateSheet();

  @override
  ConsumerState<_AppUpdateSheet> createState() => _AppUpdateSheetState();
}

class _AppUpdateSheetState extends ConsumerState<_AppUpdateSheet> {
  _Phase _phase = _Phase.loading;
  ReleaseInfo? _release;
  ApkInstallFailure? _failure;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    ReleaseInfo? release;
    try {
      release = await ref.read(updateCheckServiceProvider).fetchLatestRelease();
    } catch (_) {
      release = null;
    }
    if (!mounted) return;
    setState(() {
      _release = release;
      _phase = release == null ? _Phase.unavailable : _Phase.ready;
    });
  }

  Future<void> _install(ReleaseInfo release) async {
    setState(() {
      _phase = _Phase.downloading;
      _progress = 0;
    });

    try {
      final path = await ApkInstaller.download(
        url: release.apkUri,
        filename: release.filename,
        expectedSha256: release.sha256,
        expectedSizeBytes: release.sizeBytes,
        onProgress: (fraction) {
          if (mounted) setState(() => _progress = fraction);
        },
      );
      await ApkInstaller.launchInstaller(path);
      if (!mounted) return;
      setState(() => _phase = _Phase.handedOff);
    } on ApkInstallException catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = e.failure;
        _phase = _Phase.failed;
      });
    }
  }

  Future<void> _openWebsite() async {
    await launchUrl(
      Uri.parse(kReleaseDownloadUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  String _sizeLabel(int bytes) =>
      bytes <= 0 ? '—' : '${(bytes / 1048576).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = AdaptiveStyle(
      context,
      ref.watch(ramadanModeProvider).value ?? false,
    );
    final release = _release;

    return Container(
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: style.border)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: style.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l10n.updateSheetTitle,
            style: style.headingMedium(color: style.gold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          _buildBody(l10n, style, release),
          const SizedBox(height: 20),
          _buildActions(l10n, style, release),
        ],
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    AdaptiveStyle style,
    ReleaseInfo? release,
  ) {
    switch (_phase) {
      case _Phase.loading:
        return Center(
          child: SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(
              color: style.gold,
              strokeWidth: 2.5,
            ),
          ),
        );
      case _Phase.unavailable:
        return Text(
          l10n.updateSheetUnavailable,
          style: style.bodyMedium(color: style.textSec),
          textAlign: TextAlign.center,
        );
      case _Phase.failed:
        return Text(
          _failure == ApkInstallFailure.checksum
              ? l10n.updateSheetFailedChecksum
              : l10n.updateSheetFailed,
          style: style.bodyMedium(color: style.danger),
          textAlign: TextAlign.center,
        );
      case _Phase.handedOff:
        return Text(
          l10n.updateSheetInstallerHint,
          style: style.bodyMedium(color: style.success),
          textAlign: TextAlign.center,
        );
      case _Phase.ready:
      case _Phase.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.updateSheetBody(
                release?.version ?? '',
                _sizeLabel(release?.sizeBytes ?? 0),
              ),
              style: style.bodyMedium(color: style.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.updateSheetCellularNote,
              style: style.bodySmall(color: style.textDim),
              textAlign: TextAlign.center,
            ),
            if (_phase == _Phase.downloading) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: style.card,
                  valueColor: AlwaysStoppedAnimation(style.gold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.updateSheetDownloading((_progress * 100).round()),
                style: style.bodySmall(color: style.textSec),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
    }
  }

  Widget _buildActions(
    AppLocalizations l10n,
    AdaptiveStyle style,
    ReleaseInfo? release,
  ) {
    final busy = _phase == _Phase.loading || _phase == _Phase.downloading;

    Widget primary;
    switch (_phase) {
      case _Phase.handedOff:
      case _Phase.unavailable:
        primary = _SheetButton(
          label: l10n.updateSheetClose,
          style: style,
          onPressed: () => Navigator.pop(context),
        );
      case _Phase.failed:
        primary = _SheetButton(
          label: l10n.updateSheetRetry,
          style: style,
          onPressed: release == null ? null : () => _install(release),
        );
      case _Phase.ready:
      case _Phase.loading:
      case _Phase.downloading:
        primary = _SheetButton(
          label: _phase == _Phase.downloading
              ? l10n.updateSheetDownloadingLabel
              : l10n.updateSheetInstall,
          style: style,
          onPressed: (busy || release == null) ? null : () => _install(release),
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primary,
        // The website stays a visible option rather than a silent fallback:
        // it is the only path left when the in-app download keeps failing,
        // and it is what a user on a metered connection may prefer to do on
        // a computer instead.
        if (_phase != _Phase.handedOff)
          TextButton(
            onPressed: _openWebsite,
            child: Text(
              l10n.updateSheetOpenSite,
              style: style.bodySmall(color: style.textDim),
            ),
          ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.style,
    this.onPressed,
  });

  final String label;
  final AdaptiveStyle style;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: style.gold,
        foregroundColor: style.deep,
        disabledBackgroundColor: style.card,
        disabledForegroundColor: style.textDim,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: style.labelLarge(
          weight: FontWeight.bold,
          color: enabled ? style.deep : style.textDim,
        ),
      ),
    );
  }
}
