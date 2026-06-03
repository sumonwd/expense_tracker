import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transaction_controller.dart';
import '../../../core/models/category_model.dart';
import '../../../core/widgets/glass_card.dart';

class ExpenseChart extends StatefulWidget {
  const ExpenseChart({super.key});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final TransactionController txController = Get.find<TransactionController>();

    return Obx(() {
      final transactions = txController.transactions;
      final categories = txController.categories;

      final Map<int, double> categorySums = {};
      double totalExpense = 0.0;

      for (var tx in transactions) {
        if (tx.type == 'expense' && tx.categoryId != null) {
          categorySums[tx.categoryId!] = (categorySums[tx.categoryId!] ?? 0.0) + tx.amount;
          totalExpense += tx.amount;
        }
      }

      if (totalExpense == 0) {
        return const GlassCard(
          child: SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No expenses recorded for this period',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        );
      }

      // Sort by amount descending for the legend
      final sortedForLegend = categorySums.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final List<PieChartSectionData> sections = [];
      for (int i = 0; i < sortedForLegend.length; i++) {
        final entry = sortedForLegend[i];
        final categoryId = entry.key;
        final amount = entry.value;
        final percentage = (amount / totalExpense) * 100;

        final category = categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => CategoryModel(
            name: 'Unknown',
            type: 'expense',
            iconCode: 0xe3b6,
            colorValue: 0xFF607D8B,
          ),
        );

        final isTouched = i == touchedIndex;
        final double radius = isTouched ? 55 : 45;
        final double fontSize = isTouched ? 14 : 11;

        sections.add(
          PieChartSectionData(
            color: category.color,
            value: amount,
            title: isTouched ? '${category.name}\n\$${amount.toStringAsFixed(0)}' : '${percentage.toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }

      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expenses by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text(
              'Top Spending',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3),
            ),
            const SizedBox(height: 12),
            ...sortedForLegend.map((entry) {
              final cat = categories.firstWhere(
                (c) => c.id == entry.key,
                orElse: () => CategoryModel(
                  name: 'Unknown',
                  type: 'expense',
                  iconCode: 0xe3b6,
                  colorValue: 0xFF607D8B,
                ),
              );
              final percentage = (entry.value / totalExpense) * 100;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: Text(
                        cat.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: percentage > 12
                                  ? Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: cat.color,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\$${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
