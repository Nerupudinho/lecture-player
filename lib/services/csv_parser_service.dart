import '../data/models/video_model.dart';
import 'link_decoder_service.dart';

/// Parses a Google Sheet CSV export into a flat list of playable videos.
///
/// Expected columns (header row, case-insensitive): `Link` (or `URL`),
/// `Title`, and optionally `Duplicate`, `Why`, `Minutes`, `Added`. Any other
/// columns (e.g. `Source`) are ignored.
///  - Rows flagged `Duplicate = TRUE` are skipped.
///  - A URL that appears twice is kept once (first row wins), so merged
///    starter lists and sloppy agent appends never show doubles.
///  - Each link is decoded to its clean playable URL.
///  - Title falls back to the URL when blank.
class CsvParserService {
  final LinkDecoderService _decoder;

  CsvParserService({LinkDecoderService? decoder})
      : _decoder = decoder ?? LinkDecoderService();

  List<VideoModel> parse(String csv) => inspect(csv).videos;

  /// Like [parse], but also reports whether a link column was found, so the
  /// "connect your list" screen can say exactly what's wrong with a link.
  CsvReport inspect(String csv) {
    final rows = _parseCsv(csv);
    if (rows.isEmpty) return const CsvReport(hasLinkColumn: false, videos: []);

    final header = rows.first.map((c) => c.trim().toLowerCase()).toList();
    int col(List<String> names) {
      for (final n in names) {
        final i = header.indexOf(n);
        if (i != -1) return i;
      }
      return -1;
    }

    final linkIdx = col(['link', 'url']);
    final titleIdx = col(['title']);
    final dupIdx = col(['duplicate']);
    final whyIdx = col(['why']);
    final minutesIdx = col(['minutes', 'duration']);
    final addedIdx = col(['added', 'date added']);
    if (linkIdx == -1) {
      return const CsvReport(hasLinkColumn: false, videos: []);
    }

    final videos = <VideoModel>[];
    final seen = <String>{};
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      String cell(int j) => (j >= 0 && j < row.length) ? row[j].trim() : '';

      final rawLink = cell(linkIdx);
      if (rawLink.isEmpty) continue;
      if (dupIdx != -1 && cell(dupIdx).toUpperCase() == 'TRUE') continue;

      final url = _decoder.decode(rawLink);
      if (!seen.add(url)) continue;
      final rawTitle = cell(titleIdx);
      final why = cell(whyIdx);
      final added = cell(addedIdx);
      videos.add(VideoModel(
        title: rawTitle.isNotEmpty ? rawTitle : url,
        url: url,
        position: videos.length,
        why: why.isEmpty ? null : why,
        minutes: int.tryParse(cell(minutesIdx)),
        added: _isIsoDate(added) ? added.substring(0, 10) : null,
      ));
    }
    return CsvReport(hasLinkColumn: true, videos: videos);
  }

  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}');
  bool _isIsoDate(String s) => _isoDate.hasMatch(s);

  /// Minimal RFC 4180 CSV parser: handles quoted fields, doubled quotes,
  /// embedded commas/newlines, and CRLF or LF line endings.
  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var sawField = false;

    void endField() {
      row.add(field.toString());
      field.clear();
      sawField = true;
    }

    void endRow() {
      endField();
      rows.add(row);
      row = <String>[];
      sawField = false;
    }

    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
      } else {
        switch (c) {
          case '"':
            inQuotes = true;
            break;
          case ',':
            endField();
            break;
          case '\r':
            break; // handled by the following \n
          case '\n':
            endRow();
            break;
          default:
            field.write(c);
        }
      }
    }
    // Flush trailing field/row if the input didn't end with a newline.
    if (field.isNotEmpty || sawField || row.isNotEmpty) endRow();
    return rows;
  }
}

class CsvReport {
  final bool hasLinkColumn;
  final List<VideoModel> videos;
  const CsvReport({required this.hasLinkColumn, required this.videos});
}
