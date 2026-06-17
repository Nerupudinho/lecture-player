# Lecture Player

A Flutter Android app for commute learning. Aggregates YouTube playlists and lecture recordings into a single player with a clean title list and one-tap random playback. No ads, no algorithm, no distractions — just your content.

## Why

Commute time was being wasted on passive YouTube browsing. This app lets you deliberately consume learning content on the go without getting pulled into the feed.

## Features

- A clean, flat list of your lecture titles — tap any to play, or Shuffle for a random one
- Playlist synced from a **Google Sheet** — paste the sheet's CSV URL in Settings; auto-syncs on every launch (plus pull-to-refresh)
- Maven email tracking links are decoded automatically to clean, playable URLs
- Rows flagged `Duplicate = TRUE` are skipped
- Zero cost to run

## Setup

1. Clone the repo
2. Run `flutter pub get`
3. Build and install on Android: `flutter run`
4. Make your Google Sheet shareable: **Share → General access → Anyone with the link → Viewer**
5. In Settings, paste the sheet's CSV export URL:
   `https://docs.google.com/spreadsheets/d/<SHEET_ID>/gviz/tq?tqx=out:csv&gid=0`

### Sheet format

| Link | Title | Duplicate |
|------|-------|-----------|
| `https://maven.com/p/...` (or a Maven tracking link) | Lecture title | `FALSE` |

The `Link` (or `URL`) and `Title` columns are required; `Duplicate` is optional. Any other columns are ignored.

## Stack

Flutter · Dart · SQLite · Android
