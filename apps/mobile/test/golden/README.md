# Golden tests

`main_shell_golden_test.dart` renders the app's five bottom-nav screens
(Home, Qiyam, Checklist, Statistics, Settings) across every combination of:

- **theme**: light, dark, Ramadan
- **text scale**: 1.0x, 1.5x

— 30 golden images total — per the UI/UX audit's recommendation (item 30,
Phase 4) to have something that "stops the regressions above from
returning." Several of those regressions (the `matchTextDirection` errors,
the corrupted `khatma_progress_screen.dart` card, the reduce-motion adoption
gap) were only caught by manual code reading or CI's `flutter analyze` in
this pass — none of them would have been visible in a rendered screenshot
diff, which is exactly the gap golden tests close.

## This needs one manual step before it's usable

The environment these tests were written in has no Flutter SDK, so **the
golden test file above has never actually been run** — there are no
baseline PNGs for it to compare against yet, and `flutter analyze`/`flutter
test` can't generate or verify images on their own. Trying to run this file
today just fails with "no golden file found" on every case.

To make it usable, from a machine with the Flutter SDK installed:

```bash
cd apps/mobile
flutter test --update-goldens test/golden/main_shell_golden_test.dart
```

This generates `test/golden/goldens/*.png` (30 files, one per
screen/theme/scale combination). Then:

1. **Look at the generated images.** This is the step that actually matters
   — `--update-goldens` writes whatever the app currently renders, bugs
   included, as the new "correct" baseline. Skim all 30 for anything
   obviously wrong (a broken layout, missing text, wrong colors) before
   committing them. If something looks wrong, fix the underlying screen
   first, then re-run `--update-goldens` to capture the corrected version
   — don't commit a screenshot of a known bug as the baseline.
2. Commit the generated `test/golden/goldens/` directory.
3. Ask Claude (or add it yourself) to add this file to
   `.github/workflows/mobile-ci.yml`'s `flutter test` step (it already runs
   `flutter test`, which picks up every `*_test.dart` file including this
   one automatically — no separate CI step should be needed once the
   baselines exist, just confirm the workflow's `flutter test` invocation
   doesn't exclude `test/golden/`).

## Regenerating after an intentional visual change

Same command as above. `flutter test` (without `--update-goldens`) is what
CI runs day to day — it fails loudly on any pixel diff against the
committed baseline, intentional or not, which is the point. Re-run with
`--update-goldens` and re-commit the changed PNGs whenever a change to one
of these five screens is meant to look different.

## Why these five screens, and not six

The audit doc that specifies this item ("six main screens") predates a
later Phase 4 change that reduced the bottom nav from 6 tabs to 5
(`docs/flutter-ui-ux-audit.md` §C10). There are only 5 bottom-nav screens
to cover now: Home, Qiyam, Checklist, Statistics, Settings.

## Why Ramadan mode only has a dark variant here

The in-app Ramadan toggle only ever drives `RamadanTheme.dark()` — there's
no separate "Ramadan + light system theme" combination the app itself can
be put into (see `ramadan_theme.dart`), so a `RamadanTheme.light()` case
would test a combination that can't occur.

## A known source of flakiness

`TakwaLoadingIndicator` / `TakwaRefreshIndicator` spin unconditionally —
they're deliberately excluded from the reduce-motion gate added elsewhere
in this audit pass, since a real loading/refresh spinner communicates
actual in-progress work and stopping it would misrepresent that (see
`ReducedMotionRepeat`'s own doc comment in
`packages/takwa_ui/lib/src/app_theme.dart`). If a screen is still loading
at the moment a golden test captures it, that spinner's rotation angle is
a source of pixel-diff flakiness this test setup doesn't fully rule out.
If a specific case turns out flaky in practice, the fix is likely a longer
or more deterministic pump schedule for that one screen, not disabling the
spinner.
