import '../data/models/video_model.dart';
import 'csv_parser_service.dart';
import 'source_link.dart';

/// Result of checking a pasted list link before the app switches to it.
class ListCheckResult {
  final bool ok;
  final String message;

  /// The normalized URL the app will actually fetch.
  final String url;
  final List<VideoModel> videos;

  const ListCheckResult._(this.ok, this.message, this.url, this.videos);

  factory ListCheckResult.fail(String message, [String url = '']) =>
      ListCheckResult._(false, message, url, const []);

  factory ListCheckResult.success(String url, List<VideoModel> videos) =>
      ListCheckResult._(
          true,
          'Connected: ${videos.length} '
          '${videos.length == 1 ? 'item' : 'items'}.',
          url,
          videos);
}

/// Checks the link an agent returned and explains, in plain words, what to fix
/// when it doesn't work. Wrong links are the most likely place a new user gets
/// stuck, so every failure says what to do next.
class ListCheck {
  final Future<String> Function(String url) fetch;
  final CsvParserService parser;

  ListCheck({required this.fetch, CsvParserService? parser})
      : parser = parser ?? CsvParserService();

  static const expectedHeader = 'Link,Title,Why,Minutes,Added';

  Future<ListCheckResult> check(String input) async {
    if (input.trim().isEmpty) {
      return ListCheckResult.fail('Paste the link your agent gave you.');
    }
    final url = SourceLink.normalize(input);
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return ListCheckResult.fail(
          "That doesn't look like a link. It should start with https://", url);
    }

    final String body;
    try {
      body = await fetch(url);
    } catch (e) {
      return ListCheckResult.fail(_fetchError(e.toString(), uri), url);
    }

    final head = body.trimLeft().substring(0, _min(body.trimLeft().length, 200))
        .toLowerCase();
    if (head.startsWith('<!doctype html') || head.startsWith('<html')) {
      return ListCheckResult.fail(
          uri.host == 'docs.google.com'
              ? 'Google showed a sign-in page instead of the list. In the '
                  'Sheet, set Share → General access → "Anyone with the link" '
                  '(Viewer), then try again.'
              : 'That link opens a web page, not the list itself. Ask your '
                  'agent for the raw CSV link.',
          url);
    }

    final report = parser.inspect(body);
    if (!report.hasLinkColumn) {
      return ListCheckResult.fail(
          "Found the file, but it has no 'Link' column. Its first row should "
          'be: $expectedHeader',
          url);
    }
    if (report.videos.isEmpty) {
      return ListCheckResult.fail(
          'The list is connected but empty. Ask your agent to run the '
          'playlist skill once now, then try again.',
          url);
    }
    return ListCheckResult.success(url, report.videos);
  }

  String _fetchError(String error, Uri uri) {
    final code = RegExp(r'HTTP (\d{3})').firstMatch(error)?.group(1);
    switch (code) {
      case '404':
        return 'Nothing at that link (404). If it is a Gist or GitHub file, '
            'make sure it is public.';
      case '401':
      case '403':
        return 'That link is private. Make it viewable by anyone with the '
            'link, then try again.';
    }
    if (code != null) return 'The link answered with an error (HTTP $code).';
    return "Couldn't reach ${uri.host}. Check your connection and the link.";
  }

  static int _min(int a, int b) => a < b ? a : b;
}
