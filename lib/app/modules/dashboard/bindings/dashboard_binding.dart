import 'package:get/get.dart';
import '../controllers/transaction_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionController>(() => TransactionController());
  }
}
