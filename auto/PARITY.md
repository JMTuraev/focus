# Telegram Desktop parity

Status: `OK` matches, `DIFF` differs (do it), `PR` fix in an open PR, `?` not verified yet (check the code and update).
References: put screenshots of Telegram Desktop in `auto/reference/` and name them after the row id.

| id | Telegram Desktop behaviour | Status | Notes |
|----|----------------------------|--------|-------|
| audio-1 | Voice message plays inside its own bubble (play/pause button, waveform, progress, time); no separate player screen or dialog | DIFF | reported by the user: pressing play opens a player-like UI instead of the Telegram bubble |
| audio-2 | Mini-player strip above the chat while audio plays (title, play/pause, close); stays when you switch chats | ? | `lib/ui/chats/voice_player.dart` is a singleton, check the UI |
| audio-3 | Playback speed toggle (1x / 1.5x / 2x) on voice messages | ? | |
| audio-4 | Next voice message in the chat starts automatically when one ends | ? | |
| audio-5 | Music files (not voice) show cover/title/artist row with inline play | ? | |
| media-1 | Photo viewer: arrows / keys move between photos of the chat | ? | |
| media-2 | Video plays inline with a progress bar, click opens the viewer | ? | |
| msg-1 | Reply preview on a message jumps to the original and highlights it | ? | |
| msg-2 | Hover on a message shows the time and the quick reaction/reply buttons | ? | |
| msg-3 | Date separators ("Today", "Yesterday") between days | ? | |
| msg-4 | Link preview card under messages with a link | ? | |
| list-1 | Chat list shows the last message sender, draft, and message status ticks | ? | |
| comp-1 | Composer remembers the draft per chat | ? | |
| comp-2 | Ctrl+V pastes an image from the clipboard into the send dialog | ? | |
