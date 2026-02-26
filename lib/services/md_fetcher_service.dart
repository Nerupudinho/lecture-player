import 'package:http/http.dart' as http;

class MdFetcherService {
  Future<String> fetch(String url) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch .md file: HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
