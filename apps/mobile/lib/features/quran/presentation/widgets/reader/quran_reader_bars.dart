import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/l10n/app_localizations.dart';
import '../../../data/quran_models.dart';
import '../../../utils/quran_helpers.dart';
import 'quran_reader_colors.dart';

class QuranReaderTopBar extends StatelessWidget {
  final int surahNum;
  final int currentPage;
  final bool isDark;
  final ReaderTheme currentTheme;
  final bool isBookmarked;
  final bool isAudioPlaying;
  final VoidCallback onBack;
  final VoidCallback onThemeToggle;
  final VoidCallback onFontSize;
  final VoidCallback onAudio;
  final VoidCallback onBookmark;
  final VoidCallback onGuide;
  final VoidCallback onSettings;
  final VoidCallback onSurahTap;

  const QuranReaderTopBar({
    super.key,
    required this.surahNum,
    required this.currentPage,
    required this.isDark,
    required this.currentTheme,
    required this.isBookmarked,
    required this.isAudioPlaying,
    required this.onBack,
    required this.onThemeToggle,
    required this.onFontSize,
    required this.onAudio,
    required this.onBookmark,
    required this.onGuide,
    required this.onSettings,
    required this.onSurahTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overlay = isDark
        ? const Color(0xD00A2818)
        : Colors.white.withValues(alpha: 0.92);
    final fg = isDark ? Colors.white70 : Colors.black54;
    final divider = isDark ? Colors.white12 : Colors.black12;

    final themeIcon = switch (currentTheme) {
      ReaderTheme.night => Icons.nightlight_round,
      ReaderTheme.white => Icons.wb_sunny_rounded,
      ReaderTheme.sepia => Icons.menu_book_rounded,
    };
    final themeColor = switch (currentTheme) {
      ReaderTheme.night => kReaderGold,
      ReaderTheme.white => const Color(0xFFD97706),
      ReaderTheme.sepia => const Color(0xFF92400E),
    };

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [overlay, Colors.transparent],
              )
            : null,
        color: isDark ? null : overlay,
        border: Border(bottom: BorderSide(color: divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
          child: Row(
            children: [
              // Theme mode toggle button (dynamic icon)
              _TapIcon(
                icon: themeIcon,
                color: themeColor,
                tooltip: 'تبديل المظهر',
                onTap: onThemeToggle,
              ),
              // Font size / zoom button
              _TapIcon(
                icon: Icons.format_size_rounded,
                color: fg,
                tooltip: 'حجم الخط والصفحة',
                onTap: onFontSize,
              ),
              // Audio toggle button
              _TapIcon(
                icon: isAudioPlaying
                    ? Icons.headphones
                    : Icons.headphones_outlined,
                color: isAudioPlaying ? kReaderGold : fg,
                tooltip: 'الاستماع',
                badgeColor: isAudioPlaying ? kReaderGold : null,
                onTap: onAudio,
              ),
              // Bookmark toggle button
              _TapIcon(
                icon: isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: isBookmarked ? kReaderGold : fg,
                tooltip: 'فاصل القراءة',
                onTap: onBookmark,
              ),
              // Help / Guide
              _TapIcon(
                icon: Icons.help_outline_rounded,
                color: fg,
                tooltip: 'دليل القراءة',
                onTap: onGuide,
              ),
              // Settings
              _TapIcon(
                icon: Icons.tune_rounded,
                color: fg,
                tooltip: 'الإعدادات',
                onTap: onSettings,
              ),
              const Spacer(),
              // Clickable Surah name pill
              GestureDetector(
                onTap: onSurahTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? kReaderGold.withValues(alpha: 0.35)
                          : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: kReaderGold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        l10n.quranReaderSurahLabel(
                          localizedSurahName(context, surahNum),
                        ),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Right: back button
              const CustomLeadingButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? badgeColor;

  const _TapIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    // TakwaTappable is opaque by default already, matching the explicit
    // HitTestBehavior.opaque this GestureDetector used to set.
    Widget child = TakwaTappable(
      onTap: onTap,
      // A toolbar icon button, sized by its own padding rather than a
      // fixed box — see quran_widgets.dart's icon buttons for why
      // minTapSize is null here.
      minTapSize: null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Icon(icon, color: color, size: 22),
            if (badgeColor != null)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                ),
              ),
          ],
        ),
      ),
    );
    if (tooltip != null) {
      child = Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

class QuranReaderBottomBar extends StatelessWidget {
  final int juz, currentPage, totalPages, surahNum, pagesRead;
  final bool isDark;
  final QuranAudioState audio;
  final VoidCallback onTogglePlay;
  final VoidCallback onStop;
  final VoidCallback onSpeedTap;
  final VoidCallback onPageNav;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onJuzNav;
  final VoidCallback onKhatmaStats;
  final VoidCallback onReciter;
  final VoidCallback onDownload;
  final VoidCallback onFullscreen;

  const QuranReaderBottomBar({
    super.key,
    required this.juz,
    required this.currentPage,
    required this.totalPages,
    required this.surahNum,
    required this.pagesRead,
    required this.isDark,
    required this.audio,
    required this.onTogglePlay,
    required this.onStop,
    required this.onSpeedTap,
    required this.onPageNav,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onJuzNav,
    required this.onKhatmaStats,
    required this.onReciter,
    required this.onDownload,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark
        ? const Color(0xF00A2818)
        : Colors.white.withValues(alpha: 0.95);
    final textDim = isDark ? Colors.white54 : Colors.black45;
    final border = isDark ? Colors.white10 : Colors.black12;

    const khatmaPages = 12;
    final readCount = pagesRead.clamp(0, khatmaPages);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [bg, Colors.transparent],
              )
            : null,
        color: isDark ? null : bg,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Progress row with navigation ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Juz chip (tap opens Juz jump sheet)
                  GestureDetector(
                    onTap: onJuzNav,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _infoChip(
                            l10n.quranReaderJuzChip(
                              localizedNumeral(context, juz),
                            ),
                            isDark ? kReaderGoldLight : const Color(0xFF1A5234),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: textDim,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center: Prev/Next step buttons + Page of Total
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // In RTL Mushaf: Next page is to the left (chevron_left)
                      _navArrow(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'الصفحة التالية',
                        color: currentPage < totalPages
                            ? textDim
                            : Colors.transparent,
                        onTap: currentPage < totalPages ? onNextPage : null,
                      ),
                      GestureDetector(
                        onTap: onPageNav,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                          child: _infoChip(
                            l10n.quranReaderPageOfTotalChip(
                              localizedNumeral(context, currentPage),
                              localizedNumeral(context, totalPages),
                            ),
                            isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      // In RTL Mushaf: Previous page is to the right (chevron_right)
                      _navArrow(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'الصفحة السابقة',
                        color: currentPage > 1 ? textDim : Colors.transparent,
                        onTap: currentPage > 1 ? onPrevPage : null,
                      ),
                    ],
                  ),

                  // Khatma read count chip (tap opens Khatma stats)
                  GestureDetector(
                    onTap: onKhatmaStats,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _infoChip(
                            l10n.quranReaderReadCountChip(
                              localizedNumeral(context, readCount),
                              localizedNumeral(context, khatmaPages),
                            ),
                            textDim,
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 13,
                            color: textDim,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 6,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: readCount / khatmaPages,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    kReaderGreenHdr,
                  ),
                  minHeight: 3,
                ),
              ),
            ),

            // ── Audio controls row ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    // Left icons: Reciter selection, Download, Fullscreen
                    _audioIcon(
                      Icons.person_outline_rounded,
                      textDim,
                      onReciter,
                      tooltip: 'اختيار القارئ',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _audioIcon(
                      Icons.download_outlined,
                      textDim,
                      onDownload,
                      tooltip: 'تحميل التلاوة',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _audioIcon(
                      Icons.fit_screen_outlined,
                      textDim,
                      onFullscreen,
                      tooltip: 'وضع ملء الشاشة',
                    ),
                    const Spacer(),

                    // Play/pause button
                    TakwaTappable(
                      onTap: onTogglePlay,
                      // Sits in a fixed-height audio toolbar row — see
                      // quran_widgets.dart's icon buttons for why
                      // minTapSize is null here.
                      minTapSize: null,
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: audio.isLoading
                              ? Colors.white24
                              : kReaderGreenHdr,
                          boxShadow: [
                            BoxShadow(
                              color: kReaderGreenHdr.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: audio.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: TakwaLoadingIndicator(size: 24),
                              )
                            : Icon(
                                audio.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Surah & Ayah info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          localizedSurahName(context, surahNum),
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          '${localizedSurahName(context, audio.surah)}: ${localizedNumeral(context, audio.ayah)}',
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 11,
                            color: textDim,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Speed control
                    GestureDetector(
                      onTap: onSpeedTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: textDim),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '${audio.speed}x',
                          style: TextStyle(
                            color: textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Stop
                    TakwaTappable(
                      onTap: onStop,
                      minTapSize: null,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        child: Icon(
                          Icons.stop_rounded,
                          color: textDim,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navArrow({
    required IconData icon,
    required String tooltip,
    required Color color,
    VoidCallback? onTap,
  }) => Tooltip(
    message: tooltip,
    // No semanticLabel: the Tooltip above already contributes one.
    child: TakwaTappable(
      onTap: onTap,
      minTapSize: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(icon, size: 22, color: color),
      ),
    ),
  );

  Widget _infoChip(String text, Color color) => Text(
    text,
    style: TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 11, color: color),
  );

  Widget _audioIcon(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    Widget btn = TakwaTappable(
      onTap: onTap,
      minTapSize: null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(icon, color: color, size: 20),
      ),
    );
    if (tooltip != null) {
      // No semanticLabel on the tappable above: this Tooltip supplies one.
      btn = Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }
}
