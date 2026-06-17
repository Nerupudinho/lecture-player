import '../data/models/video_model.dart';
import 'link_decoder_service.dart';

/// Parses a Google Sheet CSV export into a flat list of playable videos.
///
/// Expected columns (header row, case-insensitive): `Link` (or `URL`),
/// `Title`, optional `Duplicate`. Any other columns (e.g. `Category`) are
/// ignored.
///  - Rows flagged `Duplicate = TRUE` are skipped.
///  - Each link is decoded to its clean playable URL.
///  - Title falls back to the URL when blank.
class CsvParserService {
  final LinkDecoderService _decoder;

  CsvParserService({LinkDecoderService? decoder})
      : _decoder = decoder ?? LinkDecoderService();

  List<VideoModel> parse(String csv) {
    final rows = _parseCsv(csv);
    if (rows.isEmpty) return [];

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
    if (linkIdx == -1) return [];

    final videos = <VideoModel>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      String cell(int j) => (j >= 0 && j < row.length) ? row[j].trim() : '';

      final rawLink = cell(linkIdx);
      if (rawLink.isEmpty) continue;
      if (dupIdx != -1 && cell(dupIdx).toUpperCase() == 'TRUE') continue;

      final url = _decoder.decode(rawLink);
      final rawTitle = cell(titleIdx);
      videos.add(VideoModel(
        title: rawTitle.isNotEmpty ? rawTitle : url,
        url: url,
        position: videos.length,
      ));
    }
    return videos;
  }

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
