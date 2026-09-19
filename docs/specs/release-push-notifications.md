# Spec: Release Push Notifications

## Status

Partially implemented. The in-app update check (Goal 1) is fully working
today. The real push path (Goal 2) is fully coded but inert until a Firebase
project is created and its config files are added — see **Manual setup**
below.

## Context

There was no way for a user to learn a new APK release existed unless they
manually re-visited the web app's download page
(`apps/web/src/components/landing/DownloadSection.tsx`) or the GitHub
Releases page. `.github/workflows/release-apk.yml` already builds the APK,
creates a GitHub Release, and publishes a `manifest.json` to Supabase
Storage that `GET /api/releases/latest` (`apps/web/src/app/api/releases/
latest/route.ts`) reads — that endpoint is public/unauthenticated and was
the missing piece needed to let the *app itself* check for updates.

True push notifications (reaching a user even when the app is closed)
require a real push service — this app had zero push infrastructure before
this spec (no Firebase, no APNs, nothing; confirmed by grepping the whole
mobile app for "firebase"/"fcm"/"google-services" — clean slate). Standing
one up requires creating an actual Firebase project, which needs a Google
account action and downloading a config file — not something that can be
done from inside this codebase. Given that, and given a careless native
Gradle change here could break the Android build used for every release,
this was split into two halves on purpose (see the two goals below).

## Goals

1. **In-app update check (ships working today, no external service).** On
   each cold launch, the app calls `/api/releases/latest`, compares the
   returned version against the installed one, and shows a local
   notification if a newer release exists — once per version, not on every
   launch. Tapping it opens the web download page.
2. **Real push notification, scaffolded (Firebase Cloud Messaging).** Every
   device subscribes to a single `new_release` FCM topic on launch (no
   per-device token database needed for a broadcast-to-everyone use case).
   `release-apk.yml` sends one topic broadcast per release, after the
   manifest is confirmed published. This reaches users even with the app
   fully closed — but only once a real Firebase project exists; until then
   every piece of code here safely no-ops (see Non-goals).

## Non-goals

- **Must never break the existing Android build.** The Google Services
  Gradle plugin is applied conditionally
  (`if (file("google-services.json").exists())` in
  `apps/mobile/android/app/build.gradle.kts`) specifically so this ships
  safely before any real Firebase project exists — every build (local dev,
  CI) behaves exactly as before until that file is added. This was verified
  by running `flutter build apk --debug` locally with no
  `google-services.json` present.
- **iOS push is deferred.** No `Podfile`/entitlements/APNs wiring was
  touched. `firebase_messaging`'s Dart API is cross-platform, so once
  Android is proven out, adding `GoogleService-Info.plist` + an APNs Auth
  Key in the Firebase console + a `remote-notification` background mode is
  the remaining iOS-specific work — same "separate, later" treatment this
  repo already gives iOS release signing (see `docs/ios-testflight-setup.md`
  per the README).
- **No per-device token registry.** A topic broadcast is the right shape
  for "notify literally everyone" — storing/refreshing/pruning individual
  FCM tokens in Supabase would only be needed for targeted or per-user
  notifications, which nothing here asks for.
- **No retry/backoff on the CI push step.** Matches the existing Supabase
  manifest-publish step's own philosophy in the same workflow: a failed
  push notification is logged but never fails the release.

## Functional requirements (EARS)

- R1: WHEN the app launches, THE SYSTEM SHALL fetch `/api/releases/latest`
  and compare its `version` field against the installed app version.
- R2: IF the fetched version is newer than installed AND the user has not
  already been notified for that exact version, THEN THE SYSTEM SHALL show
  a local notification and record that version as notified.
- R3: WHEN the user taps either the in-app update notification or a real
  push notification for a release, THE SYSTEM SHALL open
  `https://takwa-web.vercel.app/#download` in the external browser.
- R4: WHEN `PushNotificationService.initialize()` cannot initialize Firebase
  (no config present), THE SYSTEM SHALL log and continue app startup
  normally — never crash or block on a missing/invalid Firebase config.
- R5: WHEN a device successfully initializes Firebase, THE SYSTEM SHALL
  subscribe it to the `new_release` FCM topic.
- R6: WHEN `release-apk.yml` finishes publishing the release manifest AND
  the `FCM_SERVICE_ACCOUNT_JSON` secret is configured, THE SYSTEM SHALL send
  one push notification to the `new_release` topic containing the new
  version and the download URL.
- R7: IF `FCM_SERVICE_ACCOUNT_JSON` is not configured, THEN THE SYSTEM SHALL
  skip the push step with a log message, without failing the release.

## Manual setup required to activate real push (Goal 2)

Everything below is the one-time work needed to turn on Firebase Cloud
Messaging. Until it's done, Goal 1 (in-app check) keeps working on its own.

1. Create a Firebase project at <https://console.firebase.google.com> (any
   name; it only needs to exist).
2. Add an Android app to it with package name `com.takwa` (matches
   `applicationId` in `apps/mobile/android/app/build.gradle.kts`).
3. Download the generated `google-services.json` and place it at
   `apps/mobile/android/app/google-services.json`. As soon as this file
   exists, the Gradle plugin (already declared, `apply false`, in
   `apps/mobile/android/settings.gradle.kts`) starts applying automatically
   — no further Gradle edits needed.
4. In Firebase Console → Project Settings → Service Accounts → "Generate
   new private key" — this downloads a JSON file. Add its **entire
   contents** as a GitHub Actions repository secret named
   `FCM_SERVICE_ACCOUNT_JSON`. `release-apk.yml`'s push step is already
   gated on this secret's presence and needs no other configuration (it
   derives the Firebase project ID from the key itself).
5. (Optional, for iOS later) Add an iOS app to the same Firebase project,
   download `GoogleService-Info.plist`, add it to `apps/mobile/ios/Runner/`,
   and configure an APNs Auth Key in Firebase Console → Project Settings →
   Cloud Messaging — plus a `remote-notification` entry in
   `UIBackgroundModes` in `Info.plist`. Not required for Android to work.

Once steps 1–4 are done, the very next tagged release will broadcast a push
notification to every device that has the app installed with Firebase
configured.
