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

## First run: built for your agent

A new user never sees an empty screen or a CSV field:

1. **Pick topics** (Product, AI, Startups, Engineering) and get a hand-picked
   starter list of public talks immediately (`starter/*.csv`, bundled in the app).
2. **Connect my agent** hands the playlist skill
   ([`agent-kit/SKILL.md`](agent-kit/SKILL.md)) to Claude, ChatGPT, Grok or any
   agent, with the user's topics filled in. The agent creates a public list
   (Gist, GitHub file or Google Sheet), fills it, schedules a weekly refresh and
   replies with the link.
3. **Paste the link.** The app accepts Sheet, Gist, GitHub-file or raw links,
   checks the file and says exactly what to fix if it can't load it.
4. **Stays fresh.** The home screen shows "updated 2 days ago · 5 new" from the
   `Added` dates the agent writes, and nudges the user to re-share the skill if
   nothing has been added for 10 days.

Existing installs that already have a playlist URL skip all of this.

## Setup

1. Clone the repo
2. Run `flutter pub get`
3. Build and install on Android: `flutter run`
4. In Settings, paste the playlist URL:
   `https://raw.githubusercontent.com/Nerupudinho/lecture-player/master/playlist/lectures.csv`

Any URL serving the same columns works — swap it for your own fork or a private
Gist if you'd rather not use this one.

### Playlist format

| Link | Title | Why | Minutes | Added | Source |
|------|-------|-----|---------|-------|--------|
| `https://www.youtube.com/watch?v=...` | Talk title | Why it's worth it | `42` | `2026-11-12` | `ycombinator` |

`Link` (or `URL`) and `Title` are required. `Why` and `Minutes` show under each
title. `Added` (`YYYY-MM-DD`) drives the "updated" and "new" line on the home
screen. Rows with `Duplicate = TRUE` are skipped, a repeated URL is shown once,
and any other column is ignored.

## How the playlist stays current

A scheduled job scans Gmail for course-recording and podcast emails, extracts the
canonical `/p/<slug>` URL, de-duplicates against the existing playlist, and commits
new rows. Because the playlist is a file in git, every addition is visible in the
commit history — if the job stops running, the gap is obvious.

## Stack

Flutter · Dart · SQLite · Android
