# Google Play Store Checklist

This document covers everything needed to publish Lecture Player on Google Play.

## App Details

### Short Description (≤80 characters)

```
Play lecture videos on your commute. Opens YouTube externally. No ads.
```

### Full Description

```
Lecture Player is a simple, distraction-free app for commute learning. It displays a flat list of lecture titles from a CSV playlist and opens each video externally in YouTube or your browser.

KEY FEATURES:
• Clean list of lecture titles — tap any to play
• Shuffle button for random selection
• Pull-to-refresh to update your playlist
• Videos open in YouTube app or browser — no embedded player
• Zero ads, zero tracking, zero distractions

HOW IT WORKS:
The app fetches a CSV playlist from a URL you configure. The default playlist lives in the app's GitHub repository, but you can use any URL serving the same format. Playback happens externally — when you tap a lecture, it opens in YouTube or your web browser.

PLAYLIST FORMAT:
Your CSV needs columns: Link (or URL), Title, and optionally Duplicate.
- Link: The video URL (YouTube, Maven, podcast sites)
- Title: What appears in the list
- Duplicate: Set to TRUE to skip the row

The app stores your playlist locally so it works offline (though you still need internet to watch videos).

FREE & OPEN SOURCE:
No ads, no in-app purchases, no data collection. The source code is available on GitHub under the MIT License.
```

## Store Listing Assets

### Required Graphics

| Asset | Size | Status | Notes |
|-------|------|--------|-------|
| App icon | 512×512 PNG | ✅ `store/play_icon_512.png` | High-res icon for Play Store |
| Feature graphic | 1024×500 PNG | ✅ `store/feature_graphic_1024x500.png` | Displayed at top of store listing |
| Phone screenshots | 16:9 or 9:16, min 320px | ❌ **You must add** | 2-8 screenshots required |
| 7" tablet screenshots | Optional | ❌ Not created | Recommended if app looks good on tablets |
| 10" tablet screenshots | Optional | ❌ Not created | Recommended if app looks good on tablets |

### Screenshot Guidelines

Take screenshots showing:
1. Home screen with lecture list
2. Shuffle button interaction
3. Settings screen with playlist URL
4. Player screen showing "Opened externally" state

Use a Pixel device or emulator for clean status bar. Screenshots should be at least 320px on short side, max 3840px on long side.

## Content Rating

### IARC Rating Questionnaire

When completing the content rating questionnaire:

- **Violence**: None
- **Sexual content**: None
- **Profanity**: None
- **Controlled substance references**: None
- **User-generated content**: Yes (technically — user provides their own playlist URL, but content plays externally)
- **Personal info collection**: No
- **Location data**: No
- **Ad content**: No

Expected rating: **Rated for 3+** (Everyone)

Since videos open externally in YouTube/browser, the external app's content rating applies to video content.

## Data Safety Section

### Data Types

Answer the following in Play Console's Data Safety section:

| Question | Answer |
|----------|--------|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS for playlist fetch) |
| Do you provide a way for users to request that their data is deleted? | **N/A** — no data collected |

### Data Collected

| Data Type | Collected? | Shared? | Notes |
|-----------|-----------|---------|-------|
| Personal info | No | No | |
| Financial info | No | No | |
| Location | No | No | |
| Contacts | No | No | |
| User content | No | No | |
| App activity | No | No | |
| Device/identifiers | No | No | |

### Privacy Policy

Link to: `https://github.com/Nerupudinho/lecture-player/blob/master/PRIVACY.md`

(Update the URL if you move the repository or host the policy elsewhere)

## Closed Testing Requirements (New Personal Accounts)

Google requires new personal developer accounts to:

1. **Run a closed test** with at least **12 testers** who have **opted in**
2. Testers must be active for **14 continuous days**
3. After 14 days, you can apply for production access

### Steps

1. **Create closed testing track** in Play Console → Release → Testing → Closed testing
2. **Create a tester list** — add 12+ email addresses
3. **Upload your AAB** to the closed testing track
4. **Share opt-in link** with testers (they must click it and accept)
5. **Wait 14 days** from when the last of 12 testers opts in
6. **Apply for production** access once requirements are met

### Finding Testers

- Friends and family
- Communities (Reddit, Discord, dev communities)
- Professional beta testing services (optional, paid)

## Build Commands

### Prerequisites

1. **Create your keystore** (one-time):
   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks \
     -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

2. **Create `android/key.properties`** from the example:
   ```bash
   cp android/key.properties.example android/key.properties
   # Then edit key.properties with your actual values
   ```

### Build Signed Release APK (for GitHub Releases)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build Signed Release AAB (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Verify the Build

```bash
# Check APK signing
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk

# Check AAB contents
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=test.apks --mode=universal
```

## Pre-Upload Checklist

- [ ] `applicationId` confirmed (cannot change after first upload)
- [ ] Version code incremented for each upload (`pubspec.yaml` → `version: x.y.z+N`)
- [ ] Release signed with upload keystore (not debug)
- [ ] Screenshots captured (2-8 phone screenshots minimum)
- [ ] Privacy policy URL is live and accessible
- [ ] Content rating questionnaire completed
- [ ] Data safety form completed
- [ ] Short description ≤80 characters
- [ ] Full description completed
- [ ] Contact email set in Play Console

## Important Notes

### Application ID

The `applicationId` (`io.github.nerupudinho.lectureplayer`) is set in `android/app/build.gradle`. **You cannot change this after your first upload to Play Store.** Confirm this is the ID you want before uploading.

If you need a different ID:
1. Edit `applicationId` in `android/app/build.gradle`
2. Update `namespace` in the same file to match
3. Move Kotlin files to match the new package path

### Keystore Security

- **Never commit** your keystore (`.jks`) or `key.properties` to git
- **Back up** your keystore securely — losing it means you can't update your app
- Consider Google's **Play App Signing** to let Google manage the app signing key

### Version Management

In `pubspec.yaml`:
```yaml
version: 1.0.0+1
         ^^^^^  ^
         |      versionCode (increment for each Play upload)
         versionName (user-visible version)
```

Increment `versionCode` (the number after `+`) for every Play Store upload.
