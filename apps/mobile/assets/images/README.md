# assets/images

`dev.png` (the developer photo shown on the "About the Developer" /
`AboutMeScreen` screen) must be committed here. It is only referenced from
code (`about_me_screen.dart`) — nothing generates it — so if it is ever
missing from a checkout (e.g. it existed only on a contributor's machine
and was never `git add`ed), the app still builds fine but ships with a
broken avatar image. `flutter pub get` / `flutter analyze` won't catch this
because Flutter doesn't validate that every `AssetImage` path resolves to a
real file, only that paths declared under `flutter.assets` in
`pubspec.yaml` exist (this whole directory is covered by the
`assets/images/` glob).

Before committing a replacement, verify it's tracked:

```sh
git ls-files apps/mobile/assets/images/dev.png
```
