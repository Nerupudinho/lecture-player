import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_player/data/models/video_model.dart';
import 'package:lecture_player/services/agent_kit.dart';
import 'package:lecture_player/services/csv_parser_service.dart';
import 'package:lecture_player/services/list_check.dart';
import 'package:lecture_player/services/source_link.dart';
import 'package:lecture_player/services/starter_catalog.dart';
import 'package:lecture_player/shared/freshness.dart';

const _csv = 'Link,Title,Why,Minutes,Added,Source\n'
    'https://www.youtube.com/watch?v=aaa,"A talk, with comma",Worth it,42,2026-11-10,yc\n'
    'https://www.youtube.com/watch?v=bbb,Another,,abc,not-a-date,\n'
    'https://www.youtube.com/watch?v=aaa,Duplicate of first,,,,\n';

void main() {
  group('CsvParserService optional columns', () {
    final parser = CsvParserService();

    test('reads Why, Minutes and Added', () {
      final v = parser.parse(_csv).first;
      expect(v.title, 'A talk, with comma');
      expect(v.why, 'Worth it');
      expect(v.minutes, 42);
      expect(v.added, '2026-11-10');
    });

    test('bad Minutes and Added become null, not errors', () {
      final v = parser.parse(_csv)[1];
      expect(v.why, isNull);
      expect(v.minutes, isNull);
      expect(v.added, isNull);
    });

    test('a repeated URL is kept once', () {
      expect(parser.parse(_csv).length, 2);
    });

    test('inspect reports a missing Link column', () {
      expect(parser.inspect('Title\nfoo\n').hasLinkColumn, isFalse);
    });
  });

  group('SourceLink.normalize', () {
    test('Google Sheets edit link becomes CSV export, keeping the tab', () {
      expect(
        SourceLink.normalize(
            'https://docs.google.com/spreadsheets/d/ABC123/edit#gid=42'),
        'https://docs.google.com/spreadsheets/d/ABC123/export?format=csv&gid=42',
      );
      expect(
        SourceLink.normalize(
            'https://docs.google.com/spreadsheets/d/ABC123/edit?usp=sharing'),
        'https://docs.google.com/spreadsheets/d/ABC123/export?format=csv',
      );
    });

    test('published-to-web CSV links are left alone', () {
      const published =
          'https://docs.google.com/spreadsheets/d/e/2PACX-x/pub?output=csv';
      expect(SourceLink.normalize(published), published);
    });

    test('GitHub file page becomes raw', () {
      expect(
        SourceLink.normalize(
            'https://github.com/me/repo/blob/main/playlist/lectures.csv'),
        'https://raw.githubusercontent.com/me/repo/main/playlist/lectures.csv',
      );
    });

    test('Gist page becomes its raw endpoint', () {
      expect(SourceLink.normalize('https://gist.github.com/me/abc123'),
          'https://gist.githubusercontent.com/me/abc123/raw');
    });

    test('raw links and junk pass through trimmed', () {
      const raw = 'https://raw.githubusercontent.com/me/r/main/x.csv';
      expect(SourceLink.normalize('  $raw '), raw);
      expect(SourceLink.normalize('not a link'), 'not a link');
    });
  });

  group('ListCheck', () {
    ListCheck withBody(String body) => ListCheck(fetch: (_) async => body);
    ListCheck failing(String error) =>
        ListCheck(fetch: (_) async => throw Exception(error));

    test('a good list connects and reports the count', () async {
      final r = await withBody(_csv).check('https://gist.github.com/me/x');
      expect(r.ok, isTrue);
      expect(r.message, 'Connected: 2 items.');
      expect(r.url, 'https://gist.githubusercontent.com/me/x/raw');
    });

    test('empty input and non-links fail with guidance', () async {
      expect((await withBody(_csv).check('  ')).ok, isFalse);
      expect((await withBody(_csv).check('hello')).message,
          contains('https://'));
    });

    test('a Google sign-in page explains how to share the Sheet', () async {
      final r = await withBody('<!DOCTYPE html><html>sign in')
          .check('https://docs.google.com/spreadsheets/d/X/edit');
      expect(r.ok, isFalse);
      expect(r.message, contains('Anyone with the link'));
    });

    test('a missing Link column shows the expected header', () async {
      final r = await withBody('Name,Url2\na,b\n').check('https://x.dev/a.csv');
      expect(r.message, contains(ListCheck.expectedHeader));
    });

    test('a header-only list asks the agent to run once', () async {
      final r = await withBody('Link,Title\n').check('https://x.dev/a.csv');
      expect(r.message, contains('empty'));
    });

    test('404 and 403 are explained', () async {
      expect(
          (await failing('Failed to fetch playlist: HTTP 404')
                  .check('https://x.dev/a.csv'))
              .message,
          contains('public'));
      expect(
          (await failing('Failed to fetch playlist: HTTP 403')
                  .check('https://x.dev/a.csv'))
              .message,
          contains('private'));
    });
  });

  group('Freshness', () {
    VideoModel item(String? added) =>
        VideoModel(title: 't', url: 'u$added', position: 0, added: added);
    final now = DateTime(2026, 11, 20);

    test('counts new items and labels the last update', () {
      final f = Freshness.of(
          [item('2026-11-19'), item('2026-11-15'), item('2026-10-01')],
          now: now);
      expect(f.newCount, 2);
      expect(f.lastAddedLabel, 'yesterday');
      expect(f.isStale, isFalse);
    });

    test('goes stale after the threshold', () {
      final f = Freshness.of([item('2026-11-05')], now: now);
      expect(f.daysSinceLastAdded, 15);
      expect(f.isStale, isTrue);
      expect(f.lastAddedLabel, '2 weeks ago');
    });

    test('lists without dates are neither fresh nor stale', () {
      final f = Freshness.of([item(null)], now: now);
      expect(f.hasDates, isFalse);
      expect(f.isStale, isFalse);
    });
  });

  group('Agent kit', () {
    final skill = File('agent-kit/SKILL.md').readAsStringSync();

    test('the skill has a topics slot and the app\'s exact header', () {
      expect(skill, contains('{{TOPICS}}'));
      expect(skill, contains('Link,Title,Why,Minutes,Added,Source'));
    });

    test('compose fills in topics and asks for the link back', () {
      final msg = AgentKit.compose(skill, ['AI', 'Product']);
      expect(msg, contains('AI, Product'));
      expect(msg, isNot(contains('{{TOPICS}}')));
      expect(msg, contains('reply with the link'));
    });
  });

  group('Starter lists', () {
    final parser = CsvParserService();

    for (final topic in StarterCatalog.topics) {
      test('${topic.id} ships, parses and is fully filled in', () {
        final file = File(topic.assetPath);
        expect(file.existsSync(), isTrue, reason: topic.assetPath);
        final videos = parser.parse(file.readAsStringSync());
        expect(videos.length, greaterThanOrEqualTo(8));
        for (final v in videos) {
          expect(v.url, startsWith('https://'));
          expect(v.title.trim(), isNotEmpty);
          expect(v.why, isNotNull, reason: 'every starter item has a Why');
          expect(v.minutes, isNotNull);
          expect(v.added, isNotNull);
          expect(v.url, isNot(contains('maven.com')),
              reason: 'starter lists are public content only');
        }
      });
    }

    test('topic ids round-trip through config', () {
      final picked = [StarterCatalog.topics[1], StarterCatalog.topics[3]];
      expect(StarterCatalog.decode(StarterCatalog.encode(picked)), picked);
      expect(StarterCatalog.decode('nope,ai'), [StarterCatalog.byId('ai')]);
    });
  });
}
