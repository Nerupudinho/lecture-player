import '../data/models/category_model.dart';
import '../data/models/video_model.dart';
import 'categorizer_service.dart';
import 'link_decoder_service.dart';

class ParsedCategory {
  final CategoryModel category;
  final List<VideoModel> videos;
  ParsedCategory({required this.category, required this.videos});
}

/// Parses a Google Sheet CSV export into categories of playable videos.
///
/// Expected columns (header row, case-insensitive): `Link` (or `URL`),
/// `Title`, optional `Duplicate`, optional `Category`.
///  - Rows flagged `Duplicate = TRUE` are skipped.
///  - Each link is decoded to its clean playable URL.
///  - If a `Category` column is present and non-empty it is used; otherwise the
///    category is derived from the title via [CategorizerService].
class CsvParserService {
  final LinkDecoderService _decoder;
  final CategorizerService _categorizer;

  CsvParserService({
    LinkDecoderService? decoder,
    CategorizerService? categorizer,
  })  : _decoder = decoder ?? LinkDecoderService(),
        _categorizer = categorizer ?? CategorizerService();

  List<ParsedCategory> parse(String csv) {
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
    final catIdx = col(['category']);
    if (linkIdx == -1) return [];

    final byCategory = <String, List<VideoModel>>{};
    final order = <String>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      String cell(int j) => (j >= 0 && j < row.length) ? row[j].trim() : '';

      final rawLink = cell(linkIdx);
      if (rawLink.isEmpty) continue;
      if (dupIdx != -1 && cell(dupIdx).toUpperCase() == 'TRUE') continue;

      final url = _decoder.decode(rawLink);
      final rawTitle = cell(titleIdx);
      final title = rawTitle.isNotEmpty ? rawTitle : url;
      final explicitCat = cell(catIdx);
      final category =
          explicitCat.isNotEmpty ? explicitCat : _categorizer.categorize(title);

      final list = byCategory.putIfAbsent(category, () {
        order.add(category);
        return <VideoModel>[];
      });
      list.add(VideoModel(
        categoryId: 0, // set after DB insert
        title: title,
        url: url,
        position: list.length,
      ));
    }

    return [
      for (final name in order)
        ParsedCategory(
          category: CategoryModel(name: name),
          videos: byCategory[name]!,
        ),
    ];
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
