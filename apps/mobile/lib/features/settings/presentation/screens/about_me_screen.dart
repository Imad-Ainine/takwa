import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutMeScreen extends StatelessWidget {
  const AboutMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29).
      appBar: _buildAppBar(context, l),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context, l),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSectionTitle(
                        context,
                        l.aboutSectionDeveloper,
                        l.aboutSectionDeveloper,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildBioCard(context, l),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSectionTitle(
                        context,
                        l.aboutSectionSkills,
                        l.aboutSectionSkills,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSkillsGrid(context),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSectionTitle(
                        context,
                        l.aboutSectionConnect,
                        l.aboutSectionConnect,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSocialLinks(context),
                      const SizedBox(height: 40),
                      _buildFooter(context, l),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AppBarWidget _buildAppBar(BuildContext context, AppLocalizations l) {
    return AppBarWidget(
      leading: const CustomLeadingButton(),
      title: l.aboutScreenTitle,
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: context.decorations.goldCard.copyWith(
        color: context.colors.card.withValues(alpha: 0.85),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.goldDim,
              border: Border.all(color: context.colors.gold, width: 3),
              boxShadow: context.shadows.goldGlow,
            ),
            // ClipOval + Image.asset(errorBuilder: ...) instead of a
            // DecorationImage: a DecorationImage has no way to react to a
            // failed/missing asset, so a bad build (e.g. the asset didn't
            // ship — see assets/images/README.md) used to silently render
            // an empty gold ring. This falls back to a person icon instead.
            child: ClipOval(
              child: Image.asset(
                'assets/images/dev.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_rounded,
                  size: 56,
                  color: context.colors.gold,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          // Arabic Name
          Text(
            l.aboutDevNameArabic,
            style: context.typography.headingLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          // Latin Name
          Text(
            l.aboutDevNameLatin,
            style: context.typography.headingMedium.copyWith(
              fontSize: 18,
              color: context.colors.goldLight,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Badge
          TaqwaBadge(label: l.aboutDevBadge),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String primary,
    String secondary,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          primary,
          style: context.typography.headingMedium.copyWith(
            color: context.colors.teal,
          ),
        ),
        Text(
          secondary,
          style: context.typography.caption.copyWith(
            fontSize: 12,
            color: context.colors.textDim,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBioCard(BuildContext context, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: context.decorations.card.copyWith(
        color: context.colors.card.withValues(alpha: 0.85),
      ),
      child: Text(
        l.aboutBio,
        style: context.typography.bodyMedium.copyWith(height: 1.8),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildSkillsGrid(BuildContext context) {
    const skills = [
      'Flutter',
      'Dart',
      'Node.js',
      'PostgreSQL',
      'Supabase',
      'Firebase',
      'Next.js',
      'React',
      'Git',
      'Clean Architecture',
      'Rest API',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map(
            (skill) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.colors.card2,
                borderRadius: AppRadius.chip,
                border: Border.all(color: context.colors.border),
              ),
              child: Text(
                skill,
                style: context.typography.labelMedium.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSocialLinks(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              context,
              Icons.code_rounded,
              'GitHub',
              url: 'https://github.com/Imad-Ainine',
            ),
            const SizedBox(width: AppSpacing.lg),
            _buildSocialIcon(
              context,
              Icons.business_center_rounded,
              'LinkedIn',
              url: 'https://www.linkedin.com/in/imadeddine-ainine',
            ),
            const SizedBox(width: AppSpacing.lg),
            _buildSocialIcon(
              context,
              Icons.facebook_rounded,
              'Facebook',
              url: 'https://www.facebook.com/imad.ainine1',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              context,
              Icons.mail_outline_rounded,
              'Email',
              url: 'mailto:imad.ainine11@gmail.com',
            ),
            const SizedBox(width: AppSpacing.lg),
            _buildSocialIcon(
              context,
              Icons.phone_android_rounded,
              'Phone',
              url: 'tel:+213773843669',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(
    BuildContext context,
    IconData icon,
    String tooltip, {
    String? url,
  }) {
    return Tooltip(
      message: tooltip,
      child: TakwaTappable(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () async {
          HapticFeedback.lightImpact();
          if (url != null) {
            final uri = Uri.parse(url);
            try {
              final launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched) {
                debugPrint('Could not launch $url');
              }
            } catch (e) {
              debugPrint('Error launching $url: $e');
            }
          }
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.colors.border),
          ),
          child: Icon(icon, color: context.colors.gold, size: 24),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l) {
    return Center(
      child: Column(
        children: [
          Container(height: 1, width: 80, color: context.colors.border),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l.aboutFooterDuaRequest,
            style: context.typography.headingMedium.copyWith(
              color: context.colors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.aboutFooterMadeWithLove,
            style: context.typography.caption.copyWith(
              color: context.colors.textDim,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('❤️', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                l.aboutFooterCopyright,
                style: context.typography.caption.copyWith(
                  fontSize: 11,
                  color: context.colors.textDim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
