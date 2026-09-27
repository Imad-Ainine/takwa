import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/l10n/app_localizations.dart';
import '../../../utils/quran_helpers.dart';
import 'quran_reader_colors.dart';

class QuranReaderGuideDialog extends StatelessWidget {
  const QuranReaderGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xxl),
      child: Container(
        decoration: BoxDecoration(
          color: kReaderTealHdr,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const IslamicGlyph('📖', size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.quranReaderGuideTitle,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Guide items
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  _GuideItem(emoji: '👆', text: l10n.quranReaderGuideTapToggle),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '👆👆',
                    text: l10n.quranReaderGuideDoubleTapZoom,
                  ),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '👈',
                    text: l10n.quranReaderGuideSwipeNavigate,
                  ),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '📌',
                    text: l10n.quranReaderGuideLongPress,
                    subItems: [
                      l10n.quranReaderGuideSaveAyah,
                      l10n.quranReaderGuideShareAyah,
                      l10n.quranReaderGuideTafsir,
                      l10n.quranReaderGuideTranslation,
                      l10n.quranReaderGuideListen,
                    ],
                  ),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '🎧',
                    text: l10n.quranReaderGuideAudioButton,
                  ),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '🌙',
                    text: l10n.quranReaderGuideNightModeButton,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Got it button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      l10n.quranReaderGuideGotIt,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: kReaderTealHdr,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final String emoji, text;
  final List<String>? subItems;
  const _GuideItem({required this.emoji, required this.text, this.subItems});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IslamicGlyph(emoji, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              if (subItems != null)
                ...subItems!.map(
                  (s) => Padding(
                    padding: const EdgeInsetsDirectional.only(top: 3, end: 8),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuranReaderPageNavigationDialog extends StatefulWidget {
  final int currentPage, totalPages;
  final void Function(int) onNavigate;

  const QuranReaderPageNavigationDialog({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onNavigate,
  });

  @override
  State<QuranReaderPageNavigationDialog> createState() =>
      _PageNavigationDialogState();
}

class _PageNavigationDialogState
    extends State<QuranReaderPageNavigationDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _navigate() {
    final val = int.tryParse(_ctrl.text);
    if (val == null || val < 1 || val > widget.totalPages) {
      setState(
        () => _error = AppLocalizations.of(context)!.quranReaderPageJumpError(
          localizedNumeral(context, widget.totalPages),
        ),
      );
      return;
    }
    widget.onNavigate(val);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: kReaderBgDark,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TakwaTappable(
                  onTap: () => Navigator.pop(context),
                  // Inline with the dialog title via spaceBetween.
                  minTapSize: null,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white38,
                    size: 20,
                  ),
                ),
                Text(
                  l10n.quranReaderGoToPageTitle,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.quranReaderCurrentPageLabel(
                localizedNumeral(context, widget.currentPage),
              ),
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 13,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.quranReaderPageInputLabel(
                l10n.quranReaderPageRangeHint(
                  localizedNumeral(context, widget.totalPages),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 12,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 14),
            // Input
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: l10n.quranReaderPageRangeHint(
                  localizedNumeral(context, widget.totalPages),
                ),
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                errorText: _error,
                errorStyle: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 11,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Center(
                        child: Text(
                          l10n.quranReaderCancelButton,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _navigate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: kReaderTealHdr,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: kReaderTealHdr.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          l10n.quranReaderGoButton,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
