---
name: lecture-player-playlist
description: Create and maintain a Lecture Player playlist (a CSV of talks worth watching) for one person, refreshed on a schedule. Use when asked to set up, refresh or tune their Lecture Player list.
---

# Lecture Player playlist skill

You maintain a learning playlist for one person. The Lecture Player app on
their phone reads a CSV file from a link and shows it as a list. You own that
file: you create it, keep it fresh, and keep it worth their time. The app does
nothing else, so the quality of the list is the product.

**What they want to learn:** {{TOPICS}}

If anything here conflicts with what the person tells you, follow the person.

## 1. Set up (first run only)

1. **Ask at most two short questions**, only if the topics above are too broad
   to search well: e.g. "Which of these matter most right now?" and "Any
   channels or people you already trust?" Otherwise skip straight to building.
2. **Pick where the file lives.** Use the first option you can actually write to:
   - **A public GitHub Gist** named `lecture-player.csv` (best: free, versioned,
     a stable raw link).
   - **A file in a public GitHub repo**, e.g. `playlist/lectures.csv`.
   - **A Google Sheet** with the columns below in the first tab, shared as
     "Anyone with the link → Viewer".
   The list must be readable without signing in, or the app can't load it.
   It holds only public links, so this is safe; say so if they ask.
3. **Fill it** with 15–25 items following the rules in section 3.
4. **Schedule the refresh** (section 2) as a recurring task, weekly by default.
   If you can't schedule tasks, tell them: "Send me 'refresh my Lecture Player
   list' once a week and I'll do it."
5. **Reply with exactly this**, so they can paste the link into the app:

   > Your Lecture Player list is ready: <link to the file or sheet>
   > In the app, tap **Connect my list** and paste that link.
   > I'll add new talks every <day>.

   The app accepts a Gist page, a GitHub file page, a raw link or a Google
   Sheet link, so give whichever is natural.

## 2. Refresh (every scheduled run)

1. Read the current file.
2. Find 3–8 new items that pass section 3 and are not already in the file
   (compare by video ID / canonical URL, not title).
3. **Add new rows at the top**, with `Added` = today. Never delete or reorder
   existing rows; the person may be partway through them. The app shows how
   recently you added something, so a run that adds nothing looks to them like
   you stopped working.
4. If you truly found nothing good, add nothing and say why in your run notes.
   Never pad with weak items.
5. If the file has grown past 150 rows, tell the person and suggest archiving
   the oldest 50 to a second file. Don't do it unasked.

## 3. What goes on the list

**Include**
- Public, free talks, lectures, podcast episodes and conference sessions
  that open without an account: YouTube (`https://www.youtube.com/watch?v=ID`),
  or a public podcast episode page.
- Depth over hype: practitioners explaining how they actually did something.
- Mostly 15–90 minutes. A few shorter ones help on short rides.

**Exclude**
- Paid course recordings, private or members-only links, anything behind
  a login, tracking or affiliate links.
- Clips, reaction videos, listicles, "top 10" videos, and more than two
  items from the same channel per run.

**Verify every link before writing it.** Open it, or find it in a search
result, and confirm the ID and the title match. Never write a video ID
from memory. A dead link on the list costs more trust than a missing one.

## 4. File format

UTF-8 CSV, comma-separated, header row exactly:

```
Link,Title,Why,Minutes,Added,Source
```

| Column  | Required | Rules |
|---------|----------|-------|
| Link    | yes | Canonical public URL. YouTube as `https://www.youtube.com/watch?v=ID`, no `&t=` or tracking parameters. |
| Title   | yes | Real title, under ~80 characters, keep the speaker's name. |
| Why     | yes | One sentence in your own words, under 90 characters: why *this person* should watch it. |
| Minutes | yes | Runtime, whole minutes. |
| Added   | yes | Date you added the row, `YYYY-MM-DD`. Drives "new" and "last updated" in the app. |
| Source  | no  | Short channel slug, e.g. `ycombinator`. |

Quote any field that contains a comma with double quotes. Example rows:

```
Link,Title,Why,Minutes,Added,Source
https://www.youtube.com/watch?v=VIDEO_ID,"Talk title | Speaker",Why this matters to you in one line,42,2026-11-12,channel-slug
```

The app also understands `Duplicate` (rows with `TRUE` are hidden) and ignores
any other column, so you may add your own bookkeeping columns.

## 5. Getting better over time

- If the person says "more like X", "less of Y" or "too long", record it at
  the top of your notes for this task and apply it on every later run.
- Every 4 weeks, in one or two lines, tell them what you've added and ask if
  the mix is still right. No more often than that.
