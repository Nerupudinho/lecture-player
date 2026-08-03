import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_player/services/csv_parser_service.dart';

/// Guards the shipped playlist itself, not just the parser.
///
/// The playlist is written by an automated sync job, so a malformed row would
/// otherwise only surface as an empty or broken list on the phone. These tests
/// fail loudly in CI instead.
void main() {
  final file = File('playlist/lectures.csv');
  final parser = CsvParserService();

  test('shipped playlist exists and parses', () {
    expect(file.existsSync(), isTrue,
        reason: 'playlist/lectures.csv is the app\'s default source');

    final videos = parser.parse(file.readAsStringSync());
    expect(videos, isNotEmpty);
  });

  test('every playable row has a title and an absolute http(s) URL', () {
    final videos = parser.parse(file.readAsStringSync());

    for (final v in videos) {
      expect(v.title.trim(), isNotEmpty,
          reason: 'blank title renders as a raw URL in the list');
      expect(v.url, startsWith('http'),
          reason: 'url_launcher needs an absolute URL: ${v.url}');
    }
  });

  test('no tracking wrappers survive into the playlist', () {
    final raw = file.readAsStringSync();

    for (final marker in ['/e/c/', 'link.courses.maven.com', 'kit-mail3.com']) {
      expect(raw.contains(marker), isFalse,
          reason: '$marker should have been decoded before commit');
    }
  });

  test('no duplicate URLs among playable rows', () {
    final videos = parser.parse(file.readAsStringSync());
    final urls = videos.map((v) => v.url).toList();

    expect(urls.toSet().length, urls.length,
        reason: 'the sync job de-duplicates by canonical key');
  });
}
