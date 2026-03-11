import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:laundry_app/core/config/env.dart';

void main() async {
  final url = Uri.parse('${Env.supabaseUrl}/rest/v1/outlets?limit=1');
  
  // Try authenticating using the JWT or anon key
  final response = await http.get(
    url,
    headers: {
      'apikey': Env.supabaseAnonKey,
      'Authorization': 'Bearer ${Env.supabaseAnonKey}',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode == 200) {
    if (response.body != '[]') {
      final data = jsonDecode(response.body);
      print('KEYS: ${data[0].keys}');
    } else {
       print('Outlets list is empty, falling back to swagger URL for definitions:');
       final swaggerUrl = Uri.parse('${Env.supabaseUrl}/rest/v1/?apikey=${Env.supabaseAnonKey}');
       final swaggerRes = await http.get(swaggerUrl);
       if(swaggerRes.statusCode == 200) {
          final sData = jsonDecode(swaggerRes.body);
          print('SCHEMA: ${sData['definitions']['outlets']['properties'].keys}');
       } else {
         print('Failed swagger: ${swaggerRes.body}');
       }
    }
  } else {
    print('Failed with status ${response.statusCode}');
    print(response.body);
  }
}
