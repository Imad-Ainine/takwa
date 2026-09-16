import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Single source of truth for a [TaqwaLevel]'s emoji and localized display
/// label. Was previously duplicated as hardcoded-Arabic switch statements in
/// `MonthStats.levelLabel` (daos.dart — a DB layer with no `BuildContext`,
/// so it could never actually be locale-aware) and again inline in
/// `statistics_screen.dart`'s `_levelEmoji`.
String taqwaLevelEmoji(TaqwaLevel level) => switch (level) {
  TaqwaLevel.mubtadi => '🌱',
  TaqwaLevel.salik => '🌿',
  TaqwaLevel.mujahid => '⚔️',
  TaqwaLevel.mutaqi => '✨',
};

String taqwaLevelLabel(AppLocalizations l10n, TaqwaLevel level) =>
    switch (level) {
      TaqwaLevel.mubtadi => l10n.homeLevelMubtadi,
      TaqwaLevel.salik => l10n.homeLevelSalik,
      TaqwaLevel.mujahid => l10n.homeLevelMujahid,
      TaqwaLevel.mutaqi => l10n.homeLevelMutaqi,
    };
