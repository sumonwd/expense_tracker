import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/budget_model.dart';
import '../../dashboard/controllers/transaction_controller.dart';

class BudgetController extends GetxController {
  final DBHelper _dbHelper = DBHelper();
  final TransactionController _txController = Get.find<TransactionController>();

  var budgets = <BudgetModel>[].obs;
  var currentMonth = ''.obs;
  var isLoading = false.obs;

  var categorySpending = <int, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    currentMonth.value = DateFormat('yyyy-MM').format(DateTime.now());
    loadBudgetData();
    
    ever(_txController.transactions, (_) => loadBudgetData());
  }

  Future<void> loadBudgetData() async {
    isLoading.value = true;
    try {
      await fetchBudgets();
      await calculateSpending();
    } finally {
      isLoading.value = false;
    }
  }

  void changeMonth(String month) {
    currentMonth.value = month;
    loadBudgetData();
  }

  Future<void> fetchBudgets() async {
    final list = await _dbHelper.getBudgetsForMonth(currentMonth.value);
    budgets.assignAll(list);
  }

  Future<void> calculateSpending() async {
    final startOfMonth = '${currentMonth.value}-01';
    
    final year = int.parse(currentMonth.value.split('-')[0]);
    final month = int.parse(currentMonth.value.split('-')[1]);
    final lastDay = DateTime(year, month + 1, 0).day;
    final endOfMonth = '${currentMonth.value}-$lastDay 23:59:59';

    final monthTxs = await _dbHelper.getTransactions(
      type: 'expense',
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    final Map<int, double> spending = {};
    for (var tx in monthTxs) {
      if (tx.categoryId != null) {
        spending[tx.categoryId!] = (spending[tx.categoryId!] ?? 0.0) + tx.amount;
      }
    }
    categorySpending.assignAll(spending);
  }

  Future<void> setBudget(int categoryId, double amount) async {
    final budget = BudgetModel(
      categoryId: categoryId,
      amount: amount,
      month: currentMonth.value,
    );
    await _dbHelper.insertOrUpdateBudget(budget);
    await loadBudgetData();
  }

  double getSpendingForCategory(int categoryId) {
    return categorySpending[categoryId] ?? 0.0;
  }

  double getProgressForBudget(BudgetModel budget) {
    if (budget.amount == 0) return 0.0;
    return getSpendingForCategory(budget.categoryId) / budget.amount;
  }
}
