import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/primary_switch.dart';
import 'package:takwa/core/widgets/custom_time_picker.dart';
import 'package:takwa/l10n/app_localizations.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String icon;

  const SectionHeader({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: context.typography.headingMedium.copyWith(
              fontSize: 19,
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final String? title;

  const SettingsCard({
    super.key,
    required this.children,
    this.padding,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 4,
              bottom: 8,
              top: 4,
            ),
            child: Text(
              title!,
              style: context.typography.caption.copyWith(
                color: context.colors.textDim,
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Container(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: context.colors.border.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      endIndent: 16,
      color: context.colors.border.withValues(alpha: 0.5),
    );
  }
}

class ToggleSetting extends StatelessWidget {
  final String icon;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accentColor;

  const ToggleSetting({
    super.key,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        // color: value
        //     ? (accentColor ?? context.colors.teal).withValues(alpha: 0.05)
        //     : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            AnimatedScale(
              scale: value ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (accentColor ?? context.colors.gold).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: (accentColor ?? context.colors.gold).withValues(
                      alpha: 0.1,
                    ),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.typography.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                      color: context.colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: context.typography.caption.copyWith(
                      fontSize: 10.5,
                      color: context.colors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PrimarySwitch(value: value, onChanged: onChanged),
                Text(
                  value
                      ? (AppLocalizations.of(context)?.settingEnabled ?? 'مفعل')
                      : (AppLocalizations.of(context)?.settingDisabled ??
                            'معطل'),
                  style: context.typography.caption.copyWith(
                    color: value ? context.colors.teal : context.colors.textDim,
                    fontSize: 8.5,
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

class ActionSetting extends StatelessWidget {
  final String icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool isDestructive;

  const ActionSetting({
    super.key,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? context.colors.danger
        : context.colors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    (isDestructive
                            ? context.colors.danger
                            : context.colors.gold)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.typography.bodyMedium.copyWith(
                      fontSize: 15,
                      color: color,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: context.typography.caption.copyWith(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: context.colors.textDim,
            ),
          ],
        ),
      ),
    );
  }
}

class SelectSetting extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  final Widget Function(BuildContext, String, bool)? itemTrailingBuilder;

  const SelectSetting({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.itemTrailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.typography.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    options[value] ?? value,
                    style: context.typography.caption.copyWith(
                      fontSize: 10.5,
                      color: context.colors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: context.colors.textDim,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(ctx).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  label,
                  style: context.typography.headingMedium.copyWith(
                    fontSize: 18,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 40), // Spacer for centering
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.entries.map((e) {
                    final isSelected = value == e.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          onChanged(e.key);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colors.gold.withValues(alpha: 0.08)
                                : context.colors.card.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isSelected
                                  ? context.colors.gold.withValues(alpha: 0.3)
                                  : context.colors.border.withValues(
                                      alpha: 0.5,
                                    ),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: context.typography.bodyMedium.copyWith(
                                    fontSize: 14,
                                    color: isSelected
                                        ? context.colors.textPrimary
                                        : context.colors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (itemTrailingBuilder != null)
                                itemTrailingBuilder!(ctx, e.key, isSelected),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: context.colors.gold,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckboxSetting extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CheckboxSetting({
    super.key,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: context.colors.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.typography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: context.colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: context.typography.caption.copyWith(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SyncStatusIndicator extends StatelessWidget {
  final bool isSyncing;
  final DateTime? lastSynced;

  /// Non-null when the last `fullSync()` had at least one step fail (R6 of
  /// achievements-statistics-db-persistence-fix.md) — surfaces that instead
  /// of always claiming "synced successfully" while a step is silently
  /// behind.
  final String? syncError;

  /// Count of entities still awaiting a retried push (`SyncOutbox`) — the
  /// other half of R6: a user can now tell sync is behind even when the
  /// *last* attempt didn't itself throw (e.g. offline since).
  final int pendingCount;

  const SyncStatusIndicator({
    super.key,
    required this.isSyncing,
    this.lastSynced,
    this.syncError,
    this.pendingCount = 0,
  });

  bool get _hasIssue => !isSyncing && (syncError != null || pendingCount > 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _hasIssue
              ? context.colors.warning.withValues(alpha: 0.6)
              : context.colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicator(context),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _statusText(context),
            style: context.typography.caption.copyWith(
              color: _hasIssue
                  ? context.colors.warningText
                  : context.colors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(BuildContext context) {
    if (isSyncing) {
      return AppLocalizations.of(context)?.syncStatusSyncing ??
          'جاري المزامنة...';
    }
    if (syncError != null) {
      return AppLocalizations.of(context)?.syncStatusError ??
          'تعذّرت آخر مزامنة، ستتم إعادة المحاولة تلقائيًا';
    }
    if (pendingCount > 0) {
      return AppLocalizations.of(context)?.syncStatusPending(pendingCount) ??
          '$pendingCount عنصر بانتظار المزامنة';
    }
    return AppLocalizations.of(context)?.syncStatusSuccess ??
        'تمت المزامنة بنجاح';
  }

  Widget _buildIndicator(BuildContext context) {
    if (isSyncing) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(context.colors.gold),
        ),
      );
    }
    if (_hasIssue) {
      return Icon(
        Icons.sync_problem_rounded,
        size: 14,
        color: context.colors.warningText,
      );
    }
    return Icon(
      Icons.check_circle_outline_rounded,
      size: 14,
      color: context.colors.teal,
    );
  }
}

class TimeSetting extends StatelessWidget {
  final String icon;
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const TimeSetting({
    super.key,
    required this.icon,
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');

    return InkWell(
      onTap: () async {
        final picked = await showCustomTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: context.typography.bodyMedium.copyWith(
                  fontSize: 15,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: context.colors.goldDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.colors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '$h:$m',
                style: context.typography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: context.colors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SliderSetting extends StatelessWidget {
  final String icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;

  /// Formats [value] into a short readout shown at the end of the label
  /// row (e.g. "80%") — a bare slider gives no indication of its concrete
  /// effect until dragged. Optional so existing callers that don't pass it
  /// keep their previous look; see
  /// docs/specs/settings-notifications-improvements.md R7.
  final String Function(double value)? valueLabelBuilder;

  const SliderSetting({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.valueLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: context.typography.bodyMedium.copyWith(
                    fontSize: 15,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              if (valueLabelBuilder != null)
                Text(
                  valueLabelBuilder!(value),
                  style: context.typography.caption.copyWith(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: context.colors.gold,
              inactiveTrackColor: context.colors.border.withValues(alpha: 0.5),
              thumbColor: context.colors.gold,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: min,
              max: max,
              divisions: divisions,
            ),
          ),
        ],
      ),
    );
  }
}
