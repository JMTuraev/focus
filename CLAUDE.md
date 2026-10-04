# Focus — project rules

Unofficial, local-first Telegram desktop client for Windows (Flutter + TDLib). The app is called **Focus** (window title, `focus.exe`, all UI text). Internal names stay `fokus`: the Dart package, `Fokus*` classes, `fokus.sqlite`, the `#fokus_backup` tag and the `FOKUSBAK` format.

## Language
- All UI text is Uzbek (Latin script). Use the proper apostrophes `‘` (o‘, g‘) and `’` (tutuq belgisi: ma’lumot, so‘z), not a plain `'`.
- Code, identifiers, comments and commit messages are in English.
- Flutter's built-in texts use the Uzbek locale (`flutter_localizations`, `Locale('uz')`).

## Workflow
- UI-first: build every screen with mock data first (`lib/data/mock.dart`, `USE_MOCK=true`), then wire the backend.
- Do not change existing design or behaviour while fixing build/analyzer issues.
- `flutter analyze` must report no issues before every commit.

## Architecture
- No server. Telegram data comes only from TDLib (`lib/tdlib/`). Everything else (collections, tasks, notes, calendar) is stored locally (SQLite via drift, from phase 2).
- Backups are encrypted locally and uploaded to the user's own Saved Messages.
- TDLib binaries live in `tdlib/` (git-ignored), built by `.github/workflows/tdlib-windows.yml` and copied next to `focus.exe` by the CMake rule added by `tool/setup_windows.ps1`.

## Local mode (must never be broken)
Defined in `lib/tdlib/td_auth.dart` → `LocalMode`.
- Set option `online = false` right after authorization.
- Never call `viewMessages`, `sendChatAction`, `readAllChatMentions` (or `readAllChatReactions`). Opening a chat in Focus only clears the local badge.
- Known limit: sending a reply makes Telegram treat the chat as read.

## Palette and themes
Colors live in `lib/theme.dart` as `FokusColors` (light and dark variants). Read them with `final c = context.fc;`, never hard-code colors in widgets.
- Accent `#3390EC` (`c.accent`) for icons, strokes and non-text accents.
- `#2874C8` (`c.accentStrong`) for fills under white text.
- `c.accentText` for links and accent-colored text (lighter blue in dark mode).
- Every new color needs a light and a dark value.
- Theme mode (system, light, dark) is stored in `settings.json` by `lib/state/settings.dart`.

## Responsive layout
Breakpoints are in `lib/ui/layout.dart`, modelled on Telegram Desktop:
- wide (>= 1200 px): rail, chat list, chat, docked info panel;
- medium (800–1199 px): info panel slides over the chat;
- narrow (< 800 px): one column, chat list or chat with a back button.
`test/layout_test.dart` renders every layout in light and dark mode and must pass (`flutter test`).

## Login (phase 1)
- `lib/auth/auth.dart`: `AuthService` interface and login states. The UI only talks to this.
- `lib/auth/mock_auth.dart`: used when `USE_MOCK=true`. Any phone, any 5-digit code (`00000` fails), any password (`xato` fails).
- `lib/tdlib/td_auth.dart`: `TdAuth`, the real TDLib flow; maps TDLib errors to Uzbek text in `authErrorText`.
- The TDLib database is encrypted with a random 32-byte key protected by Windows DPAPI (`lib/tdlib/db_key.dart`, file `tdlib/db.key` in the app support folder).
- Never log, print or store the phone number, login code, password or database key.
- Real TDLib run: `flutter run -d windows --dart-define-from-file=secrets.json --dart-define=USE_MOCK=false`.

## Chats (phase 1)
- `lib/data/chat_source.dart`: `ChatSource` (chats, messages, send, history) and `ChatSession`. UI and `AppState` only use this.
- `lib/data/mock_source.dart` wraps the mock data; `lib/tdlib/td_chats.dart` (`TdChatSource`) builds chats from TDLib `update*` objects.
- `TdChatSource` talks to TDLib through `TdApi`, so `test/td_chats_test.dart` can drive it with a fake.
- Focus-only data (collections, chat assignments, unread already seen in Focus) lives in `lib/data/local_store.dart`: held in memory, written in order to the drift tables `collections`, `chat_collections`, `seen_counts` (schema v4). The old `local_state.json` is imported once (flag `localStateImported` in `key_values`) and kept as `local_state.json.bak`.
- `openChat`/`closeChat`/`getChatHistory` are allowed; anything that marks messages as read is not.

