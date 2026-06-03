import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/wallet_model.dart';

class DBHelper {
  static DBHelper? _databaseHelper;
  static Database? _database;

  DBHelper._createInstance();

  factory DBHelper() {
    _databaseHelper ??= DBHelper._createInstance();
    return _databaseHelper!;
  }

  Future<Database> get database async {
    _database ??= await initializeDatabase();
    return _database!;
  }

  Future<Database> initializeDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_tracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> closeDb() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _createDb(Database db, int newVersion) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_system INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_code INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        wallet_id INTEGER NOT NULL,
        transfer_wallet_id INTEGER,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE CASCADE,
        FOREIGN KEY (transfer_wallet_id) REFERENCES wallets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await _populateDefaultCategories(db);
    await _populateDefaultWallets(db);
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Create wallets table
      await db.execute('''
        CREATE TABLE wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          icon_code INTEGER NOT NULL
        )
      ''');

      // 2. Insert default wallets
      await db.insert('wallets', {
        'id': 1,
        'name': 'Main Account',
        'color_value': 0xFF4361EE,
        'icon_code': 0xe1f8
      });
      await db.insert('wallets', {
        'id': 2,
        'name': 'Cash',
        'color_value': 0xFF4CAF50,
        'icon_code': 0xe850
      });

      // 3. Migrate transactions table to include wallet_id, transfer_wallet_id, and make category_id nullable.
      // Rename old transactions table
      await db.execute('ALTER TABLE transactions RENAME TO temp_transactions');

