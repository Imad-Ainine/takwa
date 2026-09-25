# Spec: Zakat Calculator

## Status
Implemented (R1-R7) as `lib/features/zakat/` — a pure math module (`domain/zakat_calculator.dart`,
unit-tested) plus `presentation/screens/zakat_calculator_screen.dart` with cash, bank, gold,
silver, trade goods and deductible debt fields, a gold/silver Nisab picker (defaults to the
silver/595g standard), the Hawl confirmation toggle, the 2.5% result with Nisab shortfall, a
saved-calculation history you can restore from, an annual reminder via the existing
`Reminders` feature, and a Zakat al-Fitr section. Persistence is the new local-only
`zakat_calculations` Drift table (`ZakatDao`); it is deliberately not part of the Supabase
sync whitelist.

Resolved open questions:
- **Price source:** the user types today's gold/silver price per gram themselves (helper text
  says so). There is no network price feed and no cache to go stale — R3's "cannot resolve a
  price" state is simply an empty field, and the result card then shows
  `zakatMissingPriceMessage` while still doing gram-based math.
- **Currency:** free-text display label only, no conversion, matching the app's single-unit
  approach.
- **Weight or value (R1):** gold/silver each take either weight × price or a straight value.
  Weight × price wins when both are filled so a restored calculation can't double-count.

## Context

Prior art to follow in this codebase:

- `DailyRecords.sadaqah` / `sadaqahAmount` (`apps/mobile/lib/core/database/app_database.dart:65`)
  is the only existing money-shaped field, and it's a simple opt-in daily amount with no
  currency handling — the app has never needed a currency concept before.
- Settings screens live under `apps/mobile/lib/features/settings/presentation/screens/`,
  each a standalone `ConsumerWidget`/`StatefulWidget` following the pattern in
  `subscription_screen.dart` (custom app bar via `CustomLeadingButton`, `PrimaryButton`
  for actions, `context.colors`/`context.typography` theme tokens).
- The app is single-user, local-first (Drift/SQLite) with optional Supabase sync
  (`core/supabase/sync_manager.dart`) — a Zakat calculator's inputs/results should follow
  the same local-first pattern, not require an account.
- There is no currency/locale-for-money setting anywhere (`locale_provider.dart` only
  drives UI language, ar/en). This must be decided as part of the feature, not assumed.

## Goals

1. A Zakat al-Mal calculator: user enters cash, bank savings, gold/silver holdings
   (by weight or value), business/trade assets, and outstanding short-term debts; the
   tool computes net zakatable wealth and compares it against the Nisab threshold.
2. Nisab reference values: support both the gold standard (~85g) and silver standard
   (~595g), since madhabs/scholars differ on which to use — let the user pick, default
   to whichever is more commonly recommended (silver, as the more cautious/inclusive
   threshold) rather than silently hardcoding one.
3. Live gold/silver spot price: needed to convert the gram-based Nisab into the user's
   currency. This requires either (a) a bundled/periodically-updated static price table
   shipped with app updates (matches the app's fully-offline-capable philosophy), or
   (b) a network fetch with graceful offline fallback to the last-cached price. Needs a
   product decision (see Open Questions) — this is the one place the calculator can't be
   purely offline-and-static without going stale.
4. Result: computed Zakat due = 2.5% of zakatable wealth, only if wealth ≥ Nisab and has
   been held for a lunar year (Hawl) — expose a simple "have you held this wealth for a
   full Hijri year?" toggle rather than trying to track Hawl automatically per-asset.
5. Persist the last calculation locally (new small table or `UserSettings` key/value rows,
   reusing the existing `UserSettings` table pattern at
   `apps/mobile/lib/core/database/app_database.dart:176`) so the user can revisit/update
   it, not just a one-shot calculator.
6. Optional: a reminder ("Zakat due" annual reminder), reusing the existing `Reminders`
   table/feature (`apps/mobile/lib/features/reminders`) rather than building new
   notification plumbing.

## Non-goals

- Zakat al-Fitr (the separate, fixed, end-of-Ramadan per-person charity) — different
  calculation (a fixed food-staple amount per household member), could be a fast-follow
  in the same screen but is out of scope for v1.
- Zakat on livestock/agriculture — niche for this app's urban user base; skip entirely.
- Any payment/disbursement flow (sending the Zakat money anywhere). This is a calculator
  only, same spirit as `subscription_screen.dart`'s "honor system" — the app never
  handles real money movement today (see `payment_methods_screen.dart`, which is for the
  app's own optional support subscription, not a payments SDK).
- Automatic Hawl (lunar-year holding period) tracking per asset.

## Functional requirements (EARS)

- R1: WHEN the user opens the Zakat calculator, THE SYSTEM SHALL present input fields for
  cash on hand, bank balances, gold weight/value, silver weight/value, trade goods value,
  and deductible short-term debt.
- R2: WHEN the user selects a Nisab standard (gold or silver), THE SYSTEM SHALL compute
  the Nisab threshold in the user's currency using the current gold/silver price.
- R3: IF the app cannot resolve a current gold/silver price (offline, first launch with no
  cached price), THEN THE SYSTEM SHALL show the calculator with a visible "prices last
  updated on X" notice using the last cached price, or block only the currency-denominated
  Nisab comparison while still allowing gram-based entry.
- R4: WHEN total zakatable wealth (assets minus deductible debt) is at or above the
  selected Nisab AND the user confirms the wealth passed a full Hijri year, THE SYSTEM
  SHALL display Zakat due = 2.5% of zakatable wealth.
- R5: WHEN total zakatable wealth is below Nisab, THE SYSTEM SHALL state that no Zakat is
  due and show the shortfall to reach Nisab.
- R6: WHEN the user saves a calculation, THE SYSTEM SHALL persist the inputs and result
  locally so reopening the calculator restores the last entry.
- R7: WHERE the user enables a Zakat reminder, THE SYSTEM SHALL create an entry via the
  existing `Reminders` feature rather than a bespoke notification path.

## Data model changes

- New table (or `UserSettings` rows) to persist calculator inputs + last result:
  `zakat_calculations`: `id`, `computedAt`, `cashAmount`, `bankAmount`, `goldGrams`,
  `goldValue`, `silverGrams`, `silverValue`, `tradeGoodsValue`, `debtAmount`,
  `nisabStandard` (gold/silver), `currencyCode`, `resultDue`, `hawlConfirmed`.
- New cached-price store: `goldSilverPriceCache` (or a `UserSettings` key), storing
  price-per-gram for gold and silver, currency, and a `fetchedAt`/`bundledVersion`
  timestamp, per whichever sourcing approach is chosen (see Open Questions).

## Open questions

- Gold/silver price source: bundle a static table updated at each app release (simplest,
  fully offline, but can drift between releases), or add a network call (introduces the
  app's first "requires internet for correctness" feature, plus a source to vet for
  reliability)? This blocks R2/R3 implementation and should be decided before coding
  starts.
- Currency: let the user free-type a currency symbol/code (simplest, matches the app
  having no currency infra today), or add a currency picker + conversion? Given the app
  is Arabic/English only with no multi-currency precedent, recommend starting with a
  free-text currency label purely for display, with all math done in a single
  user-chosen unit (no conversion).
- Should Zakat al-Fitr be bundled into this same screen as a second tab from day one,
  given how small its calculation is, or deferred? Listed as non-goal above pending
  product input.
