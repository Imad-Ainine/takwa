import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/utils/prayer_display.dart';
import 'package:takwa/l10n/app_localizations.dart';

class PrayerSelectionSheet extends StatefulWidget {
  final String title;
  final List<String> selectedPrayers;
  final bool includeSunrise;
  final ValueChanged<List<String>> onChanged;

  const PrayerSelectionSheet({
    super.key,
    required this.title,
    required this.selectedPrayers,
    this.includeSunrise = false,
    required this.onChanged,
  });

  static void show({
    required BuildContext context,
    required String title,
    required List<String> selectedPrayers,
    bool includeSunrise = false,
    required ValueChanged<List<String>> onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PrayerSelectionSheet(
        title: title,
        selectedPrayers: selectedPrayers,
        includeSunrise: includeSunrise,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<PrayerSelectionSheet> createState() => _PrayerSelectionSheetState();
}

class _PrayerSelectionSheetState extends State<PrayerSelectionSheet> {
  late List<String> _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = List.from(widget.selectedPrayers);
  }

  void _togglePrayer(String key) {
    setState(() {
      if (_currentSelection.contains(key)) {
        _currentSelection.remove(key);
      } else {
        _currentSelection.add(key);
      }
    });
    widget.onChanged(_currentSelection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prayers = [
      'fajr',
      if (widget.includeSunrise) 'sunrise',
      'dhuhr',
      'jumuah',
      'asr',
      'maghrib',
      'isha',
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
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
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                widget.title,
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
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: prayers.map((key) {
                  final isSelected = _currentSelection.contains(key);
                  final name = prayerLocalizedName(l10n, key);
                  final label = key == 'sunrise'
                      ? l10n.prayerSelectionSunriseAlertsLabel
                      : l10n.prayerSelectionAdhanLabel(name);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _togglePrayer(key),
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
                                : context.colors.border.withValues(alpha: 0.5),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'NotoNaskhArabic',
                                fontSize: 14,
                                color: isSelected
                                    ? context.colors.textPrimary
                                    : context.colors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: context.colors.gold,
                                size: 20,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: context.colors.textDim.withValues(alpha: 0.3),
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
    );
  }
}
