import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static Database? _database;
  static const String usersTable = 'users';
  static const String historyTable = 'history';
  static const String sessionTable = 'session';
  static const String settingsTable = 'settings';
  static const String groupsTable = 'tab_groups';
  static const String tabsTable = 'tabs';
  static const String downloadsTable = 'downloads';
  static const String databaseName = 'djimsearch.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = await getDatabasesPath();
    String databasePath = join(path, databaseName);

    return await openDatabase(
      databasePath,
      version: 7, // Passage à la version 7 pour ajouter la table des téléchargements
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  // Activer les clés étrangères
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createHistoryTable(db);
    await _createSessionTable(db);
    await _createSettingsTable(db);
    await _createGroupsTable(db);
    await _createTabsTable(db);
    await _createDownloadsTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createHistoryTable(db);
    }
    if (oldVersion < 3) {
      await _createSessionTable(db);
    }
    if (oldVersion < 4) {
      await _createSettingsTable(db);
    }
    if (oldVersion < 6) {
      await _createGroupsTable(db);
      await _createTabsTable(db);
    }
    if (oldVersion < 7) {
      await _createDownloadsTable(db);
    }
  }

  Future _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $usersTable (
        users_id INTEGER PRIMARY KEY AUTOINCREMENT,
        users_nom TEXT NOT NULL,
        users_prenom TEXT NOT NULL,
        users_email TEXT UNIQUE NOT NULL,
        users_password TEXT NOT NULL,
        users_status TEXT DEFAULT 'active',
        date_create INTEGER,
        date_update INTEGER
      )
    ''');
  }

  Future _createHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $historyTable (
        history_id INTEGER PRIMARY KEY AUTOINCREMENT,
        history_query TEXT NOT NULL,
        history_url TEXT,
        history_date INTEGER NOT NULL
      )
    ''');
  }

  Future _createSessionTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $sessionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        login_date INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future _createGroupsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $groupsTable (
        group_id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_name TEXT NOT NULL,
        group_date INTEGER NOT NULL
      )
    ''');
  }

  Future _createTabsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tabsTable (
        tab_id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        tab_url TEXT NOT NULL,
        tab_title TEXT,
        tab_date INTEGER NOT NULL,
        FOREIGN KEY (group_id) REFERENCES $groupsTable(group_id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createDownloadsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $downloadsTable (
        download_id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT NOT NULL,
        file_url TEXT NOT NULL,
        file_path TEXT,
        file_size TEXT,
        download_date INTEGER NOT NULL
      )
    ''');
  }

  // --- Downloads Methods ---

  Future<int> addDownload(String fileName, String url, {String? path, String? size}) async {
    final db = await database;
    return await db.insert(downloadsTable, {
      'file_name': fileName,
      'file_url': url,
      'file_path': path,
      'file_size': size,
      'download_date': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    final db = await database;
    return await db.query(downloadsTable, orderBy: 'download_date DESC');
  }

  Future<int> deleteDownload(int id) async {
    final db = await database;
    return await db.delete(downloadsTable, where: 'download_id = ?', whereArgs: [id]);
  }

  // --- Tab Groups Methods ---

  Future<int> addTabGroup(String name) async {
    final db = await database;
    return await db.insert(groupsTable, {
      'group_name': name,
      'group_date': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  Future<Map<String, dynamic>?> getTabGroupById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      groupsTable,
      where: 'group_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getTabGroups() async {
    final db = await database;
    return await db.query(groupsTable, orderBy: 'group_date DESC');
  }

  Future<int> deleteTabGroup(int id) async {
    final db = await database;
    return await db.delete(groupsTable, where: 'group_id = ?', whereArgs: [id]);
  }

  Future<int> addTabToGroup(int groupId, String url, {String? title}) async {
    final db = await database;
    return await db.insert(tabsTable, {
      'group_id': groupId,
      'tab_url': url,
      'tab_title': title,
      'tab_date': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getTabsForGroup(int groupId) async {
    final db = await database;
    return await db.query(tabsTable, where: 'group_id = ?', whereArgs: [groupId], orderBy: 'tab_date ASC');
  }

  // --- Settings Methods ---

  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> getSetting(String key, String defaultValue) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return defaultValue;
  }

  // --- Users Methods ---

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      usersTable,
      where: 'users_email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<int> createUser(Map<String, String> userData) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final Map<String, Object?> userToInsert = {
      'users_nom': userData['users_nom'],
      'users_prenom': userData['users_prenom'],
      'users_email': userData['users_email'],
      'users_password': userData['users_password'],
      'users_status': 'active',
      'date_create': now,
      'date_update': now,
    };

    return await db.insert(usersTable, userToInsert, conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      usersTable,
      where: 'users_email = ? AND users_password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      usersTable,
      where: 'users_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // --- Session Methods ---

  Future<void> saveSession(int userId) async {
    final db = await database;
    await db.delete(sessionTable);
    await db.insert(sessionTable, {
      'user_id': userId,
      'login_date': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete(sessionTable);
  }

  Future<Map<String, dynamic>?> getSessionUser() async {
    final db = await database;
    final List<Map<String, dynamic>> session = await db.query(sessionTable, limit: 1);
    if (session.isNotEmpty) {
      final userId = session.first['user_id'] as int;
      return await getUserById(userId);
    }
    return null;
  }

  // --- History Methods ---

  Future<int> addHistory(String query, {String? url}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final last = await db.query(historyTable, orderBy: 'history_date DESC', limit: 1);
    if (last.isNotEmpty && last.first['history_query'] == query) {
      return await db.update(
        historyTable,
        {'history_date': now},
        where: 'history_id = ?',
        whereArgs: [last.first['history_id']]
      );
    }

    return await db.insert(historyTable, {
      'history_query': query,
      'history_url': url,
      'history_date': now,
    });
  }

  Future<List<Map<String, dynamic>>> getRecentHistoryForHome() async {
    return await getHistory(limit: 5); 
  }

  Future<List<Map<String, dynamic>>> getHistory({int? limit}) async {
    final db = await database;
    return await db.query(
      historyTable,
      orderBy: 'history_date DESC',
      limit: limit,
    );
  }

  Future<int> deleteHistoryItem(int id) async {
    final db = await database;
    return await db.delete(historyTable, where: 'history_id = ?', whereArgs: [id]);
  }

  Future<int> clearHistory() async {
    final db = await database;
    return await db.delete(historyTable);
  }

  // --- General ---

  Future<void> resetDB() async {
    String path = await getDatabasesPath();
    String databasePath = join(path, databaseName);
    await deleteDatabase(databasePath);
    _database = null;
  }
}
