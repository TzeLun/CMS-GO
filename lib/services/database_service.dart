import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        company_name TEXT,
        client_name TEXT,
        business_model TEXT,
        business_operation TEXT,
        target_market TEXT,
        looking_for TEXT,
        phone_number TEXT,
        email TEXT,
        additional_notes TEXT,
        audio_file_path TEXT,
        transcription TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<Contact> createContact(Contact contact) async {
    final db = await database;
    final id = await db.insert('contacts', contact.toJson());
    return contact.copyWith(id: id.toString());
  }

  Future<Contact?> readContact(String id) async {
    final db = await database;
    final maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Contact.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Contact>> readAllContacts(String userId) async {
    final db = await database;
    final result = await db.query(
      'contacts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return result.map((json) => Contact.fromJson(json)).toList();
  }

  Future<int> updateContact(Contact contact) async {
    final db = await database;
    return db.update(
      'contacts',
      contact.toJson(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(String id) async {
    final db = await database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
