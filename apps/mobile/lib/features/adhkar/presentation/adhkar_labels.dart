import 'package:takwa/features/adhkar/data/adhkar_data.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Localized name for an adhkar category.
///
/// Single source for every screen that shows categories: the tabs screen and
/// the favourites list each kept their own switch, they disagreed on both the
/// wording and the order, and the tab labels ended up pointing at the wrong
/// content. New categories must be added here, not at a call site.
String adhkarTabLabel(AppLocalizations l10n, AdhkarCategory cat) =>
    switch (cat) {
      AdhkarCategory.wakingUp => l10n.adhkarTabWakingUp,
      AdhkarCategory.morning => l10n.adhkarTabMorning,
      AdhkarCategory.evening => l10n.adhkarTabEvening,
      AdhkarCategory.afterPrayer => l10n.adhkarTabAfterPrayer,
      AdhkarCategory.sleep => l10n.adhkarTabSleep,
      AdhkarCategory.home => l10n.adhkarTabHome,
      AdhkarCategory.travel => l10n.adhkarTabTravel,
      AdhkarCategory.food => l10n.adhkarTabFood,
      AdhkarCategory.gathering => l10n.adhkarTabGathering,
      AdhkarCategory.misc => l10n.adhkarTabMisc,
    };

/// '(icon, name)' in `AdhkarCategory.values` order, matching the order the tabs
/// screen builds its `TabBarView` children in.
List<(String, String)> adhkarTabs(AppLocalizations l10n) => [
  for (final cat in AdhkarCategory.values)
    (cat.emoji, adhkarTabLabel(l10n, cat)),
];
