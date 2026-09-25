<div align="center">

# 🌙 تقوى — Takwa

**A premium Islamic self-accountability app built with Flutter**

_Track your daily prayers, Quran recitation, adhkar, fasting, and guard against prohibitions — all in a beautiful offline-first experience._

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.x-00C853)](https://riverpod.dev)
[![Drift](https://img.shields.io/badge/Drift-SQLite-FF6F00)](https://drift.simonbinder.eu)
[![License](https://img.shields.io/badge/License-MIT-gold)](LICENSE)

</div>

|                                               Screenshot 1                                                |                                               Screenshot 2                                                |
| :-------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------: |
| <img src="https://github.com/user-attachments/assets/579b78d7-f1d8-4ec3-9560-99e89d0fdbb4" width="480" /> | <img src="https://github.com/user-attachments/assets/5e38a470-3f09-4304-8d7d-d3417f6a241e" width="480" /> |

---

## ✨ Features

| Category              | What it does                                                                             |
| --------------------- | ---------------------------------------------------------------------------------------- |
| 🕌 **Prayers**        | Track all 5 daily prayers — performed, qadaa, or missed — with a beautiful status picker |
| 📖 **Quran**          | Log pages read each day with per-page point rewards                                      |
| 📿 **Adhkar**         | Morning & evening adhkar toggles with streak awareness                                   |
| 🌙 **Fasting**        | Mark obligatory (فريضة) or voluntary (نافلة) fasts                                       |
| 🌌 **Qiyam**          | Night prayer logging with bonus points                                                   |
| 💧 **Sadaqah**        | Daily charity checkbox — "ولو بكلمة طيبة"                                                |
| ⚠️ **Prohibitions**   | Honest self-audit for 6 major sins with repeat-count tracking                            |
| 📊 **Statistics**     | Weekly bar chart, monthly streaks, Taqwa level progression                               |
| 📝 **Day Notes**      | Personal journal entry saved per day                                                     |
| 🏆 **Achievements**   | Unlockable badges for streaks and Quran milestones                                       |
| 🗓️ **Hijri Calendar** | Dates displayed in the Islamic calendar                                                  |

---

## 📱 الشاشات الرئيسية · Key Screens

The application's interface was meticulously crafted as seen in the [`muhasaba_ui_preview.html`](muhasaba_ui_preview.html) design system. It consists of four primary screens:

### 1. Onboarding (مرحباً بك)

- **Welcome Message:** Greets users with the profound quote of Umar ibn Al-Khattab: _"حَاسِبُوا أَنفُسَكُمْ قَبْلَ أَنْ تُحَاسَبُوا"_
- **Feature Highlights:** Introduces tracking for daily worship, statistics, and reminders.

### 2. Home Dashboard (الرئيسية)

- **Header:** Displays current Hijri/Gregorian date and a dynamic greeting.
- **Next Prayer Card:** Highlights the upcoming prayer with an active countdown timer.
- **Taqwa Ring:** A circular progress indicator summarizing the day's total completion percentage and current streak.
- **Quick Ibadah:** A fast-access grid marking completed daily tasks like Fajr, Dhuhr, and Quran reading.
- **Daily Inspiration:** A dedicated card for a Quranic verse or quote of the day.

### 3. Daily Checklist (محاسبة اليوم)

- **Detailed Accountability:** Grouped lists for Prayers (الصلوات), Quran & Adhkar (القرآن والأذكار), and Prohibitions (المحظورات).
- **Gamification:** Displays the points gained (`+10`) for good deeds or lost (`-10`) for prohibitions, directly on the checklist items.

### 4. Statistics (تقرير الأداء)

- **Taqwa Score Card:** Shows the user's current spiritual level (e.g., مجاهد ⚔️) and total monthly points.
- **Weekly Chart:** A visual bar chart indicating performance over the last 7 days.
- **Continuous Streak:** Badges indicating how many consecutive days the user has maintained their habits.

---

## 🏗️ Architecture

```
lib/
├── app/
│   └── main_shell.dart          # Navigation shell
├── core/
│   ├── database/
│   │   ├── app_database.dart    # Drift schema & enums
│   │   ├── daos.dart            # Data Access Objects
│   │   └── *.g.dart             # Generated Drift files
│   ├── providers/
│   │   └── database_providers.dart  # Riverpod providers
│   └── theme/
│       └── app_theme.dart       # Design system (colors, typography, tokens)
└── features/
    ├── checklist/               # Daily checklist screen
    ├── home/                    # Home & points summary
    ├── onboarding/              # First-launch onboarding
    └── statistics/              # Charts and history
```

**Pattern:** Feature-first, layered architecture
**State:** Riverpod `StreamProvider` → Drift `watchSingleOrNull()` → reactive UI
**Storage:** Drift (SQLite) — fully offline, no internet required

---

## 🎨 Design System

The app uses a cohesive dark-mode-only design system defined in `app_theme.dart`:

| Token               | Value                 |
| ------------------- | --------------------- |
| Background          | `#0D1117` (night)     |
| Card                | `#1A2332`             |
| Gold (primary)      | `#C8A96E`             |
| Teal (secondary)    | `#3AAFA9`             |
| Success             | `#4CAF7D`             |
| Danger              | `#E07070`             |
| Arabic heading font | **Amiri**             |
| Arabic body font    | **Noto Naskh Arabic** |

---

## 🛢️ Database Schema

Powered by **Drift** (type-safe SQLite wrapper):

| Table                | Purpose                                                   |
| -------------------- | --------------------------------------------------------- |
| `daily_records`      | One row per day — prayers, quran, adhkar, fasting, points |
| `prohibitions_log`   | Per-prohibition commit log with repeat count              |
| `custom_ibadah`      | User-defined ibadah items                                 |
| `custom_ibadah_log`  | Log entries for custom ibadah                             |
| `achievements`       | Unlocked badges                                           |
| `user_settings`      | Key-value settings store                                  |
| `ramadan_progress`   | Ramadan-specific nightly progress                         |
| `prayer_times_cache` | Cached prayer times per location                          |

**Enums:** `PrayerStatus` · `FastingType` · `ProhibitionCategory` · `TaqwaLevel`

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **≥ 3.x**
- Dart **≥ 3.x**
- Android Studio / VS Code with Flutter plugin

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/takwa.git
cd takwa

# 2. Install dependencies
flutter pub get

# 3. Generate Drift database files
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

### Generate code after schema changes

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Environment variables

Create `apps/mobile/.env` (not committed) with:

| Variable                | Required | Purpose                                                              |
| ----------------------- | -------- | ---------------------------------------------------------------------- |
| `SUPABASE_URL`           | Yes      | Supabase project URL — see [`auth_setup_guide.md`](docs/auth_setup_guide.md) |
| `SUPABASE_ANON_KEY`      | Yes      | Supabase anon/public key                                              |
| `SENTRY_DSN`             | No       | Enables crash/error reporting via Sentry. Left unset, the app runs with no crash reporting — no events are sent anywhere. |
| `CHARGILY_SECRET_KEY`    | No       | Chargily Pay V2 secret key (`test_sk_…` / `sk_…`) — Bearer token for the CIB/Edahabia checkout API. Unset, the Chargily flow shows an error. |
| `CHARGILY_PUBLIC_KEY`    | No       | Chargily publishable key (`test_pk_…` / `pk_…`) — client-side identifier, kept for the widget-based flow. |
| `CHARGILY_LIVE`          | No       | `true` switches the API base URL to live mode; anything else stays on the test endpoints. |
| `CHARGILY_SUBSCRIPTION_AMOUNT` | No | Checkout amount in centime (minor units). Defaults to `200` = 200.00 DZD. |
| `WISE_IBAN` / `WISE_ACCOUNT_NUMBER` / `WISE_SORT_CODE` / `WISE_HOLDER_NAME` / `WISE_BANK_NAME` | No | Visa/Mastercard path: recipient details of the Wise account, shown on the Wise screen for the user to transfer from. Unset, that screen shows "coming soon". |
| `WISE_PROFILE_LINK`      | No       | `wise.com/pay/me/…` profile link opened by the "Open Wise" button (falls back to `https://app.wise.com`). |
| `WISE_MONTHLY_EUR`       | No       | Monthly amount in euro displayed on the Wise screen. Defaults to `10`. |
| `WISE_PAYMENT_REFERENCE` | No       | Transfer reference users should put on the payment so it can be matched. Defaults to `TAKWA`. |

---

## 📦 Dependencies

| Package                          | Purpose                              |
| -------------------------------- | ------------------------------------ |
| `flutter_riverpod`               | State management                     |
| `drift` + `sqlite3_flutter_libs` | Local SQLite database                |
| `google_fonts`                   | Amiri & Noto Naskh Arabic typography |
| `hijri`                          | Hijri calendar conversion            |
| `fl_chart`                       | Statistics charts                    |
| `flutter_local_notifications`    | Prayer time reminders                |
| `intl`                           | Date/number formatting               |
| `shared_preferences`             | Lightweight settings persistence     |
| `path_provider` + `path`         | Database file location               |

---

## 🧮 Points System

| Action                   | Points             |
| ------------------------ | ------------------ |
| Prayer performed in time | +10                |
| Prayer qadaa             | +5                 |
| Quran recitation         | +1 per page        |
| Morning adhkar           | +5                 |
| Evening adhkar           | +5                 |
| Night prayer (Qiyam)     | +15                |
| Fasting (obligatory)     | +20                |
| Fasting (voluntary)      | +10                |
| Sadaqah                  | +10                |
| Prohibition committed    | -10 per occurrence |

### Taqwa Levels

| Level | Points    | Label            |
| ----- | --------- | ---------------- |
| 🌱    | 0 – 99    | مبتدئ (Beginner) |
| 🌿    | 100 – 299 | سالك (Seeker)    |
| ⚔️    | 300 – 599 | مجاهد (Striver)  |
| ✨    | 600+      | متقي (The Pious) |

---

## 🌐 Supabase Cloud Sync

- **Offline-first** — all writes go to Drift, synced in the background via [`SyncManager`](lib/core/supabase/sync_manager.dart)
- **Auth** — Supabase Auth (email / Google)
- **Realtime** — live sync across devices via Postgres Realtime
- **Row Level Security** — users only access their own data — see [`supabase/README.md`](supabase/README.md) for auditing and version-controlling RLS policies

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<div align="center">

_"حاسبوا أنفسكم قبل أن تُحاسبوا"_
_"Hold yourselves accountable before you are held accountable"_
— عمر بن الخطاب رضي الله عنه

Made with ❤️ for the Muslim community

</div>
