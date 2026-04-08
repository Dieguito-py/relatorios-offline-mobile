import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:relatoriooffline/core/database/app_database.dart';
import 'package:relatoriooffline/services/api_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();

  SyncService._init();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _monitoringStarted = false;
  bool _isSyncing = false;
  final Set<int> _inFlightIds = <int>{};

  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 2);
  static const Duration _connectionStabilizationDelay = Duration(seconds: 3);
  static const Duration _requestTimeout = Duration(seconds: 30);

  bool _hasConnection(dynamic status) {
    if (status is ConnectivityResult) {
      return status != ConnectivityResult.none;
    }
    if (status is List<ConnectivityResult>) {
      return status.any((result) => result != ConnectivityResult.none);
    }
    return false;
  }

  Future<void> startMonitoring() async {
    if (_monitoringStarted) return;
    _monitoringStarted = true;

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (status) async {
        if (_hasConnection(status)) {
          await Future.delayed(_connectionStabilizationDelay);
          final current = await _connectivity.checkConnectivity();
          if (_hasConnection(current)) {
            unawaited(syncPending());
          }
        }
      },
    );

    final current = await _connectivity.checkConnectivity();
    if (_hasConnection(current)) {
      await syncPending();
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _monitoringStarted = false;
  }

  Future<Map<String, dynamic>?> _getAuth() async {
    return await AppDatabase.instance.obterToken();
  }

  Future<bool> trySendRelatorio(
    Map<String, dynamic> relatorioJson, {
    int? localId,
  }) async {
    if (localId != null) {
      if (_inFlightIds.contains(localId)) {
        return false;
      }
      _inFlightIds.add(localId);
    }

    final auth = await _getAuth();
    final token = auth?['token'] as String?;

    if (token == null || token.isEmpty) {
      if (localId != null) _inFlightIds.remove(localId);
      return false;
    }

    final base = ApiService.getBaseUrl();
    final uri = Uri.parse('$base/relatorios/criar');
    final imagens = _extrairImagens(relatorioJson);
    final payloadSemImagens = Map<String, dynamic>.from(relatorioJson)
      ..remove('fotoResidencia')
      ..remove('fotosResidencia');
    final client = http.Client();

    try {
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          final connectivity = await _connectivity.checkConnectivity();
          if (!_hasConnection(connectivity)) {
            break;
          }

          final request = http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Bearer $token';

          payloadSemImagens.forEach((key, value) {
            if (value == null) return;
            if (value is List || value is Map) {
              request.fields[key] = jsonEncode(value);
              return;
            }
            request.fields[key] = value.toString();
          });

          for (var i = 0; i < imagens.length; i++) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'fotosResidencia',
                imagens[i],
                filename: 'residencia_${i + 1}.jpg',
              ),
            );
          }

          final streamedResponse = await client.send(request).timeout(_requestTimeout);
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode >= 200 && response.statusCode < 300) {
            return true;
          }

          if (response.statusCode >= 500 && attempt < _maxRetries - 1) {
            await Future.delayed(_initialRetryDelay * (attempt + 1));
            continue;
          }

          return false;
        } on TimeoutException {
          if (attempt < _maxRetries - 1) {
            await Future.delayed(_initialRetryDelay * (attempt + 1));
            continue;
          }
          return false;
        } on http.ClientException {
          if (attempt < _maxRetries - 1) {
            await Future.delayed(_initialRetryDelay * (attempt + 1));
            continue;
          }
          return false;
        }
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      client.close();
      if (localId != null) {
        _inFlightIds.remove(localId);
      }
    }
  }

  List<Uint8List> _extrairImagens(Map<String, dynamic> payload) {
    final imagens = <Uint8List>[];

    final fotosMultiplas = payload['fotosResidencia'];
    if (fotosMultiplas is List) {
      for (final item in fotosMultiplas) {
        if (item is String && item.isNotEmpty) {
          try {
            imagens.add(base64Decode(item));
          } catch (_) {
            // Ignora imagens inválidas para não bloquear o envio restante.
          }
        }
      }
    }

    final fotoLegada = payload['fotoResidencia'];
    if (fotoLegada is String && fotoLegada.isNotEmpty) {
      try {
        imagens.add(base64Decode(fotoLegada));
      } catch (_) {
        // Ignora base64 inválido legado.
      }
    }

    return imagens;
  }

  Future<bool> trySyncAndMark(int id, Map<String, dynamic> record) async {
    try {
      final dadosJson = record['dados_json'] as String;
      final Map<String, dynamic> payload = jsonDecode(dadosJson);

      final success = await trySendRelatorio(payload, localId: id);
      if (success) {
        await AppDatabase.instance.marcarComoSincronizado(id);
        return true;
      }
    } catch (e) {
      // ignore and return false
    }
    return false;
  }

  Future<void> syncPending() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pendentes = await AppDatabase.instance.obterFormularios(
        sincronizado: false,
        incluirDadosJson: true,
      );
      for (final form in pendentes) {
        final id = form['id'] as int;
        await trySyncAndMark(id, form);
      }
    } finally {
      _isSyncing = false;
    }
  }
}
