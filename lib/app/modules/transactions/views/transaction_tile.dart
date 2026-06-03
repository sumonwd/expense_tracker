import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/transaction_model.dart';
import '../../dashboard/controllers/transaction_controller.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final txController = Get.find<TransactionController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cat = transaction.category;
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    
    Color categoryColor = cat?.color ?? Colors.grey;
    IconData categoryIcon = cat?.iconData ?? Icons.help_outline;
    String categoryName = cat?.name ?? 'Unknown';

    String titleText = transaction.note != null && transaction.note!.isNotEmpty
        ? transaction.note!
        : categoryName;

    String subtitleText = DateFormat('MMM dd, yyyy | hh:mm a').format(transaction.date);

    Widget trailingWidget;

    if (isTransfer) {
      categoryColor = const Color(0xFF4361EE);
      categoryIcon = Icons.swap_horiz_rounded;
      
      final sourceWallet = txController.wallets.firstWhereOrNull((w) => w.id == transaction.walletId);
      final destWallet = txController.wallets.firstWhereOrNull((w) => w.id == transaction.transferWalletId);
      final transferDetails = '${sourceWallet?.name ?? 'Account'} ➔ ${destWallet?.name ?? 'Account'}';

      if (transaction.note == null || transaction.note!.isEmpty) {
        titleText = 'Transfer';
      }
      subtitleText += '\n$transferDetails';

      // Dynamic amount sign based on filtered wallet
      final activeWalletId = txController.selectedWalletId.value;
      if (activeWalletId == transaction.walletId) {
        // Outflow from active wallet
        trailingWidget = Text(
          '-\$${transaction.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Color(0xFFF44336),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        );
      } else if (activeWalletId == transaction.transferWalletId) {
        // Inflow to active wallet
        trailingWidget = Text(
          '+\$${transaction.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        );
      } else {
        // Combined views (neutral)
        trailingWidget = Text(
          '\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        );
      }
    } else {
      trailingWidget = Text(
        '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      );
    }

    return Dismissible(
      key: Key('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade900,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        if (onDelete != null) onDelete!();
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: categoryColor.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(
            categoryIcon,
            color: categoryColor,
            size: 22,
          ),
        ),
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          subtitleText,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.3),
        ),
        trailing: trailingWidget,
      ),
    );
  }
}
