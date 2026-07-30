# Masged Unified Mobile App

Single Flutter app for **parent**, **teacher**, and **guest** (shared Quran, prayer times, mosque, zikr, news).

## Run

```bash
flutter run
```

API host is configured in `lib/core/constants/app_constants.dart` (same host for parent and teacher; teacher routes use `/api/teacher/*`).

## Structure

- `lib/features/auth/` — splash, unified login (parent / teacher / guest)
- `lib/features/parent/` — parent-only screens
- `lib/features/teacher/` — teacher-only screens
- `lib/features/shared/` — Quran, prayer, mosque, zikr, news
- `lib/core/` — shared theme, validators, mosque/prayer/Quran helpers
- `lib/teacher_core/` — teacher-specific API envelope client and auth storage

The old **TeacherApp** folder was removed; use this project only.
