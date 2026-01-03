import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://nubbdictapi.kode4u.tech/';
  
  print('Testing API endpoints...\n');
  
  // Test 1: Check if main search endpoint works
  try {
    final searchUrl = Uri.parse('${baseUrl}search?query=hello');
    final searchResponse = await http.get(searchUrl);
    print('Search endpoint status: ${searchResponse.statusCode}');
    print('Search response type: ${searchResponse.headers['content-type']}');
    print('Search first 100 chars: ${searchResponse.body.substring(0, min(100, searchResponse.body.length))}');
  } catch (e) {
    print('Search endpoint error: $e');
  }
  
  print('\n---\n');
  
  // Test 2: Try common auth endpoints
  final possibleEndpoints = [
    'register',
    'api/register',
    'auth/register',
    'user/register',
    'api/auth/register',
    'api/user/register',
  ];
  
  for (final endpoint in possibleEndpoints) {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('Testing: $url');
      
      // Send a simple GET request first to check if endpoint exists
      final response = await http.get(url);
      print('Status: ${response.statusCode}');
      print('Content-Type: ${response.headers['content-type']}');
      
      if (response.body.isNotEmpty) {
        print('First 200 chars: ${response.body.substring(0, min(200, response.body.length))}');
      }
      
      print('---');
    } catch (e) {
      print('Error: $e\n---');
    }
  }
}

int min(int a, int b) => a < b ? a : b;