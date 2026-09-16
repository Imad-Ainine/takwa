import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_pattern_background.dart';
import '../../../../core/widgets/custom_leading_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

class QiyamVirtuesScreen extends StatelessWidget {
  const QiyamVirtuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off Row(CustomLeadingButton + title)
      // (audit item 29) — consistent with the rest of the app's app bars.
      appBar: AppBarWidget(
        title: l10n.qiyamVirtuesScreenTitle,
        leading: const CustomLeadingButton(),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                      _buildVirtueSection(
                        context,
                        title: l10n.qiyamVirtuesFromQuran,
                        icon: Icons.menu_book,
                        color: context.colors.teal,
                        items: [
                          '﴿تَتَجَافَى جُنُوبُهُمْ عَنِ الْمَضَاجِعِ يَدْعُونَ رَبَّهُمْ خَوْفًا وَطَمَعًا﴾ [السجدة: 16]',
                          '﴿وَمِنَ اللَّيْلِ فَتَهَجَّدْ بِهِ نَافِلَةً لَّكَ عَسَىٰ أَن يَبْعَثَكَ رَبُّكَ مَقَامًا مَّحْمُودًا﴾ [الإسراء: 79]',
                          '﴿أَمَّنْ هُوَ قَانِتٌ آنَاءَ اللَّيْلِ سَاجِدًا وَقَائِمًا يَحْذَرُ الْآخِرَةَ وَيَرْجُو رَحْمَةَ رَبِّهِ﴾ [الزمر: 9]',
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildVirtueSection(
                        context,
                        title: l10n.qiyamVirtuesFromSunnah,
                        icon: Icons.auto_awesome,
                        color: context.colors.gold,
                        items: [
                          '"أفضل الصلاة بعد الفريضة صلاة الليل"',
                          '"علَيْكُم بَقِيامِ اللَّيْلِ، فَإِنَّهُ دَأْبُ الصَّالِحِينَ قَبْلَكُمْ، وَهُوَ قُرْبَةٌ إِلَى رَبِّكُمْ، وَمَكْفَرَةٌ لِلسَّيِّئَاتِ، وَمَنْهَاةٌ لِلإِثْمِ"',
                          '"إنَّ في اللَّيْلِ لَسَاعَةً، لا يُوَافِقُهَا رَجُلٌ مُسْلِمٌ، يَسْأَلُ اللَّهَ خَيْرًا مِن أَمْرِ الدُّنْيَا وَالآخِرَةِ، إلَّا أَعْطَاهُ إيَّاهُ، وَذلكَ كُلَّ لَيْلَةٍ"',
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildVirtueSection(
                        context,
                        title: l10n.qiyamVirtuesFromSalaf,
                        icon: Icons.format_quote,
                        color: context.colors.teal,
                        items: [
                          'قال الحسن البصري: "ما نعلم عملاً أشد من مكابدة الليل، ونفقة المال، فقيل له: ما بال المتجحدين من أحسن الناس وجوهاً؟ قال: لأنهم خلوا بالرحمن فألبسهم نوراً من نوره"',
                          'قال الفضيل بن عياض: "إذا لم تقدر على قيام الليل، وصيام النهار، فاعلم أنك محروم، كبلتك خطيئتك"',
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtueSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              title,
              style: context.typography.displayMedium.copyWith(
                fontSize: 20,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              item,
              style: context.typography.bodyLarge.copyWith(
                fontSize: 16,
                color: context.colors.textPrimary,
                height: 1.6,
                fontStyle: icon == Icons.format_quote
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
