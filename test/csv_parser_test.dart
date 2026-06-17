import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_player/services/csv_parser_service.dart';

void main() {
  final parser = CsvParserService();

  test('parses rows into a flat list and skips duplicates', () {
    const csv = '"Link","Title","Duplicate",""\n'
        '"https://maven.com/p/aaa/claude-code-for-pms","Claude Code for PMs","FALSE",""\n'
        '"https://maven.com/p/bbb/pm-interview-prep","PM Interview Prep","FALSE",""\n'
        '"https://maven.com/p/ccc/dupe","A duplicate","TRUE",""\n';

    final videos = parser.parse(csv);

    expect(videos.length, 2);
    expect(videos.any((v) => v.title == 'A duplicate'), isFalse);
    expect(videos.first.title, 'Claude Code for PMs');
    expect(videos.first.url, 'https://maven.com/p/aaa/claude-code-for-pms');
    // position reflects order among kept rows
    expect(videos[0].position, 0);
    expect(videos[1].position, 1);
  });

  test('decodes a wrapped Maven link during parse', () {
    const csv = '"Link","Title","Duplicate"\n'
        '"https://email-courses.maven.com/e/c/eyJlbWFpbF9pZCI6IlJNLXdCd1VBQVp3a2R1ZHA0VjNLTzU1aHU0RXpnUT09IiwiaHJlZiI6Imh0dHBzOi8vbWF2ZW4uY29tL3AvZDY3OWI5P3V0bV9zb3VyY2U9bWF2ZW5cdTAwMjZ1dG1fbWVkaXVtPWVtYWlsXHUwMDI2dXRtX2NhbXBhaWduPWNsY19jb2hvcnRfb3Blblx1MDAyNmFqc191aWQ9MTU3MTE5IiwiaW50ZXJuYWwiOiJjZmIwMDcxNGM4YjcwMTg5ODcyNiJ9/fbbb87","Promotion Path","FALSE"\n';

    final video = parser.parse(csv).single;
    expect(video.url, startsWith('https://maven.com/p/d679b9'));
  });

  test('ignores a Category column if present', () {
    const csv = 'Category,Title,Link\n'
        'My Bucket,Some Title,https://maven.com/p/xyz/random\n';

    final videos = parser.parse(csv);
    expect(videos.single.title, 'Some Title');
    expect(videos.single.url, 'https://maven.com/p/xyz/random');
  });

  test('falls back to the URL when the title is blank', () {
    const csv = 'Link,Title\n'
        'https://maven.com/p/zzz/x,\n';

    expect(parser.parse(csv).single.title, 'https://maven.com/p/zzz/x');
  });

  test('handles quoted titles containing commas', () {
    const csv = '"Link","Title","Duplicate"\n'
        '"https://maven.com/p/zzz/x","AI Agents, Bootcamp & Evals","FALSE"\n';

    expect(parser.parse(csv).single.title, 'AI Agents, Bootcamp & Evals');
  });

  test('empty input yields no videos', () {
    expect(parser.parse(''), isEmpty);
  });
}