## Collections and filters
- Collections are Focus-only (`LocalStore`): create, rename, change icon, delete, reorder. Deleting a collection makes its chats unsorted; nothing is ever changed in Telegram.
- `AppState.collectionOf` returns '' for unsorted chats or chats of a deleted collection.
- "To‘plamlar" screen (`lib/ui/collections/`): collection cards and the "Saralanmagan" list with type tabs and bulk moves. Chats move by right click in the chat list, the info panel chips, or the unsorted list.
- The rail holds only the modules. Collections are tabs above the chat list (`_CollectionTabs` in `chat_list.dart`): click filters, right click edits or deletes, + adds. The tabs are a `Row` in a scroll view, not a lazy `ListView`, so every tab exists for `ensureVisible`.
- Filters: waiting / unread chips plus the chat type filter (Shaxsiy, Guruhlar, Kanallar, Botlar) and "hide muted"; the chips count within the type filter.

## Local database (phase 2)
- drift + SQLite: `lib/db/database.dart` (`AppDatabase`, file `fokus.sqlite` in the app support folder; in memory for mock sessions and tests). Generated code: `lib/db/database.g.dart`, committed.
- After changing tables run `dart run build_runner build --delete-conflicting-outputs --force-jit` (the AOT mode fails because of native build hooks) and bump `schemaVersion` with a migration.
- Enums are stored by name (`textEnum`), never by index.
- Stores (e.g. `TaskStore`) keep rows in memory and reload after each write; no drift streams (they leave timers that break widget tests).

## Tasks
- `lib/tasks/task_store.dart`; board in `lib/ui/tasks/`. Columns: Rejada, Jarayonda, Kutilmoqda, Bajarildi. Order inside a column is `position` (insert-before uses the midpoint).
- "Vazifa qilish" in a chat creates a task from the selected or latest incoming message and keeps the chat id, chat title and message text.

## Calendar
- `lib/calendar/event_store.dart` (`Events` table, schema v2 with a migration from v1); grid in `lib/ui/calendar/`: week on wide windows, day on narrow ones, tasks with a due date in the all-day row.
- Events: click an empty slot to add; drag to move (15 min / day snapping, mouse); drag the bottom edge to resize; right click for a menu.
- Meetings in messages: `lib/data/meeting_parser.dart` (Uzbek Latin/Cyrillic and Russian). It needs both a day and a time; relative days count from the message date; only meetings that have not passed are offered. Add every new phrase to `test/meeting_parser_test.dart`.
- "Kalendarga" adds a detected meeting at once (1 hour, reminder 30 min before); without one it opens the editor prefilled from the message.

## Reminders (notifications)
- `lib/reminders/`: `ReminderService` keeps Windows scheduled toasts in line with meetings (`remindBefore`) and open tasks with a due date (at `Settings.taskReminderHour`). Ids: 100000000 + event id, 200000000 + task id. Payloads `event:ID` / `task:ID` open the calendar or the tasks board.
- Windows keeps scheduled toasts, so they fire when Focus is closed. App identity (`appUserModelId`, `guid` in `notifier.dart`) must never change.
- Building needs the Visual Studio component "C++ ATL" (`Microsoft.VisualStudio.Component.VC.ATL`) for flutter_local_notifications_windows.
- Settings dialog (rail ⚙): theme (system / light / dark), reminders on/off, task reminder hour, test notification, backup.

## Windows runner
- `windows/runner/main.cpp` allows one instance (named mutex): a second start brings the running window to the front and exits, because two instances would fight over the TDLib database. Close the app before `flutter run`.
- `Runner.rc` `CompanyName` (`com.example`) and `ProductName` (`fokus`) decide the data folder `%APPDATA%\com.example\fokus` (TDLib session, `fokus.sqlite`, keys). Never change them without moving that folder first, or users lose their login and local data.
- Local install: `tool/install_local.ps1` builds a release, copies it to `%LOCALAPPDATA%\Programs\Focus` and puts a "Focus" shortcut on the desktop.

