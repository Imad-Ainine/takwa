import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/widgets/custom_time_picker.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Map from human-readable icon key to IconData.
/// Used to persist and restore icons from the database.
const Map<String, IconData> kReminderIcons = {
  'favorite_rounded': Icons.favorite_rounded,
  'mosque_rounded': Icons.mosque_rounded,
  'book_rounded': Icons.book_rounded,
  'water_drop_rounded': Icons.water_drop_rounded,
  'volunteer_activism_rounded': Icons.volunteer_activism_rounded,
  'wb_sunny_rounded': Icons.wb_sunny_rounded,
  'nightlight_round': Icons.nightlight_round,
  'self_improvement_rounded': Icons.self_improvement_rounded,
};

class AddReminderBottomSheet extends ConsumerStatefulWidget {
  const AddReminderBottomSheet({super.key});

  @override
  ConsumerState<AddReminderBottomSheet> createState() =>
      _AddReminderBottomSheetState();
}

class _AddReminderBottomSheetState
    extends ConsumerState<AddReminderBottomSheet> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedIconKey = 'favorite_rounded';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showCustomTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    // Store time as padded 24h "HH:mm"
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    try {
      final id = await ref
          .read(remindersDaoProvider)
          .addReminder(title: title, iconName: _selectedIconKey, time: timeStr);

      // Fetch the created reminder and sync
      final reminder = Reminder(
        id: id,
        title: title,
        iconName: _selectedIconKey,
        time: timeStr,
        isEnabled: true,
        createdAt: DateTime.now(),
      );
      await ref.read(syncManagerProvider).syncReminder(reminder);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addReminderSaveError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: context.colors.tealGoldGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      l10n.addReminderTitle,
                      style: context.typography.headingMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── عنوان التذكير ──
                Text(
                  l10n.addReminderTitleLabel,
                  style: context.typography.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _titleController,
                  style: context.typography.bodyMedium,
                  textDirection: TextDirection.rtl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l10n.addReminderTitleRequired;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: l10n.addReminderTitleHint,
                    hintStyle: context.typography.bodyMedium.copyWith(
                      color: context.colors.textDim,
                    ),
                    prefixIcon: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── وقت التذكير ──
                Text(
                  l10n.addReminderTimeLabel,
                  style: context.typography.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () => _selectTime(context),
                  borderRadius: AppRadius.input,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.card2,
                      borderRadius: AppRadius.input,
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: context.colors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          _selectedTime.format(context),
                          style: context.typography.bodyLarge.copyWith(
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          color: context.colors.textDim,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── اختر الأيقونة ──
                Text(
                  l10n.addReminderIconLabel,
                  style: context.typography.labelLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kReminderIcons.entries.map((entry) {
                    final isSelected = _selectedIconKey == entry.key;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconKey = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected ? null : context.colors.card2,
                          gradient: isSelected
                              ? context.colors.tealGoldGradient
                              : null,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: isSelected
                              ? null
                              : Border.all(color: context.colors.border),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: context.colors.teal.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            entry.value,
                            color: isSelected
                                ? Colors.white
                                : context.colors.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                // ── Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: l10n.commonCancel,
                        isOutline: true,
                        onTap: () async => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: PrimaryButton(
                        label: l10n.addReminderAddButton,
                        onTap: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
