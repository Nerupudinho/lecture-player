/// Turns the link an agent (or a person) pastes into the URL that actually
/// serves raw CSV.
///
/// Agents hand back whatever link is natural for where they put the list, so
/// the app accepts the common shapes instead of making the user fix them:
///  - Google Sheets edit/view link  -> CSV export of that tab
///  - GitHub file page (`/blob/`)   -> raw.githubusercontent.com
///  - Gist page                     -> the Gist's raw endpoint (latest revision)
///  - anything else                 -> unchanged
class SourceLink {
  static String normalize(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;

    // Google Sheets: /spreadsheets/d/<id>/edit#gid=<gid>
    if (uri.host == 'docs.google.com' &&
        uri.pathSegments.length >= 3 &&
        uri.pathSegments[0] == 'spreadsheets' &&
        uri.pathSegments[1] == 'd') {
      final id = uri.pathSegments[2];
      // Already a published or export CSV link: leave it alone.
      if (id == 'e' || uri.pathSegments.contains('export') ||
          uri.queryParameters['output'] == 'csv') {
        return trimmed;
      }
      final gid = _gid(uri);
      return 'https://docs.google.com/spreadsheets/d/$id/export?format=csv'
          '${gid != null ? '&gid=$gid' : ''}';
    }

    // GitHub file page: github.com/<owner>/<repo>/blob/<ref>/<path>
    if (uri.host == 'github.com' &&
        uri.pathSegments.length >= 5 &&
        uri.pathSegments[2] == 'blob') {
      final s = uri.pathSegments;
      final rest = s.sublist(3).join('/');
      return 'https://raw.githubusercontent.com/${s[0]}/${s[1]}/$rest';
    }

    // Gist page: gist.github.com/<owner>/<id>  (no file part)
    if (uri.host == 'gist.github.com' && uri.pathSegments.length == 2) {
      final s = uri.pathSegments;
      return 'https://gist.githubusercontent.com/${s[0]}/${s[1]}/raw';
    }

    return trimmed;
  }

  static String? _gid(Uri uri) {
    final fromQuery = uri.queryParameters['gid'];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    final match = RegExp(r'gid=(\d+)').firstMatch(uri.fragment);
    return match?.group(1);
  }
}
