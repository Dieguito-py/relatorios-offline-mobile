import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('defesa_civil.db');
    return _database!;
  }


  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    await _runMaintenance(db);
    return db;
  }

  Future<void> _runMaintenance(Database db) async {
    await db.execute(
      "UPDATE formularios SET dados_json = '{\"sincronizado\":true}' WHERE sincronizado = 1",
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        final result = await db.rawQuery('PRAGMA table_info(auth)');
        final columnExists = result.any((column) => column['name'] == 'nome');
        if (!columnExists) {
          await db.execute('ALTER TABLE auth ADD COLUMN nome TEXT');
        }
      } catch (_) {}
    }
    if (oldVersion < 4) {
      final authInfo = await db.rawQuery('PRAGMA table_info(auth)');
      if (!authInfo.any((c) => c['name'] == 'municipal_id')) {
        await db.execute('ALTER TABLE auth ADD COLUMN municipal_id INTEGER');
      }
      if (!authInfo.any((c) => c['name'] == 'municipal_nome')) {
        await db.execute('ALTER TABLE auth ADD COLUMN municipal_nome TEXT');
      }

      final formInfo = await db.rawQuery('PRAGMA table_info(formularios)');
      if (!formInfo.any((c) => c['name'] == 'template_id')) {
        await db.execute('ALTER TABLE formularios ADD COLUMN template_id INTEGER');
      }
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS templates (
          id INTEGER PRIMARY KEY,
          nome TEXT NOT NULL,
          descricao TEXT,
          dados_json TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE auth (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        token TEXT NOT NULL,
        nome TEXT,
        municipal_id INTEGER,
        municipal_nome TEXT,
        data_login TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE templates (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        descricao TEXT,
        dados_json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE formularios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER,
        tipo TEXT NOT NULL,
        dados_json TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        data_criacao TEXT NOT NULL,
        FOREIGN KEY (template_id) REFERENCES templates (id)
      )
    ''');
  }

  Future<void> salvarTemplates(List<dynamic> templates) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('templates');
      for (var template in templates) {
        await txn.insert('templates', {
          'id': template['id'],
          'nome': template['nome'],
          'descricao': template['descricao'],
          'dados_json': jsonEncode(template),
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> obterTemplates() async {
    final db = await database;
    return await db.query('templates');
  }

  Future<void> salvarToken(
    String username,
    String token, {
    String? nome,
    int? municipalId,
    String? municipalNome,
  }) async {
    final db = await database;
    await db.delete('auth');

    await db.insert('auth', {
      'username': username,
      'token': token,
      'nome': nome,
      'municipal_id': municipalId,
      'municipal_nome': municipalNome,
      'data_login': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> obterToken() async {
    final db = await database;
    final result = await db.query('auth', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> limparToken() async {
    final db = await database;
    await db.delete('auth');
  }

  Future<int> salvarFormulario({
    required String tipo,
    required String dadosJson,
    int? templateId,
  }) async {
    final db = await database;
    return await db.insert('formularios', {
      'tipo': tipo,
      'template_id': templateId,
      'dados_json': dadosJson,
      'sincronizado': 0,
      'data_criacao': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> obterFormularios({
    bool? sincronizado,
    bool incluirDadosJson = false,
  }) async {
    final db = await database;
    final columns = incluirDadosJson
        ? null
        : <String>['id', 'tipo', 'template_id', 'sincronizado', 'data_criacao'];

    if (sincronizado != null) {
      return await db.query(
        'formularios',
        columns: columns,
        where: 'sincronizado = ?',
        whereArgs: [sincronizado ? 1 : 0],
        orderBy: 'data_criacao DESC',
      );
    }
    return await db.query(
      'formularios',
      columns: columns,
      orderBy: 'data_criacao DESC',
    );
  }

  Future<void> marcarComoSincronizado(int id) async {
    final db = await database;
    await db.update(
      'formularios',
      {
        'sincronizado': 1,
        'dados_json': '{"sincronizado":true}',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'defesa_civil.db');
    _database = null;
    await databaseFactory.deleteDatabase(path);
  }
}

