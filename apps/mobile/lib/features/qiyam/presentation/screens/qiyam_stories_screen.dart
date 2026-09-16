import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

class QiyamStoriesScreen extends StatelessWidget {
  const QiyamStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stories = _stories(l10n);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppTopBar(context),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    itemCount: stories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, index) =>
                        _buildStoryCard(context, stories[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTopBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 0,
      ),
      child: Row(
        children: [
          const CustomLeadingButton(),
          const SizedBox(width: AppSpacing.md),
          Text(
            l10n.qiyamStoriesScreenTitle,
            style: context.typography.displayMedium.copyWith(
              fontSize: 22,
              color: context.colors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, _Story story) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(story.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          story.title,
                          style: context.typography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    story.content,
                    style: context.typography.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  if (story.reference.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '— ${story.reference}',
                        style: context.typography.caption.copyWith(
                          color: context.colors.textDim,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Story {
  final String title, content, reference, icon;
  const _Story({
    required this.title,
    required this.content,
    required this.icon,
    this.reference = '',
  });
}

List<_Story> _stories(AppLocalizations l10n) => [
  _Story(
    title: l10n.qiyamStoryTitle1,
    icon: '✨',
    content:
        'قال جبريل عليه السلام للنبي ﷺ: "يا محمد، عش ما شئت فإنك ميت، وأحبب من شئت فإنك مفارقه، واعمل ما شئت فإنك مجزي به، واعلم أن شرف المؤمن قيامه بالليل، وعزه استغناؤه عن الناس".',
    reference: 'رواه الحاكم',
  ),
  _Story(
    title: l10n.qiyamStoryTitle2,
    icon: '🌟',
    content:
        'كان أويس القرني رضي الله عنه إذا أمسى يقول: هذه ليلة الركوع، فيركع حتى يصبح، وكان يقول في ليلة أخرى: هذه ليلة السجود، فيسجد حتى يصبح. قيل له: يا أويس، كيف تطيق هذا؟ قال: إنما هي ليلة واحدة، والجنة تستحق أكثر من ذلك.',
    reference: 'صفة الصفوة',
  ),
  _Story(
    title: l10n.qiyamStoryTitle3,
    icon: '🏹',
    content:
        'كان الإمام الشافعي يقول: "سهام الليل لا تخطئ، ولكن لها أمد وللأمد انقضاء". ويقصد بها دعاء المستيقظ في جوف الليل الموقن بالإجابة.',
    reference: 'ديوان الشافعي',
  ),
  _Story(
    title: l10n.qiyamStoryTitle4,
    icon: '🌙',
    content:
        'سُئل الحسن البصري: ما بال المتهجدين من أحسن الناس وجوهاً؟ فقال: "لأنهم خلوا بالرحمن فألبسهم نوراً من نوره".',
  ),
];