## Notes
- `lib/notes/note_store.dart` (`Notes` table, schema v3); screen and editor in `lib/ui/notes/`. Text notes or checklists (items as JSON via `NoteItemsConverter`), 7 colors (`FokusColors.noteColors`, `NoteColor` order), pinning.
- The editor saves when it closes, however it is closed (button, Escape, click outside); an empty new note is not saved.
- "Eslatmaga" in a chat saves the message as a note linked to the chat.
- Dates are stored with 1 second precision; do not rely on finer ordering.

## Messages: formatting and media
- Text entities are mapped in `TdChatSource.entitiesOf` and drawn by `lib/ui/chats/message_text.dart`. Links open only for http, https, mailto, tel and tg; hidden links (`textUrl`) ask for confirmation first.
- Media (`MediaInfo`): photos and video thumbnails download automatically; videos and voice messages download on click. Playback uses media_kit (libmpv), which adds about 45 MB to the build.
- Media viewers must stay closable by mouse and Escape and must not cover the title bar close button.

## Sending files and emoji
- 📎 or dragging files from Explorer (`desktop_drop`) opens `send_files_dialog.dart`: files, "Rasmlarni siqib yuborish", caption (text already typed in the composer becomes the caption).
- `lib/data/send_plan.dart` decides how files go: images that fit Telegram's photo limits as `inputMessagePhoto` with width and height, the rest as `inputMessageDocument`; photos first, albums of at most 10 (`sendMessageAlbum`); caption on the first file; captions over 1024 characters go first as a text message.
- Documents in messages (`FileRow` in `file_actions.dart`): click downloads, then opens with the Windows app; right click: open, show in folder, save elsewhere. Programs and scripts (`isRiskyFile`) ask before opening. Upload progress comes from `remote.uploaded_size`.
- Emoji: `emoji_picker_flutter` panel above the composer (Segoe UI Emoji); Escape or the keyboard button closes it.

## Backup (phase 3)
- `lib/backup/`: `BackupService` takes a snapshot of `fokus.sqlite` (`VACUUM INTO` + gzip), encrypts it and uploads it to the user's own Saved Messages as a document whose caption starts with `#fokus_backup`. Only that chat is touched.
- Crypto (`backup_crypto.dart`): Argon2id (64 MiB, t=3) from the backup password, AES-256-GCM. File format `FOKUSBAK` v1; the header (KDF params, salt, nonce) is the AAD. Never change the format without a new version number.
- The derived key is kept on this PC in `backup.key` (DPAPI), outside the database, so backups need no password here. Restoring a backup with another salt asks for its password. The password itself is never stored.
- Restore (`snapshot.dart`): refuse newer schemas, run migrations on the backup copy, then `ATTACH` it and copy every table with explicit columns in one transaction. Then `AppState.reloadLocalData()`. The local `backupLastAt` and `backupAuto` values win over the backup.
- TDLib transport (`lib/tdlib/td_backup.dart`): `inputMessageDocument.document` is an `inputDocument` that wraps the `InputFile` (TDLib 1.8.6x). Check `td_api.tl` for the pinned commit before changing any TDLib call.
- Daily automatic backup runs while Focus is open (checked hourly). Settings → "Zaxira nusxa".

## Donations (phase 3)
- `lib/ui/donate_dialog.dart`, opened by the heart in the title bar (also on the login screen) and from Settings → "Focus haqida".
- Payment details come from build-time defines in `secrets.json` (`DONATE_CARD`, `DONATE_CARD_HOLDER`, `DONATE_CARD_LABEL`, `DONATE_PAYME_URL`, `DONATE_CLICK_URL`, `DONATE_TIRIKCHILIK_URL`, `DONATE_OTHER_URL`, `DONATE_OTHER_LABEL`, `DONATE_TELEGRAM_URL`; see `secrets.example.json`), read by `lib/donate/donate_info.dart`. Never hard-code them. Empty or invalid values are hidden; only https links are opened; card numbers must be 12–19 digits.
- Donations are voluntary and never unlock a feature (also a Microsoft Store requirement for external payment links in non-game apps).
- GitHub star and issue links use `AppConfig.repoUrl`.

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
flutter test
dart run build_runner build --delete-conflicting-outputs --force-jit
flutter build windows --debug
flutter run -d windows --dart-define-from-file=secrets.json
dart run tool\td_check.dart tdlib\tdjson.dll
```
