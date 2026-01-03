import 'dart:convert';
import 'package:dictionary_app/models/dictionary_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://nubbdictapi.kode4u.tech/';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static final http.Client _client = http.Client();

  static Future<List<DictionaryEntry>> search(String query) async {
    if (query.isEmpty || query.length < 2) {
      throw ApiException('សូមបញ្ចូលពាក្យយ៉ាងតិច ២ តួអក្សរ', 400);
    }

    final cleanedQuery = query.trim();
    final encodedQuery = Uri.encodeQueryComponent(cleanedQuery);
    final url = Uri.parse('${baseUrl}search?query=$encodedQuery');

    print('🔍 Searching for: "$cleanedQuery"');
    print('📤 URL: $url');

    try {
      final response = await _client
          .get(url)
          .timeout(timeoutDuration, onTimeout: () {
        throw ApiException('សំណើរយូរពេក', 408);
      });

      print('📥 Response status: ${response.statusCode}');

      return _handleSearchResponse(response, cleanedQuery);
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw ApiException('បញ្ហាក្នុងការតភ្ជាប់អ៊ីនធឺណិត', 0);
    } on FormatException catch (e) {
      print('❌ JSON format error: $e');
      throw ApiException('ទម្រង់ទិន្នន័យមិនត្រឹមត្រូវ', 0);
    } catch (e) {
      print('❌ Unknown error: $e');
      throw ApiException('មានបញ្ហាក្នុងការស្វែងរក', 0);
    }
  }

  static List<DictionaryEntry> _handleSearchResponse(
      http.Response response, String query) {
    switch (response.statusCode) {
      case 200:
        return _parseSearchResponse(response.body);
      case 400:
        throw ApiException('ពាក្យស្វែងរកមិនត្រឹមត្រូវ', 400);
      case 404:
        throw ApiException('មិនរកឃើញពាក្យ "$query" ទេ', 404);
      case 500:
        throw ApiException('មានបញ្ហានៅក្នុងម៉ាស៊ីនបម្រើ', 500);
      default:
        throw ApiException('មិនអាចស្វែងរកបាន: ${response.statusCode}', 
            response.statusCode);
    }
  }

  static List<DictionaryEntry> _parseSearchResponse(String responseBody) {
    try {
      final Map<String, dynamic> jsonData = json.decode(responseBody);
      print('✅ JSON parsed successfully');
      
      List<dynamic> results = [];
      
      if (jsonData.containsKey('dictionarys')) {
        results = jsonData['dictionarys'];
        print('📊 Found ${results.length} results in "dictionarys"');
      } else if (jsonData.containsKey('results')) {
        results = jsonData['results'];
        print('📊 Found ${results.length} results in "results"');
      } else if (jsonData.containsKey('data')) {
        final dynamic data = jsonData['data'];
        if (data is List) {
          results = data;
          print('📊 Found ${results.length} results in "data"');
        }
      } else {
        print('⚠️ No results found');
        return [];
      }
      
      final List<DictionaryEntry> entries = results
          .where((item) => item is Map<String, dynamic>)
          .map((item) => DictionaryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
      
      print('✅ Successfully parsed ${entries.length} dictionary entries');
      return entries;
    } on FormatException catch (e) {
      print('❌ Failed to parse JSON: $e');
      throw ApiException('ទិន្នន័យមិនត្រឹមត្រូវ', 0);
    }
  }

  // Helper function for suggestions
  static Future<List<String>> getSuggestions(String partial) async {
    if (partial.isEmpty || partial.length < 2) return [];
    
    try {
      final results = await search(partial);
      return results
          .map((entry) => entry.englishWord)
          .where((word) => word.toLowerCase().contains(partial.toLowerCase()))
          .toSet()
          .toList()
          .sublist(0, min(5, results.length));
    } catch (e) {
      return [];
    }
  }
}

int min(int a, int b) => a < b ? a : b;

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

// Helper function for error messages in Khmer
String getApiErrorMessage(ApiException e, [String query = '']) {
  switch (e.statusCode) {
    case 408:
      return 'សំណើរយូរពេក សូមព្យាយាមម្តងទៀត';
    case 400:
      return 'សំណើមិនត្រឹមត្រូវ';
    case 401:
      return 'អ្នកមិនមានសិទ្ធិ';
    case 403:
      return 'ហាមឃាត់';
    case 404:
      if (query.isNotEmpty) {
        return 'មិនរកឃើញពាក្យ "$query" ទេ';
      }
      return 'មិនរកឃើញ';
    case 409:
      return 'ព័ត៌មានបានមានរួចហើយ';
    case 500:
      return 'មានបញ្ហានៅក្នុងម៉ាស៊ីនបម្រើ';
    case 503:
      return 'សេវាកម្មមិនអាចប្រើបានបច្ចុប្បន្ន';
    default:
      return 'មានបញ្ហាក្នុងការស្វែងរក: ${e.message}';
  }
}

