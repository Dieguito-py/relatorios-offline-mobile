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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
      } catch (e) {
        try {
          await db.execute('ALTER TABLE auth ADD COLUMN nome TEXT');
        } catch (e2) {
          if (!e2.toString().contains('duplicate column')) {
            rethrow;
          }
        }
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE auth (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        token TEXT NOT NULL,
        nome TEXT,
        data_login TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE formularios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        dados_json TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        data_criacao TEXT NOT NULL
      )
    ''');
  }

  Future<void> salvarToken(String username, String token, {String? nome}) async {
    final db = await database;
    await db.delete('auth');

    try {
      await db.insert('auth', {
        'username': username,
        'token': token,
        'nome': nome,
        'data_login': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (e.toString().contains('no column named nome')) {
        // Verificar se a coluna já existe antes de tentar adicionar
        final result = await db.rawQuery('PRAGMA table_info(auth)');
        final columnExists = result.any((column) => column['name'] == 'nome');

        if (!columnExists) {
          await db.execute('ALTER TABLE auth ADD COLUMN nome TEXT');
        }

        // Tentar inserir novamente
        await db.insert('auth', {
          'username': username,
          'token': token,
          'nome': nome,
          'data_login': DateTime.now().toIso8601String(),
        });
      } else {
        rethrow;
      }
    }
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
  }) async {
    final db = await database;
    return await db.insert('formularios', {
      'tipo': tipo,
      'dados_json': dadosJson,
      'sincronizado': 0,
      'data_criacao': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> obterFormularios({
    bool? sincronizado,
  }) async {
    final db = await database;
    if (sincronizado != null) {
      return await db.query(
        'formularios',
        where: 'sincronizado = ?',
        whereArgs: [sincronizado ? 1 : 0],
        orderBy: 'data_criacao DESC',
      );
    }
    return await db.query(
      'formularios',
      orderBy: 'data_criacao DESC',
    );
  }

  Future<void> marcarComoSincronizado(int id) async {
    final db = await database;
    await db.update(
      'formularios',
      {'sincronizado': 1},
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

