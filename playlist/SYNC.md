# Playlist sync runbook

How `lectures.csv` stays current. Read this before changing the sync — most of
it is here because the obvious approach failed.

## What gets added

A row is added when an email contains a link to a **recording or podcast
episode** — something you can actually watch or listen to on a commute.

Included:
- Course recordings: Maven (`maven.com/p/<id>`) from any sender
- PM podcast episodes (`<publication>/p/<slug>`)

Excluded:
- Upcoming-event confirmations ("⚡️ You're in —") — no recording exists yet
- Daily audio briefs (GenAI PM Daily's "3 min listen") — churns the list
- Text newsletters with no episode

## Match on content, not sender

The original Apps Script filtered by sender (`maven.com`, `hellopm.co`). That
was the wrong axis and it is why the pipeline missed most of what mattered:

- Course recordings arrive from instructors' own domains
  (`theuncommonexecutive.com`, `crossingcareerchasms.com`, `ethanevans.com`).
- **Sender does not imply publication.** Lenny cross-posts The Skip; Ben Erez
  (`benerez@substack.com`) publishes his podcast under
  **`suprainsider.substack.com`**.

So: look for a `/p/<slug>` link on a known course or publication domain, plus
post-event framing in the surrounding text. Do not maintain a sender allowlist.

## Resolving a title to a canonical URL

Gmail cheaply gives subject + date; the canonical URL is only in the body, and
bodies are ~100 KB each. Fetching every body does not scale. Use this order:

1. **Sitemap slug match** — `https://<domain>/sitemap.xml` lists every post
   (Lenny's has 1,216). Match slug tokens against title tokens; require ~85%
   of slug tokens to appear in the title. Resolves roughly 60%.
2. **Substack search API** —
   `https://<domain>/api/v1/archive?sort=new&limit=8&search=<query>`
   Returns exact `title` + `canonical_url`. Resolves most of the rest.
3. **Slug-prefix probing** — build `.../p/<first-N-title-tokens>` and HEAD-check,
   shrinking N. Substack truncates slugs, so this catches many.
4. **Email body** — last resort, authoritative. First plaintext `/p/` link is
   the canonical URL. For cross-posts the link is HTML-only, as
   `open.substack.com/pub/<pub>/p/<slug>` → normalise to
   `https://<pub>.substack.com/p/<slug>`.

**Slug matching alone is not sufficient.** Product Growth's slugs are
hand-written and unrelated to titles:

| Title | Slug |
|---|---|
| How to Build Frontier-Lab Quality Evals with Daniel McKinnon | `/p/how-to-build-your-first-eval` |
| The PM's Guide to Governance with Eric Ries | `/p/eric-ries-incorruptible` |

Titles also drift from slugs on Lenny's ("The **hidden** pattern behind
successful products" → `/p/the-**common**-pattern-behind-successful`).

## Gotchas

- **HTTP 429 is not a dead link.** A parallel HEAD sweep reported 26 dead; all
  26 were self-inflicted rate limiting and returned 200 on sequential retry.
  Always retry with backoff before marking anything dead. Keep concurrency ≤ 3.
- **The archive API is a filtered public subset** — it returned 60 posts over 16
  months with no podcast metadata. Do not use it to enumerate history.
- **RSS caps at 20 items.** Fine for a weekly delta, useless for backfill.
- **Cross-source duplicates exist.** The Jessica Fain episode is in the playlist
  as both a YouTube link and a Substack link. URL-key dedup cannot see these;
  they need a title check. The Substack one is flagged `Duplicate=TRUE`.

## Dedup

Canonical key, in order: `maven.com/p/<id>` → `<publication>/p/<slug>` →
YouTube video id → URL without query string. Prefer a `Duplicate=FALSE` row over
a `TRUE` one when collapsing, so a playable entry is never hidden by its dupe.

## Columns

`Link,Title,Duplicate,Source,Added,Published` — the app reads only the first
three and ignores the rest (see `test/csv_parser_test.dart`). `Source`, `Added`,
and `Published` are bookkeeping for this job.

| Column | Description |
|--------|-------------|
| Link | Canonical playable URL |
| Title | Episode/session title |
| Duplicate | `TRUE` if another row has the same content |
| Source | Domain or shorthand for the source (e.g. `maven`, `lennys-podcast`) |
| Added | Date row was ingested (may be blank for older rows) |
| Published | Actual publication date (`YYYY-MM-DD`) from the source page |

## Published column

The `Published` column holds the actual publication/upload date, **not** the
ingest date. This is required for sorting the playlist newest-first.

**How to populate for new entries:**

1. **YouTube** — scrape `dateText` from the page JSON (e.g. `"Mar 22, 2026"`)
2. **Substack** (`lennysnewsletter.com`, `news.aakashg.com`, `theskip.substack.com`,
   `thehellopm.substack.com`, `suprainsider.substack.com`, etc.) — extract
   `datePublished` from JSON-LD `<script type="application/ld+json">`
3. **Maven** (`maven.com/p/<id>`) — extract `uploadDate` from JSON-LD when available
4. **Other sources** — try JSON-LD or meta tags; if no date is discoverable,
   leave `Published` blank

See `scripts/fetch_dates.py` for the extraction logic.

## Sort order

**The CSV must be sorted by Published date, newest first.** Rows without a
Published date go at the bottom. This ensures the phone app displays
latest-published lectures at the top.

When adding new rows:
1. Fetch the Published date using the methods above
2. Insert the row in the correct position to maintain sort order

## After changing anything

Run `flutter test`. `test/playlist_file_test.dart` guards the shipped file:
blank titles, non-absolute URLs, surviving tracking wrappers, duplicate URLs.
