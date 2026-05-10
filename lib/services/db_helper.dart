import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'sholat_smk10_final.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE presensi("
          "id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "nama_sholat TEXT, "
          "waktu TEXT, "
          "foto_path TEXT, "
          "jarak TEXT, "
          "email_user TEXT"
          ")",
        );

        await db.execute(
          "CREATE TABLE users("
          "id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "nama TEXT, " // Tambah ini
          "email TEXT UNIQUE, "
          "password TEXT, "
          "nisn TEXT, " // Tambah ini
          "kelas TEXT" // Tambah ini
          ")",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute(
            "CREATE TABLE users("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "email TEXT UNIQUE, "
            "password TEXT"
            ")",
          );
        }
      },
    );
  }

  Future<int> registerUser(String nama, String email, String password,
      String nisn, String kelas) async {
    final dbClient = await db;
    return await dbClient.insert('users', {
      'nama': nama,
      'email': email,
      'password': password,
      'nisn': nisn,
      'kelas': kelas,
    });
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final dbClient = await db;
    List<Map<String, dynamic>> res = await dbClient.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<List<Map<String, dynamic>>> getPresensiByUser(String email) async {
    final dbClient = await db;
    return await dbClient.query(
      'presensi',
      where: 'email_user = ?',
      whereArgs: [email],
      orderBy: 'id DESC',
    );
  }

  Future<int> simpanPresensi(Map<String, dynamic> data) async {
    final dbClient = await db;
    return await dbClient.insert('presensi', data);
  }
}