      // Create new transactions table
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          category_id INTEGER,
          wallet_id INTEGER NOT NULL,
          transfer_wallet_id INTEGER,
          date TEXT NOT NULL,
          note TEXT,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
          FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE CASCADE,
          FOREIGN KEY (transfer_wallet_id) REFERENCES wallets (id) ON DELETE CASCADE
        )
      ''');

      // Copy data from temp_transactions (assign default wallet_id = 1)
      await db.execute('''
        INSERT INTO transactions (id, amount, type, category_id, wallet_id, date, note)
        SELECT id, amount, type, category_id, 1, date, note FROM temp_transactions
      ''');

      // Drop temp table
      await db.execute('DROP TABLE temp_transactions');
    }
  }

  Future<void> _populateDefaultCategories(Database db) async {
    final defaultCategories = [
      CategoryModel(name: 'Food', type: 'expense', iconCode: 0xe540, colorValue: 0xFFFF5722, isSystem: true),
      CategoryModel(name: 'Rent', type: 'expense', iconCode: 0xe318, colorValue: 0xFF3F51B5, isSystem: true),
      CategoryModel(name: 'Utilities', type: 'expense', iconCode: 0xe21d, colorValue: 0xFFFFEB3B, isSystem: true),
      CategoryModel(name: 'Transport', type: 'expense', iconCode: 0xe1d7, colorValue: 0xFF00BCD4, isSystem: true),
      CategoryModel(name: 'Shopping', type: 'expense', iconCode: 0xf37f, colorValue: 0xFFE91E63, isSystem: true),
      CategoryModel(name: 'Entertainment', type: 'expense', iconCode: 0xe40f, colorValue: 0xFF9C27B0, isSystem: true),
      CategoryModel(name: 'Medical', type: 'expense', iconCode: 0xf16c, colorValue: 0xFF4CAF50, isSystem: true),
      CategoryModel(name: 'Other', type: 'expense', iconCode: 0xe3b6, colorValue: 0xFF607D8B, isSystem: true),

      CategoryModel(name: 'Salary', type: 'income', iconCode: 0xe8f4, colorValue: 0xFF2196F3, isSystem: true),
      CategoryModel(name: 'Freelance', type: 'income', iconCode: 0xe32c, colorValue: 0xFF009688, isSystem: true),
      CategoryModel(name: 'Investments', type: 'income', iconCode: 0xe655, colorValue: 0xFF8BC34A, isSystem: true),
      CategoryModel(name: 'Other Income', type: 'income', iconCode: 0xe227, colorValue: 0xFFFFC107, isSystem: true),
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
    }
  }

  Future<void> _populateDefaultWallets(Database db) async {
    await db.insert('wallets', {
      'id': 1,
      'name': 'Main Account',
      'color_value': 0xFF4361EE,
      'icon_code': 0xe1f8
    });
    await db.insert('wallets', {
      'id': 2,
      'name': 'Cash',
      'color_value': 0xFF4CAF50,
      'icon_code': 0xe850
    });
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return CategoryModel.fromMap(maps[i]);
    });
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ? AND is_system = 0', whereArgs: [id]);
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions({
    String? type,
    int? categoryId,
    int? walletId,
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT t.*, c.name as category_name, c.type as category_type, 
             c.icon_code as category_icon, c.color_value as category_color, c.is_system as category_is_system
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
    ''';
    
    List<String> conditions = [];
    List<dynamic> args = [];

    if (type != null && type != 'all') {
      conditions.add('t.type = ?');
      args.add(type);
    }
    if (categoryId != null) {
      conditions.add('t.category_id = ?');
      args.add(categoryId);
    }
    if (walletId != null) {
      conditions.add('(t.wallet_id = ? OR t.transfer_wallet_id = ?)');
      args.add(walletId);
      args.add(walletId);
    }
    if (startDate != null) {
      conditions.add('t.date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add('t.date <= ?');
      args.add(endDate);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ' ORDER BY t.date DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertOrUpdateBudget(BudgetModel budget) async {
    final db = await database;
    
    final List<Map<String, dynamic>> existing = await db.query(
      'budgets',
      where: 'category_id = ? AND month = ?',
      whereArgs: [budget.categoryId, budget.month],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'budgets',
        budget.toMap(),
        where: 'category_id = ? AND month = ?',
        whereArgs: [budget.categoryId, budget.month],
      );
    } else {
      return await db.insert('budgets', budget.toMap());
    }
  }

  Future<List<BudgetModel>> getBudgetsForMonth(String month) async {
    final db = await database;
    
    String query = '''
      SELECT b.*, c.name as category_name, c.type as category_type, 
             c.icon_code as category_icon, c.color_value as category_color, c.is_system as category_is_system
      FROM budgets b
      LEFT JOIN categories c ON b.category_id = c.id
      WHERE b.month = ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [month]);
    return List.generate(maps.length, (i) {
      return BudgetModel.fromMap(maps[i]);
    });
  }

  Future<List<BudgetModel>> getAllBudgets() async {
    final db = await database;
    
    String query = '''
      SELECT b.*, c.name as category_name, c.type as category_type, 
             c.icon_code as category_icon, c.color_value as category_color, c.is_system as category_is_system
      FROM budgets b
      LEFT JOIN categories c ON b.category_id = c.id
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query);
    return List.generate(maps.length, (i) {
      return BudgetModel.fromMap(maps[i]);
    });
  }

  // --- Wallet Operations ---

  Future<int> insertWallet(WalletModel wallet) async {
    final db = await database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<List<WalletModel>> getWallets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('wallets');
    return List.generate(maps.length, (i) {
      return WalletModel.fromMap(maps[i]);
    });
  }

  Future<int> updateWallet(WalletModel wallet) async {
    final db = await database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<int> deleteWallet(int id) async {
    if (id == 1) return 0; // Prevent deleting default wallet
    final db = await database;

    // Re-associate transactions in this wallet to default wallet (id: 1)
    await db.update(
      'transactions',
      {'wallet_id': 1},
      where: 'wallet_id = ?',
      whereArgs: [id],
    );
    await db.update(
      'transactions',
      {'transfer_wallet_id': null},
      where: 'transfer_wallet_id = ?',
      whereArgs: [id],
    );

    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }
}
