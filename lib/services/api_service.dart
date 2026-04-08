import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  //static const String _baseUrl = 'https://relatoriosoffline.app/api';
  static const String _baseUrl = 'http://192.168.0.102:8084/api';
  static String customBaseUrl = '';
  static bool allowSelfSignedCert = !kReleaseMode;

  static String getBaseUrl() {
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }
    return _baseUrl;
  }

  IOClient _createClient() {
    final httpClient = HttpClient();
    if (allowSelfSignedCert) {
      final expectedHost = Uri.parse(getBaseUrl()).host;
      httpClient.badCertificateCallback = (cert, host, port) => host == expectedHost;
    }
    return IOClient(httpClient);
  }

  String? _asNonEmptyString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final apiUrl = getBaseUrl();

      final requestBody = jsonEncode({
        'username': username,
        'password': password,
      });

      final client = _createClient();
      final response = await client.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 10));
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data is Map<String, dynamic> && data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : null;

        final token = _asNonEmptyString(data['token']) ??
            _asNonEmptyString(data['access_token']) ??
            _asNonEmptyString(user?['token']);
        final nome = _asNonEmptyString(data['nome']) ??
            _asNonEmptyString(data['name']) ??
            _asNonEmptyString(user?['nome']) ??
            _asNonEmptyString(user?['name']);

        if (token == null) {
          return null;
        }

        return {
          'token': token,
          'nome': nome,
        };
      }

      return null;
    } on SocketException {
      throw Exception(
        'Sem conexão com a internet. Verifique sua rede e tente novamente.',
      );
    } on TimeoutException {
      throw Exception(
        'O servidor demorou para responder. Tente novamente em instantes.',
      );
    } on http.ClientException {
      throw Exception(
        'Não conseguimos comunicar com o servidor. Por favor, tente novamente.',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> sincronizarFormulario({
    required String token,
    required String tipo,
    required Map<String, dynamic> dados,
  }) async {
    const int maxRetries = 3;
    const Duration initialDelay = Duration(seconds: 2);
    const Duration timeout = Duration(seconds: 30);

    final apiUrl = getBaseUrl();

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final client = _createClient();
        try {
          final response = await client.post(
            Uri.parse('$apiUrl/formularios'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'tipo': tipo,
              'dados': dados,
            }),
          ).timeout(timeout);

          if (response.statusCode == 200 || response.statusCode == 201) {
            return true;
          }

          if (response.statusCode >= 500 && attempt < maxRetries - 1) {
            await Future.delayed(initialDelay * (attempt + 1));
            continue;
          }

          return false;
        } finally {
          client.close();
        }
      } on TimeoutException {
        if (attempt < maxRetries - 1) {
          await Future.delayed(initialDelay * (attempt + 1));
          continue;
        }
        return false;
      } on SocketException {
        if (attempt < maxRetries - 1) {
          await Future.delayed(initialDelay * (attempt + 1));
          continue;
        }
        return false;
      } on http.ClientException {
        if (attempt < maxRetries - 1) {
          await Future.delayed(initialDelay * (attempt + 1));
          continue;
        }
        return false;
      } catch (e) {
        if (attempt < maxRetries - 1) {
          await Future.delayed(initialDelay * (attempt + 1));
          continue;
        }
        return false;
      }
    }
    return false;
  }
}
