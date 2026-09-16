// RamadanColors / RamadanTheme / RamadanDecorations / RamadanBgPainter /
// AdaptiveStyle moved to packages/takwa_ui — re-exported below so every
// existing `import 'core/theme/ramadan_theme.dart'` keeps working.
//
// RamadanToggle stays here (not in takwa_ui): it's a settings control
// wired to this app's Riverpod providers (settings DAO, notifications,
// sync), not a pure UI token — see the audit's "Architecture & Code
// Quality" section for why that split matters.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa_ui/takwa_ui.dart';

import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/widgets/primary_switch.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/supabase/sync_manager.dart';

export 'package:takwa_ui/takwa_ui.dart';

class RamadanToggle extends ConsumerWidget {
  const RamadanToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: isRamadan ? style.gold.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isRamadan ? '🌙' : '☽', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.xs),
          PrimarySwitch(
            value: isRamadan,
            onChanged: (v) async {
              HapticFeedback.mediumImpact();
              final dao = ref.read(settingsDaoProvider);
              await dao.setBool('ramadan_mode', v);
              ref.invalidate(ramadanModeProvider);

              // ── Sync with Cloud & Reschedule Notifications ──
              await ref.read(notificationsManagerProvider).reschedule();
              await ref.read(syncManagerProvider).syncSettings();
            },
            accentColor: style.gold,
          ),
        ],
      ),
    );
  }
}
