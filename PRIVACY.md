# Privacy Policy for Lecture Player

**Effective Date:** 2026-10-06

## Summary

Lecture Player does not collect, transmit, or share any personal data. The app is designed to respect your privacy completely.

## Data Collection

**Lecture Player does not collect any personal information.**

The app does not:
- Collect personal data (name, email, phone number, etc.)
- Track your location
- Access your contacts, photos, or other device data
- Use analytics services or crash reporting
- Display advertisements
- Transmit any data to our servers

## Data Stored Locally

The app stores the following data **only on your device**:

1. **Playlist data**: Video titles and URLs from the CSV playlist you configure
2. **Settings**: The playlist source URL and the timestamp of the last refresh

This data is stored in a local SQLite database and is never transmitted anywhere.

## Network Requests

The app makes the following network requests:

1. **Playlist fetch**: When you refresh the playlist, the app downloads the CSV file from the URL you configured (default: a public GitHub raw file URL). This request is a simple HTTP GET and does not include any personal or device information.

2. **External video playback**: When you tap a video, the app opens the URL in an external application (typically YouTube or your web browser). The external app's privacy policy applies to that playback.

## Third-Party Services

The app itself does not integrate any third-party services, SDKs, or analytics. However:

- Video playback happens in external apps (YouTube, web browser), which have their own privacy policies
- If you configure a playlist URL that you control, that server would see the request (your IP address)

## Children's Privacy

The app does not knowingly collect any information from anyone, including children under 13.

## Changes to This Policy

If this privacy policy changes, the updated version will be available in the app's repository.

## Contact

For questions about this privacy policy, please open an issue in the app's GitHub repository.
