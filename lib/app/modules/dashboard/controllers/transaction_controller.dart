import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/wallet_model.dart';

class TransactionController extends GetxController {
  final DBHelper _dbHelper = DBHelper();

  var transactions = <TransactionModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var wallets = <WalletModel>[].obs;
  var isLoading = false.obs;

  var filterType = 'all'.obs;
  var filterCategoryId = RxnInt();
  var filterStartDate = Rxn<DateTime>();
  var filterEndDate = Rxn<DateTime>();

  var selectedWalletId = RxnInt(); // null means "All Wallets"

  var netBalance = 0.0.obs;
  var totalIncome = 0.0.obs;
  var totalExpense = 0.0.obs;

  var budgetAlerts = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    isLoading.value = true;
    try {
      await loadWallets();
      await loadCategories();
      await loadTransactions();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadWallets() async {
    final list = await _dbHelper.getWallets();
    wallets.assignAll(list);
  }

  Future<void> loadCategories() async {
    final list = await _dbHelper.getCategories();
    categories.assignAll(list);
  }

  Future<void> loadTransactions() async {
    String? startStr = filterStartDate.value != null
        ? DateTime(filterStartDate.value!.year, filterStartDate.value!.month, filterStartDate.value!.day, 0, 0, 0).toIso8601String()
        : null;
    String? endStr = filterEndDate.value != null
        ? DateTime(filterEndDate.value!.year, filterEndDate.value!.month, filterEndDate.value!.day, 23, 59, 59).toIso8601String()
        : null;

    final list = await _dbHelper.getTransactions(
      type: filterType.value == 'all' ? null : filterType.value,
      categoryId: filterCategoryId.value,
      walletId: selectedWalletId.value,
      startDate: startStr,
      endDate: endStr,
    );
    transactions.assignAll(list);
    await calculateWalletBalances();
    _calculateStats();
    await checkBudgetAlerts();
  }

  Future<void> calculateWalletBalances() async {
    final allTxs = await _dbHelper.getTransactions();
    
    final Map<int, double> balances = {};
    for (var w in wallets) {
      balances[w.id!] = 0.0;
    }

    for (var tx in allTxs) {
      if (tx.type == 'income') {
        if (balances.containsKey(tx.walletId)) {
          balances[tx.walletId] = balances[tx.walletId]! + tx.amount;
        }
      } else if (tx.type == 'expense') {
        if (balances.containsKey(tx.walletId)) {
          balances[tx.walletId] = balances[tx.walletId]! - tx.amount;
        }
      } else if (tx.type == 'transfer' && tx.transferWalletId != null) {
        if (balances.containsKey(tx.walletId)) {
          balances[tx.walletId] = balances[tx.walletId]! - tx.amount;
        }
        if (balances.containsKey(tx.transferWalletId!)) {
          balances[tx.transferWalletId!] = balances[tx.transferWalletId!]! + tx.amount;
        }
      }
    }

    for (int i = 0; i < wallets.length; i++) {
      final w = wallets[i];
      final newBalance = balances[w.id] ?? 0.0;
      wallets[i] = WalletModel(
        id: w.id,
        name: w.name,
        colorValue: w.colorValue,
        iconCode: w.iconCode,
        balance: newBalance,
      );
    }
  }

  void _calculateStats() {
    double income = 0.0;
    double expense = 0.0;

    final activeWalletId = selectedWalletId.value;

    if (activeWalletId == null) {
      for (var tx in transactions) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else if (tx.type == 'expense') {
          expense += tx.amount;
        }
      }
      totalIncome.value = income;
      totalExpense.value = expense;
      netBalance.value = income - expense;
    } else {
      for (var tx in transactions) {
        if (tx.type == 'income' && tx.walletId == activeWalletId) {
          income += tx.amount;
        } else if (tx.type == 'expense' && tx.walletId == activeWalletId) {
          expense += tx.amount;
        } else if (tx.type == 'transfer') {
          if (tx.walletId == activeWalletId) {
            expense += tx.amount;
          } else if (tx.transferWalletId == activeWalletId) {
            income += tx.amount;
          }
        }
      }
      totalIncome.value = income;
      totalExpense.value = expense;
      netBalance.value = income - expense;
    }
  }

  Future<void> addTransaction({
    required double amount,
    required String type,
    int? categoryId,
    required int walletId,
    int? transferWalletId,
    required DateTime date,
    String? note,
  }) async {
    final tx = TransactionModel(
      amount: amount,
      type: type,
      categoryId: categoryId,
      walletId: walletId,
      transferWalletId: transferWalletId,
      date: date,
      note: note,
    );
    await _dbHelper.insertTransaction(tx);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
    await loadTransactions();
  }

  Future<void> addCustomCategory(String name, String type, int iconCode, int colorValue) async {
    final cat = CategoryModel(
      name: name,
      type: type,
      iconCode: iconCode,
      colorValue: colorValue,
      isSystem: false,
    );
    await _dbHelper.insertCategory(cat);
    await loadCategories();
  }

  Future<void> addWallet(String name, int colorValue, int iconCode) async {
    final wallet = WalletModel(
      name: name,
      colorValue: colorValue,
      iconCode: iconCode,
    );
    await _dbHelper.insertWallet(wallet);
    await loadWallets();
    await loadTransactions();
  }

  Future<void> deleteWallet(int id) async {
    await _dbHelper.deleteWallet(id);
    if (selectedWalletId.value == id) {
      selectedWalletId.value = null;
    }
    await loadWallets();
    await loadTransactions();
  }

  Future<void> checkBudgetAlerts() async {
    final now = DateTime.now();
    final monthStr = DateFormat('yyyy-MM').format(now);
    final budgets = await _dbHelper.getBudgetsForMonth(monthStr);

    final currentMonthTxs = await _dbHelper.getTransactions(
      startDate: DateTime(now.year, now.month, 1, 0, 0, 0).toIso8601String(),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String(),
    );

    final Map<int, double> spent = {};
    for (var tx in currentMonthTxs) {
      if (tx.type == 'expense' && tx.categoryId != null) {
        spent[tx.categoryId!] = (spent[tx.categoryId!] ?? 0.0) + tx.amount;
      }
    }

    final List<String> alerts = [];
    for (var b in budgets) {
      final categorySpent = spent[b.categoryId] ?? 0.0;
      if (b.amount > 0) {
        final percent = categorySpent / b.amount;
        if (percent >= 1.0) {
          alerts.add('Budget Exceeded: You spent \$${categorySpent.toStringAsFixed(2)} of \$${b.amount.toStringAsFixed(2)} limit in ${b.category?.name ?? 'Category'}.');
        } else if (percent >= 0.8) {
          alerts.add('Budget Warning: Spent ${(percent * 100).toStringAsFixed(0)}% (\$${categorySpent.toStringAsFixed(2)} of \$${b.amount.toStringAsFixed(2)}) in ${b.category?.name ?? 'Category'}.');
        }
      }
    }
    budgetAlerts.assignAll(alerts);
  }

  List<TransactionModel> get recentTransactions {
    return transactions.take(5).toList();
  }

  void clearFilters() {
    filterType.value = 'all';
    filterCategoryId.value = null;
    filterStartDate.value = null;
    filterEndDate.value = null;
    loadTransactions();
  }
}
