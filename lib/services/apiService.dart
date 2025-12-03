import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  static const String _baseUrl = 'https://relatoriosoffline.app/api';
  static String customBaseUrl = '';

  static String getBaseUrl() {
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }
    return _baseUrl;
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final apiUrl = getBaseUrl();

      final requestBody = jsonEncode({
        'username': username,
        'password': password,
      });

      final response = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? data['access_token'];
        final nome = data['nome'] ?? data['name'];

        return {
          'token': token,
          'nome': nome,
        };
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> sincronizarFormulario({
    required String token,
    required String tipo,
    required Map<String, dynamic> dados,
  }) async {
    try {
      final apiUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$apiUrl/formularios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tipo': tipo,
          'dados': dados,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
