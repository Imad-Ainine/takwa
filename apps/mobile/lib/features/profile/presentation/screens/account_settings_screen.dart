import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_leading_button.dart';
import '../../../../core/widgets/custom_pattern_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/takwa_loading_indicator.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import 'package:takwa/l10n/app_localizations.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    // Initialize controller with current user data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileAsync = ref.read(userProfileProvider);
      profileAsync.whenData((profile) {
        if (profile != null) {
          _nameController.text = profile['username'] ?? '';
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isSaving = true);

    try {
      // Was a `Future.delayed` placeholder that never actually wrote
      // anything — the name field always looked "saved" (success snackbar
      // + pop) but the profile row was untouched. This is the same
      // updateProfile() the rest of the app already uses to write to
      // Supabase's `profiles` table; userProfileProvider is a realtime
      // stream on that table, so every screen showing the name picks up
      // the change automatically once this succeeds.
      await ref.read(supabaseServiceProvider).updateProfile({
        'username': _nameController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.accountSettingsSavedSuccess,
              textAlign: TextAlign.center,
            ),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.accountSettingsSaveError,
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29).
      appBar: AppBarWidget(
        leading: const CustomLeadingButton(),
        title: l10n.profileAccountSettingsMenuTitle,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: profileAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(child: TakwaLoadingIndicator()),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      l10n.profileLoadError,
                      style: context.typography.bodyMedium.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  data: (profile) {
                    final email = profile?['email'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.accountSettingsPersonalInfoSection,
                              style: context.typography.labelLarge.copyWith(
                                color: context.colors.textDim,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              decoration: context.decorations.card.copyWith(
                                color: context.colors.card.withValues(alpha: 0.8),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(context, l10n.accountSettingsNameLabel),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextFormField(
                                    controller: _nameController,
                                    style: context.typography.bodyMedium,
                                    decoration: _getInputDecoration(
                                      context,
                                      l10n.accountSettingsNameHint,
                                    ),
                                    validator: (val) =>
                                        (val == null || val.trim().isEmpty)
                                        ? l10n.accountSettingsNameRequired
                                        : null,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  _buildLabel(context, l10n.authEmailHint),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextFormField(
                                    initialValue: email,
                                    enabled: false,
                                    style: context.typography.bodyMedium
                                        .copyWith(
                                          color: context.colors.textDim,
                                        ),
                                    decoration: _getInputDecoration(context, '')
                                        .copyWith(
                                          fillColor: context.colors.card
                                              .withValues(alpha: 0.3),
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    l10n.accountSettingsEmailImmutableNote,
                                    style: context.typography.caption.copyWith(
                                      color: context.colors.textDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            PrimaryButton(
                              onTap: _saveChanges,
                              label: l10n.accountSettingsSaveButton,
                              icon: Icons.save_rounded,
                              isLoading: _isSaving,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            // Update Password Section
                            Text(
                              l10n.accountSettingsSecuritySection,
                              style: context.typography.labelLarge.copyWith(
                                color: context.colors.textDim,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              decoration: context.decorations.card.copyWith(
                                color: context.colors.card.withValues(alpha: 0.8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                clipBehavior: Clip.antiAlias,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.lock_outline_rounded,
                                    color: context.colors.gold,
                                  ),
                                  title: Text(
                                    l10n.accountSettingsChangePasswordTile,
                                    style: context.typography.labelLarge,
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: context.colors.textDim,
                                  ),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/update-password',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: context.typography.labelMedium.copyWith(
        color: context.colors.gold,
      ),
    );
  }

  InputDecoration _getInputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: context.typography.bodyMedium.copyWith(
        color: context.colors.textDim,
      ),
      filled: true,
      fillColor: context.colors.card.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: context.colors.border.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: context.colors.gold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
    );
  }
}
