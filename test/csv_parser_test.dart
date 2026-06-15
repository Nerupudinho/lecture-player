import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_player/services/csv_parser_service.dart';

void main() {
  final parser = CsvParserService();

  test('parses rows, skips duplicates, decodes links, groups by category', () {
    const csv = '"Link","Title","Duplicate",""\n'
        '"https://maven.com/p/aaa/claude-code-for-pms","Claude Code for PMs","FALSE",""\n'
        '"https://maven.com/p/bbb/pm-interview-prep","PM Interview Prep","FALSE",""\n'
        '"https://maven.com/p/ccc/dupe","A duplicate","TRUE",""\n';

    final result = parser.parse(csv);

    // Two categories from keyword rules; the TRUE row is skipped.
    final all = result.expand((c) => c.videos).toList();
    expect(all.length, 2);
    expect(all.any((v) => v.title == 'A duplicate'), isFalse);

    final aiCat = result.firstWhere((c) => c.category.name == 'AI & Claude Code');
    expect(aiCat.videos.single.url, 'https://maven.com/p/aaa/claude-code-for-pms');
    expect(result.any((c) => c.category.name == 'Product Management'), isTrue);
  });

  test('decodes a wrapped Maven link during parse', () {
    const csv = '"Link","Title","Duplicate"\n'
        '"https://email-courses.maven.com/e/c/eyJlbWFpbF9pZCI6IlJNLXdCd1VBQVp3a2R1ZHA0VjNLTzU1aHU0RXpnUT09IiwiaHJlZiI6Imh0dHBzOi8vbWF2ZW4uY29tL3AvZDY3OWI5P3V0bV9zb3VyY2U9bWF2ZW5cdTAwMjZ1dG1fbWVkaXVtPWVtYWlsXHUwMDI2dXRtX2NhbXBhaWduPWNsY19jb2hvcnRfb3Blblx1MDAyNmFqc191aWQ9MTU3MTE5IiwiaW50ZXJuYWwiOiJjZmIwMDcxNGM4YjcwMTg5ODcyNiJ9/fbbb87","Promotion Path","FALSE"\n';

    final video = parser.parse(csv).expand((c) => c.videos).single;
    expect(video.url, startsWith('https://maven.com/p/d679b9'));
  });

  test('honours an explicit Category column over keyword rules', () {
    const csv = 'Category,Title,Link\n'
        'My Bucket,Some Random Title,https://maven.com/p/xyz/random\n';

    final result = parser.parse(csv);
    expect(result.single.category.name, 'My Bucket');
  });

  test('handles quoted titles containing commas', () {
    const csv = '"Link","Title","Duplicate"\n'
        '"https://maven.com/p/zzz/x","AI Agents, Bootcamp & Evals","FALSE"\n';

    final video = parser.parse(csv).expand((c) => c.videos).single;
    expect(video.title, 'AI Agents, Bootcamp & Evals');
  });

  test('empty input yields no categories', () {
    expect(parser.parse(''), isEmpty);
  });
}
