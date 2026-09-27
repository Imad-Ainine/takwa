import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';
import 'package:takwa/l10n/app_localizations.dart';
import '../../../data/quran_models.dart';
import '../../../utils/quran_helpers.dart';
import 'quran_reader_colors.dart';

class QuranReaderAyahOptionsSheet extends StatelessWidget {
  final int surahNum, ayahNum;
  final VoidCallback onSave, onShare, onTafsir, onTranslation, onPlay;

  const QuranReaderAyahOptionsSheet({
    super.key,
    required this.surahNum,
    required this.ayahNum,
    required this.onSave,
    required this.onShare,
    required this.onTafsir,
    required this.onTranslation,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surahName = localizedSurahName(context, surahNum);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: kReaderBgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.quranReaderAyahRefLabel(
              localizedNumeral(context, ayahNum),
              surahName,
            ),
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 17,
              color: kReaderGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),
          _OptionRow(
            emoji: '⭐',
            label: l10n.quranReaderSaveAyahOption,
            onTap: onSave,
          ),
          _OptionRow(
            emoji: '📤',
            label: l10n.quranReaderShareAyahOption,
            onTap: onShare,
          ),
          _OptionRow(
            emoji: '📖',
            label: l10n.quranReaderTafsirOption,
            onTap: onTafsir,
          ),
          _OptionRow(
            emoji: '🌐',
            label: l10n.quranReaderTranslationOption,
            onTap: onTranslation,
          ),
          _OptionRow(
            emoji: '🔊',
            label: l10n.quranReaderListenAyahOption,
            onTap: onPlay,
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _OptionRow({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: Colors.white24,
              size: 18,
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            IslamicGlyph(emoji, size: 18),
          ],
        ),
      ),
    );
  }
}

class QuranReaderSettingsSheet extends StatelessWidget {
  final ReaderTheme theme;
  final double currentScale;
  final ValueChanged<ReaderTheme> onThemeChanged;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onResetScale;
  final VoidCallback onReciterTap;

  const QuranReaderSettingsSheet({
    super.key,
    required this.theme,
    required this.currentScale,
    required this.onThemeChanged,
    required this.onScaleChanged,
    required this.onResetScale,
    required this.onReciterTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: kReaderBgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.quranReaderSettingsTitle,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              color: kReaderGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Theme Selection ───────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.quranReaderBackgroundStyleLabel,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: ReaderTheme.values.map((t) {
              final labels = {
                'night': l10n.quranReaderThemeNight,
                'sepia': l10n.quranReaderThemeSepia,
                'white': l10n.quranReaderThemeWhite,
              };
              final selected = theme == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onThemeChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? kReaderGold : Colors.white10,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: selected ? kReaderGoldLight : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labels[t.name] ?? t.name,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          color: selected
                              ? kReaderOnGold
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Font Size & Zoom ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onResetScale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'إعادة ضبط',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: kReaderGoldLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Text(
                'حجم الخط والصفحة (${(currentScale * 100).round()}%)',
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _scaleBtn(
                label: 'A-',
                tooltip: 'تصغير',
                onTap: () => onScaleChanged(currentScale - 0.08),
              ),
              Expanded(
                child: Slider(
                  value: currentScale.clamp(0.85, 1.6),
                  min: 0.85,
                  max: 1.6,
                  activeColor: kReaderGold,
                  inactiveColor: Colors.white24,
                  onChanged: onScaleChanged,
                ),
              ),
              _scaleBtn(
                label: 'A+',
                tooltip: 'تكبير',
                onTap: () => onScaleChanged(currentScale + 0.08),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Reciter selection button ──────────────────
          GestureDetector(
            onTap: onReciterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chevron_left, color: Colors.white38),
                  Spacer(),
                  Text(
                    'تغيير القارئ الصوتي',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.record_voice_over_outlined,
                    color: kReaderGold,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scaleBtn({
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
