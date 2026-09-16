import 'dart:math';
import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart' as ql;
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import '../../utils/quran_helpers.dart';
import '../../utils/quran_painters.dart';
import 'package:takwa/l10n/app_localizations.dart';

// Styles are managed via AdaptiveStyle for consistent theming.

// ─────────────────────────────────────────────────────────────
// Daily Verse Card  (home hub)
// ─────────────────────────────────────────────────────────────
class DailyVerseCard extends StatelessWidget {
  final Map<String, dynamic> verse;
  final VoidCallback onRefresh;
  final VoidCallback onShare;
  final VoidCallback onNavigate;
  final AdaptiveStyle style;

  const DailyVerseCard({
    super.key,
    required this.verse,
    required this.onRefresh,
    required this.onShare,
    required this.onNavigate,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: style.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: style.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Surah label row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Row(
                children: [
                  _surahChip(verse['surahName'] as String, style),
                  const Spacer(),
                  _iconBtn(Icons.share_rounded, onShare, style),
                  const SizedBox(width: AppSpacing.xs),
                  _iconBtn(Icons.refresh_rounded, onRefresh, style),
                ],
              ),
            ),
            // Ayah text
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 10,
              ),
              child: Text(
                verse['text'] as String,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: style.amiri(19, color: style.text, height: 2.0),
              ),
            ),
            // Bottom row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Row(
                children: [
                  TakwaTappable(
                    onTap: onNavigate,
                    // Inline alongside the Spacer()+badge below (audit
                    // §H3) — forcing the platform's 48dp minimum here would
                    // just eat into that spacer rather than usefully
                    // enlarging the tap target, per TakwaTappable's own
                    // guidance for compact inline controls.
                    minTapSize: null,
                    // Resolved by hand (Icon has no matchTextDirection
                    // param): chevron_right in LTR / chevron_left in RTL
                    // always points "forward" regardless of layout
                    // position — what a drill-in affordance needs whether
                    // it sits leading or trailing in its Row.
                    child: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      color: style.textDim,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  _ayahBadge(context, verse['ayahNumber'] as int, style),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _surahChip(String name, AdaptiveStyle style) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
    decoration: BoxDecoration(
      color: style.gold.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: style.gold.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, color: style.gold, size: 13),
        const SizedBox(width: 5),
        Text(
          name,
          style: style.amiri(14, color: style.gold, weight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap, AdaptiveStyle style) =>
      TakwaTappable(
        onTap: onTap,
        // Sits inline with a sibling icon button in the same row (audit
        // §H3) — see the drill-in chevron above for why minTapSize is null
        // here.
        minTapSize: null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: style.text.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: style.textSec, size: 17),
        ),
      );

  Widget _ayahBadge(BuildContext context, int ayah, AdaptiveStyle style) =>
      Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
    decoration: BoxDecoration(
      color: style.text.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(
            context,
          )!.quranScreenAyahLabel(localizedNumeral(context, ayah)),
          style: style.amiri(13, color: style.textSec),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('»»', style: TextStyle(color: style.textDim, fontSize: 11)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Khatma Action Card  (the two big green buttons)
// ─────────────────────────────────────────────────────────────
class KhatmaActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData actionIcon;
  final VoidCallback onTap;
  final AdaptiveStyle style;
  final VoidCallback? onBack;

  const KhatmaActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.actionIcon,
    required this.onTap,
    required this.style,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // The margin moved from the Container below to this outer Padding: the
    // TakwaTappable's ClipRRect clips to its child's own bounds at
    // AppRadius.xl, which needs to be the *decorated* box, not a box that
    // still has the margin's transparent inset baked in — otherwise the
    // press-tint's rounded corners land on the margin's outer edge instead
    // of the card's actual (inset) edge.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: TakwaTappable(
        onTap: onTap,
        // No semanticLabel: the visible title/subtitle Text below already
        // carries this into the semantics tree — see _PageItem in
        // ai_memorize_screen.dart for the same call.
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
            // Back arrow button — chevron_left in LTR / chevron_right in
            // RTL always points "backward".
            if (onBack != null)
              _circleBtn(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_right
                    : Icons.chevron_left,
                Colors.white.withValues(alpha: 0.2),
                Colors.white,
                onBack!,
              ),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: style.amiri(
                      19,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: style.naskh(
                      12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
              // Action icon button
              _circleBtn(
                actionIcon,
                Colors.white.withValues(alpha: 0.25),
                Colors.white,
                onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Callers resolve the correct chevron direction themselves (Icon has no
  // matchTextDirection param) before passing `icon` in.
  Widget _circleBtn(IconData icon, Color bg, Color fg, VoidCallback f) =>
      TakwaTappable(
        onTap: f,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: 22),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Feature Grid Item  (2×2 grid on hub)
// ─────────────────────────────────────────────────────────────
class FeatureGridItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final VoidCallback onTap;
  final AdaptiveStyle style;
  final bool useAiLabel;

  const FeatureGridItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.onTap,
    required this.style,
    this.useAiLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return TakwaTappable(
      onTap: onTap,
      // No semanticLabel: the visible title/subtitle Text below already
      // carries this into the semantics tree.
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: style.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: useAiLabel
                  ? Center(
                      child: Text(
                        'AI',
                        style: style.naskh(
                          18,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: style.amiri(
                15,
                weight: FontWeight.bold,
                color: style.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: style.naskh(11, color: style.textDim),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Khatma Progress Ring
// ─────────────────────────────────────────────────────────────
class KhatmaProgressRing extends StatelessWidget {
  final double progress; // 0.0 → 1.0
  final int pagesRead;
  final int totalPages;
  final AdaptiveStyle style;
  final Color? color;

  const KhatmaProgressRing({
    super.key,
    required this.progress,
    required this.pagesRead,
    required this.totalPages,
    required this.style,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(160, 160),
            painter: _RingPainter(progress, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizedNumeral(context, pagesRead),
                style: style.amiri(
                  32,
                  weight: FontWeight.bold,
                  color: style.text,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.khatmaRingOfPagesLabel(
                  localizedNumeral(context, totalPages),
                ),
                style: style.naskh(12, color: style.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color? color;
  _RingPainter(this.progress, {this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - 16) / 2;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [color ?? kGoldChip, color?.withValues(alpha: 0.5) ?? kGoldL],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, track);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
// Surah Row (existing, kept)
// ─────────────────────────────────────────────────────────────
class QuranSurahRow extends StatelessWidget {
  final ql.SurahNamesModel s;
  final VoidCallback onTap;
  final AdaptiveStyle style;
  const QuranSurahRow({
    super.key,
    required this.s,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = surahColor(s.number);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: style.border, width: 0.5)),
        ),
        child: Row(
          children: [
            CustomPaint(
              size: const Size(42, 42),
              painter: SurahBadgePainter(s.number, c),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.englishName,
                    style: style.naskh(
                      17,
                      weight: FontWeight.w600,
                      color: style.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.revelationType == 'Meccan' ? l10n.quranReaderMeccan : l10n.quranReaderMedinan} • ${l10n.quranReaderAyahCountBadge(s.ayahsNumber)}',
                    style: style.naskh(12, color: style.textDim),
                  ),
                ],
              ),
            ),
            Text(
              s.name,
              style: style.amiri(22, weight: FontWeight.bold, color: c),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Juz Card (existing, kept)
// ─────────────────────────────────────────────────────────────
class QuranJuzCard extends StatelessWidget {
  final int n;
  final String name;
  final double progress;
  final VoidCallback onTap;
  final AdaptiveStyle style;
  const QuranJuzCard({
    super.key,
    required this.n,
    required this.name,
    required this.progress,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = surahColor(n);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: style.card,
          border: Border.all(color: style.border),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(48, 48),
                  painter: JuzRingPainter(progress, c),
                ),
                Text(
                  localizedNumeral(context, n),
                  style: style.amiri(
                    14,
                    weight: FontWeight.bold,
                    color: style.text,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quranJuzLabel(name),
                    style: style.amiri(
                      18,
                      weight: FontWeight.bold,
                      color: style.text,
                    ),
                  ),
                  Text(
                    l10n.quranJuzPercentComplete(
                      localizedNumeral(context, (progress * 100).toInt()),
                    ),
                    style: style.naskh(12, color: style.textSec),
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: style.textDim,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Ayah Block (existing, kept + enhanced highlight)
// ─────────────────────────────────────────────────────────────
class AyahBlock extends StatelessWidget {
  final ql.AyahModel a;
  final double fontSize;
  final bool isPlaying;
  final VoidCallback onPlay;
  final AdaptiveStyle style;
  const AyahBlock({
    super.key,
    required this.a,
    required this.fontSize,
    required this.isPlaying,
    required this.onPlay,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final c = isPlaying ? style.gold : style.text;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      decoration: BoxDecoration(
        color: isPlaying ? style.gold.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 10,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              a.text,
              textAlign: TextAlign.center,
              style: style.amiri(fontSize, color: c, height: 1.8),
            ),
            const SizedBox(width: AppSpacing.sm),
            TakwaTappable(
              onTap: onPlay,
              // Sits inline in a Wrap next to the ayah text (audit §H3) —
              // see the drill-in chevron above for why minTapSize is null.
              minTapSize: null,
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                size: const Size(28, 28),
                painter: VerseMarkerPaint(
                  a.ayahNumber,
                  isPlaying ? style.gold : style.border,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
