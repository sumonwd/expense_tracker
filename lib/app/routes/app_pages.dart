import 'package:get/get.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/transactions/views/transactions_page.dart';
import '../modules/add_transaction/views/add_transaction_page.dart';
import '../modules/budget/views/budget_page.dart';
import '../modules/backup/views/backup_page.dart';
import '../core/widgets/main_navigation.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.DASHBOARD;

  static final routes = [
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const MainNavigation(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: _Paths.TRANSACTIONS,
      page: () => const TransactionsPage(),
    ),
    GetPage(
      name: _Paths.ADD_TRANSACTION,
      page: () => const AddTransactionPage(),
    ),
    GetPage(
      name: _Paths.BUDGET,
      page: () => const BudgetPage(),
    ),
    GetPage(
      name: _Paths.BACKUP,
      page: () => const BackupPage(),
    ),
  ];
}
