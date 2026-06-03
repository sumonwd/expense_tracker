part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const DASHBOARD = _Paths.DASHBOARD;
  static const TRANSACTIONS = _Paths.TRANSACTIONS;
  static const ADD_TRANSACTION = _Paths.ADD_TRANSACTION;
  static const BUDGET = _Paths.BUDGET;
  static const BACKUP = _Paths.BACKUP;
}

abstract class _Paths {
  _Paths._();
  static const DASHBOARD = '/';
  static const TRANSACTIONS = '/transactions';
  static const ADD_TRANSACTION = '/add-transaction';
  static const BUDGET = '/budget';
  static const BACKUP = '/backup';
}
