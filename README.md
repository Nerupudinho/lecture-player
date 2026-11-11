# Lecture Player

A Flutter Android app for commute learning. Displays lectures from a CSV playlist and opens them externally in YouTube or your browser. Clean title list, one-tap playback, shuffle for randomness. No ads, no algorithm, no distractions — just your content.

## Why

Commute time was being wasted on passive YouTube browsing. This app lets you deliberately consume learning content on the go without getting pulled into the feed.

## Features

- A clean, flat list of your lecture titles — tap any to open in YouTube or your browser, or Shuffle for a random one
- Playback is external (YouTube app, browser) — the app is a launcher, not an embedded player
- Playlist lives in this repo at [`playlist/lectures.csv`](playlist/lectures.csv) as a CSV file
- Course recordings (Maven and instructors' own domains) plus PM podcast episodes
- Email tracking links are decoded automatically to clean, playable URLs
- Rows flagged `Duplicate = TRUE` are skipped
- Zero ads, zero tracking, zero cost to run

## Setup

1. Clone the repo
2. Run `flutter pub get`
3. Build and install on Android: `flutter run`
4. In Settings, paste the playlist URL:
   `https://raw.githubusercontent.com/Nerupudinho/lecture-player/master/playlist/lectures.csv`

Any URL serving the same columns works — swap it for your own fork or a private
Gist if you'd rather not use this one.

### Playlist format

| Link | Title | Duplicate | Source | Added |
|------|-------|-----------|--------|-------|
| `https://maven.com/p/...` | Lecture title | `FALSE` | `maven` | `2026-08-04` |
| `https://www.lennysnewsletter.com/p/...` | Podcast episode | `FALSE` | `lennys-podcast` | `2026-08-04` |

`Link` (or `URL`) and `Title` are required; `Duplicate` is optional. `Source` and
`Added` are bookkeeping for the sync job — the app ignores them, along with any
other extra column.

## How the playlist stays current

A scheduled job scans Gmail for course-recording and podcast emails, extracts the
canonical `/p/<slug>` URL, de-duplicates against the existing playlist, and commits
new rows. Because the playlist is a file in git, every addition is visible in the
commit history — if the job stops running, the gap is obvious.

## Stack

Flutter · Dart · SQLite · Android
