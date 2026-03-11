import 'dart:convert';
import 'dart:io';

void main() async {
  final supabaseUrl = 'https://rhhpgvmgzkbutzpurouz.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJoaHBndm1nemtidXR6cHVyb3V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MjM2MTUsImV4cCI6MjA4ODQ5OTYxNX0.5ca3Rwl5vZZg0jg0A_SIlib_IUFLqhtJQ19-25fqsKI';
  
  // We don't have user password, so we can't login easily.
  // Let's try to just hit the GraphQL endpoint assuming it's introspection enabled,
  // or use the swagger endpoint with anon key.
  
  final client = HttpClient();
  
  try {
    // Attempt REST OpenAPI fetch with ANON key
    final req = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/?apikey=$anonKey'));
    req.headers.add('Authorization', 'Bearer $anonKey');
    final res = await req.close();
    
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode == 200) {
      final json = jsonDecode(body);
      final outlets = json['definitions']['outlets']['properties'];
      print('Outlets schema keys: \${outlets.keys}');
    } else {
      print('Failed to get schema: \${res.statusCode} \${body}');
    }
  } catch(e) {
    print('Error: \$e');
  } finally {
    client.close();
  }
}
