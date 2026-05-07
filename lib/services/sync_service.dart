import 'dart:async';
import 'dart:convert';

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

  static const Duration _connectionStabilizationDelay = Duration(seconds: 3);
  static const Duration _requestTimeout = Duration(seconds: 60);

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

  Future<Map<String, dynamic>?> _getAuth() async {
    return await AppDatabase.instance.obterToken();
  }

  Future<bool> trySendRelatorio(
    Map<String, dynamic> dadosBrutos, {
    int? localId,
    int? templateId,
  }) async {
    if (localId != null) {
      if (_inFlightIds.contains(localId)) return false;
      _inFlightIds.add(localId);
    }

    try {
      final auth = await _getAuth();
      final token = auth?['token'] as String?;
      if (token == null || token.isEmpty) return false;

      final uri = Uri.parse('${ApiService.getBaseUrl()}/relatorios/criar');
      var request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';

      final Map<String, dynamic> dadosParaJson = Map.from(dadosBrutos);
      
      dadosBrutos.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.length > 100) {
            for (int i = 0; i < value.length; i++) {
              try {
                final bytes = base64Decode(value[i] as String);
                request.files.add(http.MultipartFile.fromBytes(
                  '$key[]', 
                  bytes,
                  filename: '${key}_$i.jpg',
                ));
              } catch (e) {
              }
            }
            dadosParaJson[key] = "[ENVIADO_COMO_ARQUIVO]";
          }
        }
      });

      final requestPayload = {
        "templateId": templateId,
        "cidade": auth?['municipal_nome'] ?? "Desconhecida",
        "municipalId": auth?['municipal_id'] ?? 0,
        "dados": dadosParaJson,
      };
      
      request.fields['request'] = jsonEncode(requestPayload);

      final streamedResponse = await request.send().timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      if (localId != null) _inFlightIds.remove(localId);
    }
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
        final templateId = form['template_id'] as int?;
        final dadosBrutos = jsonDecode(form['dados_json'] as String);

        final success = await trySendRelatorio(
          dadosBrutos,
          localId: id,
          templateId: templateId,
        );

        if (success) {
          await AppDatabase.instance.marcarComoSincronizado(id);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
