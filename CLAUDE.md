# Fokus — project rules

Unofficial, local-first Telegram desktop client for Windows (Flutter + TDLib). Dart package name: `fokus`.

## Language
- All UI text is Uzbek (Latin script). Use the proper apostrophes `‘` (o‘, g‘) and `’` (tutuq belgisi: ma’lumot, so‘z), not a plain `'`.
- Code, identifiers, comments and commit messages are in English.

## Workflow
- UI-first: build every screen with mock data first (`lib/data/mock.dart`, `USE_MOCK=true`), then wire the backend.
- Do not change existing design or behaviour while fixing build/analyzer issues.
- `flutter analyze` must report no issues before every commit.

## Architecture
- No server. Telegram data comes only from TDLib (`lib/tdlib/`). Everything else (collections, tasks, notes, calendar) is stored locally (SQLite via drift, from phase 2).
- Backups are encrypted locally and uploaded to the user's own Saved Messages.
- TDLib binaries live in `tdlib/` (git-ignored), built by `.github/workflows/tdlib-windows.yml` and copied next to `fokus.exe` by the CMake rule added by `tool/setup_windows.ps1`.

## Local mode (must never be broken)
Defined in `lib/tdlib/td_auth.dart` → `LocalMode`.
- Set option `online = false` right after authorization.
- Never call `viewMessages`, `sendChatAction`, `readAllChatMentions` (or `readAllChatReactions`). Opening a chat in Fokus only clears the local badge.
- Known limit: sending a reply makes Telegram treat the chat as read.

## Palette
Use the constants in `lib/theme.dart` (`FC`), never hard-coded colors.
- Accent `#3390EC` for icons, strokes and non-text accents.
- `#2874C8` (`FC.accentStrong`) for fills under white text and for links.

## Phases
0. Skeleton: mock UI, TDLib FFI layer, Windows build, TDLib CI build.
1. Login (phone → code → 2FA password), chat list and messages from TDLib, collections, filters, TDLib database encrypted with a DPAPI-protected key.
2. Tasks, calendar, reminders.
3. Encrypted backup to Saved Messages, donation screen, Microsoft Store release.
4. File AI and statistics.

## Secrets
- Telegram `api_id` / `api_hash` live only in `secrets.json` (git-ignored; template: `secrets.example.json`).
- Pass them at build time only:
  `flutter run -d windows --dart-define-from-file=secrets.json`
- Never write the real values into code, docs, commit messages, logs or terminal output.
- Before every commit run `git check-ignore secrets.json` and check `git status` to make sure it is not staged.

## Common commands
```powershell
flutter pub get
flutter analyze
flutter build windows --debug
flutter run -d windows --dart-define-from-file=secrets.json
dart run tool\td_check.dart tdlib\tdjson.dll
```
