import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/transaction_controller.dart';
import '../../../core/widgets/glass_card.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final TransactionController txController = Get.find<TransactionController>();

    return Obx(() {
      final transactions = txController.transactions;

      final List<DateTime> months = List.generate(6, (index) {
        return DateTime.now().subtract(Duration(days: 30 * index));
      }).reversed.toList();

      final List<BarChartGroupData> barGroups = [];
      double maxVal = 100.0;

      for (int i = 0; i < months.length; i++) {
        final monthDate = months[i];
        final monthStr = DateFormat('yyyy-MM').format(monthDate);

        double incomeSum = 0.0;
        double expenseSum = 0.0;

        for (var tx in transactions) {
          final txMonthStr = DateFormat('yyyy-MM').format(tx.date);
          if (txMonthStr == monthStr) {
            if (tx.type == 'income') {
              incomeSum += tx.amount;
            } else {
              expenseSum += tx.amount;
            }
          }
        }

        if (incomeSum > maxVal) maxVal = incomeSum;
        if (expenseSum > maxVal) maxVal = expenseSum;

        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: incomeSum,
                color: const Color(0xFF4CAF50),
                width: 8,
                borderRadius: BorderRadius.circular(2),
              ),
              BarChartRodData(
                toY: expenseSum,
                color: const Color(0xFFF44336),
                width: 8,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        );
      }

      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cash Flow Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.1,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MMM').format(months[idx]),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 4),
                const Text('Income', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: const Color(0xFFF44336), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 4),
                const Text('Expense', style: TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      );
    });
  }
}
