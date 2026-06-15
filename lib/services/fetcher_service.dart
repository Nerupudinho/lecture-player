import 'package:http/http.dart' as http;

/// Fetches the raw text of a remote source (the Google Sheet CSV export).
class FetcherService {
  Future<String> fetch(String url) async {
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch playlist: HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
