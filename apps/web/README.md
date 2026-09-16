<div align="center">

# 🌐 تقوى ويب — Takwa Web

**The official web companion for the Takwa ecosystem**

*A premium Next.js application providing a seamless dashboard experience for the Takwa self-accountability system.*

[![Next.js](https://img.shields.io/badge/Next.js-16.2-black?logo=next.js)](https://nextjs.org)
[![React](https://img.shields.io/badge/React-19.0-61DAFB?logo=react)](https://react.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-CSS-38B2AC?logo=tailwind-css)](https://tailwindcss.com)

</div>

---

## ✨ Features

Takwa Web brings the powerful spiritual tracking of the mobile app to your browser:

- **Unified Dashboard**: View your Taqwa level, streaks, and daily progress at a glance. *(Auth foundation shipped — sign in at `/login` with the same account as the mobile app; the actual stats/achievements views are the next step, reading the same RLS-scoped Supabase tables mobile already syncs.)*
- **Detailed History**: Explore your past performance with interactive charts and calendars.
- **Settings Management**: Configure your profile and preferences (Planned Supabase Sync).
- **Responsive Design**: optimized for desktop and mobile browsers.

---

## 🚀 Getting Started (Within Monorepo)

This application is part of the Takwa Monorepo. To run it:

### 1. From the Root Directory
```bash
# Start development server
npm run web:dev

# Build for production
npm run web:build
```

### 2. From this Directory
```bash
# Direct access (ensure root dependencies are installed)
npm run dev
```

The app will be available at [http://localhost:3000](http://localhost:3000).

### Environment variables

`/login` and `/dashboard` need a Supabase project to talk to — the same
one the mobile app uses. Create `apps/web/.env.local` (gitignored, never
commit it) with:

```
NEXT_PUBLIC_SUPABASE_URL=https://<your-project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-anon-key>
```

Both values are also in `apps/mobile/.env` (`SUPABASE_URL`/`SUPABASE_ANON_KEY`)
under different variable names — it's the same Supabase project either
way. The `NEXT_PUBLIC_` prefix is required so Next.js exposes these to
the browser; that's expected for the anon key, which is meant to be
public (every table it can reach is protected by Row Level Security
server-side, not by keeping this key secret — see the mobile app's
`supabase/audit/table_checklist.md`).

---

## 🏗️ Architecture

```
src/
├── app/                  # Next.js App Router
├── components/           # Reusable UI components
├── lib/                  # Shared utilities and logic
└── messages/             # Localization files (next-intl)
```

---

## 🎨 Design System

Aligned with the mobile app's "Night-only" design system:

| Token | Value |
|---|---|
| Background | `#0D1117` |
| Primary | `#C8A96E` (Gold) |
| Secondary | `#3AAFA9` (Teal) |

---

## 🛠️ Development

- **Next.js 16.2**: Leveraging the latest App Router features.
- **next-intl**: Robust internationalization (Arabic/English).
- **TypeScript**: Type-safe development throughout.

---

<div align="center">

Made with ❤️ for the Muslim community

</div>
