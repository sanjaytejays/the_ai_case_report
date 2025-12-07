import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medical_case.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'medscribe_v1.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cases(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patientName TEXT,
            date TEXT,
            audioPath TEXT,
            transcript TEXT,
            subjective TEXT,
            objective TEXT,
            assessment TEXT,
            plan TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertCase(MedicalCase medicalCase) async {
    final db = await database;
    return await db.insert(
      'cases',
      medicalCase.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MedicalCase>> getCases() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cases',
      orderBy: "date DESC",
    );
    return List.generate(maps.length, (i) => MedicalCase.fromMap(maps[i]));
  }
}
