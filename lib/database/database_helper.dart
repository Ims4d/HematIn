import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
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

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budget (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monthly_limit REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // CRUD Operations for Expenses
  Future<int> createExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<Expense?> readExpense(int id) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Expense>> readAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> readExpensesByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total expense for a period
  Future<double> getTotalExpense(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Get expenses by category for a period
  Future<Map<String, double>> getExpensesByCategory(
      DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses WHERE date BETWEEN ? AND ? GROUP BY category',
      [start.toIso8601String(), end.toIso8601String()],
    );

    Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['category'] as String] = row['total'] as double;
    }
    return categoryTotals;
  }

  // Get expenses by day for a period
  Future<Map<DateTime, double>> getDailyExpenses(
      DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUBSTR(date, 1, 10) as day, SUM(amount) as total FROM expenses WHERE date BETWEEN ? AND ? GROUP BY day ORDER BY day ASC',
      [start.toIso8601String(), end.toIso8601String()],
    );

    Map<DateTime, double> dailyTotals = {};
    for (var row in result) {
      final date = DateTime.parse(row['day'] as String);
      dailyTotals[date] = row['total'] as double;
    }
    return dailyTotals;
  }

  // Budget operations
  Future<int> setMonthlyBudget(double amount) async {
    final db = await database;
    final existing = await db.query('budget', limit: 1);
    
    if (existing.isEmpty) {
      return await db.insert('budget', {
        'monthly_limit': amount,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      return await db.update(
        'budget',
        {
          'monthly_limit': amount,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<double?> getMonthlyBudget() async {
    final db = await database;
    final result = await db.query('budget', limit: 1);
    if (result.isNotEmpty) {
      return result.first['monthly_limit'] as double;
    }
    return null;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
