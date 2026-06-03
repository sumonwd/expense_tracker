import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/budget_controller.dart';
import '../../dashboard/controllers/transaction_controller.dart';
import '../../../core/widgets/glass_card.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BudgetController budgetController = Get.put(BudgetController());
    final TransactionController txController = Get.find<TransactionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _adjustMonth(budgetController, -1),
                ),
                Obx(() {
                  final date = DateFormat('yyyy-MM').parse(budgetController.currentMonth.value);
                  final display = DateFormat('MMMM yyyy').format(date);
                  return Text(
                    display,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _adjustMonth(budgetController, 1),
                ),
              ],
            ),
          ),

          Expanded(
            child: Obx(() {
              final expenseCategories = txController.categories
                  .where((c) => c.type == 'expense')
                  .toList();

              if (budgetController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (expenseCategories.isEmpty) {
                return const Center(child: Text('No expense categories found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: expenseCategories.length,
                itemBuilder: (context, index) {
                  final cat = expenseCategories[index];

                  final budgetList = budgetController.budgets.where((b) => b.categoryId == cat.id).toList();
                  final budget = budgetList.isNotEmpty ? budgetList.first : null;

                  final spent = budgetController.getSpendingForCategory(cat.id!);
                  final limit = budget?.amount ?? 0.0;
                  final hasBudget = limit > 0;
                  final double percent = hasBudget ? (spent / limit) : 0.0;

                  Color progressColor = const Color(0xFF4CAF50);
                  if (percent > 0.9) {
                    progressColor = const Color(0xFFF44336);
                  } else if (percent > 0.75) {
                    progressColor = Colors.orange;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cat.color.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(cat.iconData, color: cat.color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => _showSetBudgetDialog(context, budgetController, cat.id!, limit),
                                child: Text(hasBudget ? 'Edit Limit' : 'Set Limit'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent: \$${spent.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              Text(
                                hasBudget ? 'Limit: \$${limit.toStringAsFixed(2)}' : 'No Limit Set',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          if (hasBudget) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent > 1.0 ? 1.0 : percent,
                                color: progressColor,
                                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                     ? Colors.white10 
                                     : Colors.black.withOpacity(0.06),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${(percent * 100).toStringAsFixed(0)}% Used',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: progressColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _adjustMonth(BudgetController controller, int shift) {
    final date = DateFormat('yyyy-MM').parse(controller.currentMonth.value);
    final newDate = DateTime(date.year, date.month + shift);
    controller.changeMonth(DateFormat('yyyy-MM').format(newDate));
  }

  void _showSetBudgetDialog(
    BuildContext context,
    BudgetController controller,
    int categoryId,
    double currentLimit,
  ) {
    final TextEditingController textController = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Monthly Limit'),
          content: TextField(
            controller: textController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Enter monthly limit amount',
              prefixText: '\$ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final double? amt = double.tryParse(textController.text);
                if (amt != null && amt >= 0) {
                  controller.setBudget(categoryId, amt);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
