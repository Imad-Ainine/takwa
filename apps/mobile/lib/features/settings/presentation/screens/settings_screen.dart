import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/providers/theme_provider.dart';
import 'package:takwa/core/providers/locale_provider.dart';
import 'package:takwa/core/providers/app_info_provider.dart';
import 'package:takwa/l10n/app_localizations.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/app/animated_drawer.dart';
import 'package:takwa/core/widgets/takwa_error_state.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/notifications/overlays/adhan_overlay_screen.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/notifications/overlay_settings_tile.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';
import 'package:takwa/features/settings/presentation/widgets/settings_widgets.dart';
import 'dart:async';
import 'adhan_notifications_settings_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  // See HomeScreen's _HomeScreenState for why: one of six MainShell tabs.
  @override
  bool get wantKeepAlive => true;

  Future<void> _updatePref(
    String key,
    dynamic value, {
    NotificationCategory category = NotificationCategory.all,
  }) async {
    await ref
        .read(userPreferencesProvider.notifier)
        .updatePref(key, value, category: category);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final prefsAsync = ref.watch(userPreferencesProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final syncError = ref.watch(lastSyncErrorProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider).value ?? 0;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29).
      appBar: AppBarWidget(
        leading: const DrawerMenuButton(),
        title: l10n.settingsScreenTitle,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SyncStatusIndicator(
                isSyncing: isSyncing,
                syncError: syncError,
                pendingCount: pendingSyncCount,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Pattern
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.sm),
                    prefsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxxl),
                          child: TakwaLoadingIndicator(size: 32),
                        ),
                      ),
                      error: (err, st) => TakwaErrorState(
                        onRetry: () => ref.invalidate(userPreferencesProvider),
                      ),
                      data: (prefs) => Column(
                        children: [
                          // ── التذكيرات ──
                          SectionHeader(
                            title: l10n.settingsAdhanSectionTitle,
                            icon: '🔔',
                          ),
                          SettingsCard(
                            children: [
                              ActionSetting(
                                icon: '🕌',
                                label: l10n.settingsAdhanNotificationsLabel,
                                sublabel:
                                    l10n.settingsAdhanNotificationsSublabel,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdhanNotificationSettingsScreen(),
                                  ),
                                ),
                              ),
                              const SettingsDivider(),
                              ToggleSetting(
                                icon: '🌙',
                                label: l10n.settingsWakeBeforeFajrLabel,
                                sublabel: l10n.settingsWakeBeforeFajrSublabel,
                                value: prefs.wakeUpBeforeFajr,
                                onChanged: (v) => _updatePref(
                                  'wake_up_before_fajr',
                                  v,
                                  category: NotificationCategory.prayer,
                                ),
                              ),
                              if (prefs.wakeUpBeforeFajr) ...[
                                const SettingsDivider(),
                                TimeSetting(
                                  icon: '⏰',
                                  label: l10n.settingsWakeTimeLabel,
                                  time: prefs.wakeUpTime,
                                  onChanged: (t) async {
                                    final str =
                                        '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';
                                    await _updatePref(
                                      'wake_up_time',
                                      str,
                                      category: NotificationCategory.prayer,
                                    );
                                  },
                                ),
                              ],
                              const SettingsDivider(),
                              ToggleSetting(
                                icon: '☀️',
                                label: l10n.settingsMorningAdhkarLabel,
                                sublabel: l10n.settingsMorningAdhkarSublabel,
                                value: prefs.morningAdhkarReminder,
                                onChanged: (v) =>
                                    _updatePref('morning_adhkar_reminder', v),
                              ),
                              const SettingsDivider(),
                              ToggleSetting(
                                icon: '🌆',
                                label: l10n.settingsEveningAdhkarLabel,
                                sublabel: l10n.settingsEveningAdhkarSublabel,
                                value: prefs.eveningAdhkarReminder,
                                onChanged: (v) =>
                                    _updatePref('evening_adhkar_reminder', v),
                              ),
                              const SettingsDivider(),
                              ToggleSetting(
                                icon: '📝',
                                label: l10n.settingsMuhasabaLabel,
                                sublabel: l10n.settingsMuhasabaSublabel,
                                value: prefs.muhasabaReminder,
                                onChanged: (v) => _updatePref(
                                  'muhasaba_reminder',
                                  v,
                                  category: NotificationCategory.reminders,
                                ),
                              ),
                              const SettingsDivider(),
                              ToggleSetting(
                                icon: '🤲',
                                label: l10n.settingsDailyDuasLabel,
                                sublabel: l10n.settingsDailyDuasSublabel,
                                value: prefs.dailyDuasOn,
                                onChanged: (v) =>
                                    _updatePref('daily_duas_on', v),
                              ),
                              const SettingsDivider(),
                              ToggleSetting(
                                icon: '🕌',
                                label: l10n.settingsFridaySunnahLabel,
                                sublabel: l10n.settingsFridaySunnahSublabel,
                                value: prefs.specialRemindersOn,
                                onChanged: (v) =>
                                    _updatePref('special_reminders_on', v),
                              ),
                              const SettingsDivider(),
                              ToggleSetting(
                                icon: '🥘',
                                label: l10n.settingsFastingRemindersLabel,
                                sublabel: l10n.settingsFastingRemindersSublabel,
                                value: prefs.fastingRemindersOn,
                                onChanged: (v) =>
                                    _updatePref('fasting_reminders_on', v),
                              ),
                              if (prefs.muhasabaReminder) ...[
                                const SettingsDivider(),
                                TimeSetting(
                                  icon: '⏰',
                                  label: l10n.settingsMuhasabaTimeLabel,
                                  time: prefs.muhasabaTime,
                                  onChanged: (t) async {
                                    final str =
                                        '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';
                                    await _updatePref(
                                      'evening_reminder_time',
                                      str,
                                      category: NotificationCategory.reminders,
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                          const OverlayNotificationSettings(),

                          // ── المظهر ──
                          SectionHeader(
                            title: l10n.settingsAppearanceSectionTitle,
                            icon: '🎨',
                          ),
                          SettingsCard(
                            children: [
                              SelectSetting(
                                icon: '🌓',
                                label: l10n.settingsThemeModeLabel,
                                value: ref.watch(themeModeProvider).name,
                                options: {
                                  'system': l10n.themeModeSystem,
                                  'light': l10n.themeModeLight,
                                  'dark': l10n.themeModeDark,
                                },
                                onChanged: (v) {
                                  final mode = ThemeMode.values.firstWhere(
                                    (e) => e.name == v,
                                  );
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .setTheme(mode);
                                },
                              ),
                              const SettingsDivider(),
                              SelectSetting(
                                icon: '🌐',
                                label: l10n.settingsLanguageLabel,
                                value: ref.watch(localeProvider).languageCode,
                                options: {
                                  'ar': l10n.languageArabic,
                                  'en': l10n.languageEnglish,
                                },
                                onChanged: (v) {
                                  ref
                                      .read(localeProvider.notifier)
                                      .setLocale(Locale(v));
                                },
                              ),
                              if (kDebugMode) ...[
                                const SettingsDivider(),
                                ActionSetting(
                                  icon: '🎨',
                                  label: l10n.settingsDesignSystemLabel,
                                  sublabel: l10n.settingsDesignSystemSublabel,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    Routes.designSystem,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // ── وضع رمضان ──
                          SectionHeader(
                            title: l10n.settingsRamadanSectionTitle,
                            icon: '🌙',
                          ),
                          SettingsCard(
                            children: [
                              ToggleSetting(
                                icon: '🌙',
                                label: l10n.settingsRamadanSectionTitle,
                                sublabel: l10n.settingsRamadanModeSublabel,
                                value: prefs.ramadanMode,
                                onChanged: (v) =>
                                    _updatePref('ramadan_mode', v),
                                accentColor: context.colors.gold,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],
                      ),
                    ),

                    // ── معلومات ──
                    SectionHeader(
                      title: l10n.settingsAppSectionTitle,
                      icon: 'ℹ️',
                    ),
                    SettingsCard(
                      children: [
                        ActionSetting(
                          icon: '🔔',
                          label: l10n.settingsTestNotifLabel,
                          sublabel: l10n.settingsTestNotifSublabel,
                          onTap: _showTestMenu,
                        ),
                        const SettingsDivider(),
                        ActionSetting(
                          icon: '💎',
                          label: l10n.settingsSubscriptionLabel,
                          sublabel: l10n.settingsSubscriptionSublabel,
                          onTap: () =>
                              Navigator.pushNamed(context, Routes.subscription),
                        ),
                        const SettingsDivider(),
                        ActionSetting(
                          icon: '👨‍💻',
                          label: l10n.settingsAboutDevLabel,
                          sublabel: l10n.settingsAboutDevSublabel,
                          onTap: () =>
                              Navigator.pushNamed(context, '/about-me'),
                        ),
                        const SettingsDivider(),
                        ActionSetting(
                          icon: '📜',
                          label: l10n.settingsTermsLabel,
                          sublabel: l10n.settingsTermsSublabel,
                          onTap: () => Navigator.pushNamed(context, '/terms'),
                        ),
                        if (ref.watch(authStatusProvider) ==
                            AuthStatus.authenticated)
                          ActionSetting(
                            icon: '🚪',
                            label: l10n.settingsLogoutLabel,
                            sublabel: l10n.settingsLogoutSublabel,
                            onTap: _handleLogout,
                            isDestructive: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // App version
                    Center(
                      child: Column(
                        children: [
                          Text(
                            l10n.settingsBismillah,
                            style: context.typography.quranicVerse.copyWith(
                              fontSize: 14,
                              color: context.colors.gold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${l10n.appName} — v${ref.watch(appVersionProvider)}',
                            style: context.typography.caption.copyWith(
                              fontSize: 11,
                              color: context.colors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTestMenu() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.settingsTestNotifSheetTitle,
              style: context.typography.headingMedium.copyWith(
                fontSize: 18,
                color: context.colors.gold,
              ),
            ),
            const SizedBox(height: 14),
            ActionSetting(
              icon: '🔔',
              label: l10n.settingsTestNotifPlainLabel,
              sublabel: l10n.settingsTestNotifPlainSublabel,
              onTap: () {
                Navigator.pop(context);
                NotificationsService.showAchievementNotif(
                  title: l10n.settingsTestNotifTitle,
                  body: l10n.settingsTestNotifBody,
                  emoji: '✅',
                  points: 0,
                  l10n: l10n,
                );
              },
            ),
            const SettingsDivider(),
            ActionSetting(
              icon: '🕌',
              label: l10n.settingsTestAdhanLabel,
              sublabel: l10n.settingsTestAdhanSublabel,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdhanOverlayScreen(
                      prayerName: l10n.prayerAsr,
                      autoPlay: true,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetSettings() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: context.colors.border),
        ),
        title: Text(
          l10n.settingsResetTitle,
          style: context.typography.headingMedium.copyWith(
            fontSize: 18,
            color: context.colors.danger,
          ),
        ),
        content: Text(
          l10n.settingsResetConfirm,
          style: context.typography.bodyMedium.copyWith(
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.commonCancel,
              style: context.typography.labelMedium.copyWith(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.commonDelete,
              style: context.typography.labelMedium.copyWith(
                fontSize: 13,
                color: context.colors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) await NotificationsService.cancelAll();
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: context.colors.border),
        ),
        title: Text(
          l10n.settingsLogoutLabel,
          style: context.typography.headingMedium.copyWith(
            fontSize: 18,
            color: context.colors.danger,
          ),
        ),
        content: Text(
          l10n.settingsLogoutConfirm,
          style: context.typography.bodyMedium.copyWith(
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.commonCancel,
              style: context.typography.labelMedium.copyWith(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.settingsLogoutConfirmButton,
              style: context.typography.labelMedium.copyWith(
                fontSize: 13,
                color: context.colors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Reset guest mode state
      ref.read(guestModeProvider.notifier).state = false;

      // 2. Sign out from Supabase (Google/Email)
      await ref.read(supabaseServiceProvider).signOut();

      // 3. Navigate to splash/login
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }
}

// ── End of SettingsScreen ──
