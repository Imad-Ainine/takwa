import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/l10n/app_localizations.dart';

Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: context.colors.background,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) {
      return _CustomTimePickerWidget(initialTime: initialTime);
    },
  );
}

class _CustomTimePickerWidget extends StatefulWidget {
  final TimeOfDay initialTime;

  const _CustomTimePickerWidget({required this.initialTime});

  @override
  State<_CustomTimePickerWidget> createState() =>
      _CustomTimePickerWidgetState();
}

class _CustomTimePickerWidgetState extends State<_CustomTimePickerWidget> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _ampmController;

  late int _selectedHour;
  late int _selectedMinute;
  late int _selectedPeriod;

  @override
  void initState() {
    super.initState();
    int h = widget.initialTime.hour;
    _selectedPeriod = h < 12 ? 0 : 1;
    _selectedHour = h % 12 == 0 ? 12 : h % 12;
    _selectedMinute = widget.initialTime.minute;

    _hourController = FixedExtentScrollController(
      initialItem: _selectedHour - 1,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
    _ampmController = FixedExtentScrollController(initialItem: _selectedPeriod);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _ampmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.customTimePickerTitle,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Highlight Selection background
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.teal.withValues(alpha: 0.25)),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWheel(
                        controller: _hourController,
                        itemCount: 12,
                        onChanged: (v) => _selectedHour = v + 1,
                        itemBuilder: (v) => (v + 1).toString().padLeft(2, '0'),
                        selectedIndex: _selectedHour - 1,
                        colors: colors,
                      ),
                      Text(
                        ':',
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      _buildWheel(
                        controller: _minuteController,
                        itemCount: 60,
                        onChanged: (v) => _selectedMinute = v,
                        itemBuilder: (v) => v.toString().padLeft(2, '0'),
                        selectedIndex: _selectedMinute,
                        colors: colors,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildWheel(
                        controller: _ampmController,
                        itemCount: 2,
                        width: 70,
                        onChanged: (v) => _selectedPeriod = v,
                        itemBuilder: (v) => v == 0 ? 'AM' : 'PM',
                        selectedIndex: _selectedPeriod,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: colors.border),
                    ),
                  ),
                  child: Text(
                    l10n.commonCancel,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 16,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    int h = _selectedHour;
                    if (_selectedPeriod == 0 && h == 12) h = 0;
                    if (_selectedPeriod == 1 && h < 12) h += 12;
                    Navigator.pop(
                      context,
                      TimeOfDay(hour: h, minute: _selectedMinute),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.teal,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.customTimePickerConfirmButton,
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onChanged,
    required String Function(int) itemBuilder,
    required dynamic colors,
    required int selectedIndex,
    double width = 80,
  }) {
    return SizedBox(
      width: width,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        physics: const FixedExtentScrollPhysics(),
        perspective: 0.005,
        squeeze: 1.2,
        overAndUnderCenterOpacity: 0.35,
        onSelectedItemChanged: (i) {
          onChanged(i);
          setState(() {});
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            final isSelected = selectedIndex == index;
            return Center(
              child: Text(
                itemBuilder(index),
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: isSelected ? 24 : 20,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
