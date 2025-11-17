import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:relatoriooffline/core/database/app_database.dart';
import 'package:relatoriooffline/services/apiService.dart';

class SyncService {
  static final SyncService instance = SyncService._init();

  SyncService._init();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _monitoringStarted = false;
  bool _isSyncing = false;

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
      (status) {
        if (_hasConnection(status)) {
          unawaited(syncPending());
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

  Future<bool> trySendRelatorio(Map<String, dynamic> relatorioJson) async {
    final auth = await _getAuth();
    final token = auth?['token'] as String?;

    if (token == null || token.isEmpty) {
      return false;
    }

    // Use ApiService base URL
    final base = ApiService.getBaseUrl();
    final uri = Uri.parse('$base/relatorios/criar');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(relatorioJson),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Tenta sincronizar um formulário já salvo na base local (registro da tabela formularios).
  /// Se conseguir enviar para o backend, marca como sincronizado.
  Future<bool> trySyncAndMark(int id, Map<String, dynamic> record) async {
    try {
      final dadosJson = record['dados_json'] as String;
      final Map<String, dynamic> payload = jsonDecode(dadosJson);

      final success = await trySendRelatorio(payload);
      if (success) {
        await AppDatabase.instance.marcarComoSincronizado(id);
        return true;
      }
    } catch (e) {
      // ignore and return false
    }
    return false;
  }

  /// Percorre todos os formularios pendentes e tenta enviar.
  Future<void> syncPending() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pendentes = await AppDatabase.instance.obterFormularios(sincronizado: false);
      for (final form in pendentes) {
        final id = form['id'] as int;
        await trySyncAndMark(id, form);
      }
    } finally {
      _isSyncing = false;
    }
  }
}
