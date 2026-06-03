import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transaction_controller.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/widgets/glass_card.dart';
import 'expense_chart.dart';
import 'trend_chart.dart';
import '../../transactions/views/transaction_tile.dart';
import '../../../routes/app_pages.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TransactionController txController = Get.find<TransactionController>();
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        leading: Obx(() => IconButton(
          icon: Icon(themeController.isDarkMode.value ? Icons.light_mode : Icons.dark_mode),
          onPressed: themeController.toggleTheme,
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () => Get.toNamed(Routes.BACKUP),
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart_outline),
            onPressed: () => Get.toNamed(Routes.BUDGET),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => txController.loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Wallets Carousel Slider
              const Text(
                'My Accounts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: Obx(() {
                  final wallets = txController.wallets;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: wallets.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = txController.selectedWalletId.value == null;
                        return _buildWalletCard(
                          context,
                          name: 'All Accounts',
                          balance: wallets.fold<double>(0, (sum, w) => sum + w.balance),
                          color: const Color(0xFF4361EE),
                          iconData: Icons.all_inbox_rounded,
                          isSelected: isSelected,
                          onTap: () {
                            txController.selectedWalletId.value = null;
                            txController.loadTransactions();
                          },
                        );
                      } else if (index == wallets.length + 1) {
                        return _buildAddWalletCard(context);
                      }

                      final wallet = wallets[index - 1];
                      final isSelected = txController.selectedWalletId.value == wallet.id;
                      return _buildWalletCard(
                        context,
                        name: wallet.name,
                        balance: wallet.balance,
                        color: wallet.color,
                        iconData: wallet.iconData,
                        isSelected: isSelected,
                        onTap: () {
                          txController.selectedWalletId.value = wallet.id;
                          txController.loadTransactions();
                        },
                        onLongPress: () {
                          if (wallet.id != 1) {
                            _showDeleteWalletConfirm(context, wallet.id!, wallet.name);
                          }
                        },
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),

              // 2. Budget Alerts Banner
              Obx(() {
                final alerts = txController.budgetAlerts;
                if (alerts.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: alerts.map((alert) {
                      final isWarning = alert.startsWith('Budget Warning');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isWarning ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
                              color: isWarning ? Colors.orange : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alert,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.red.shade200 
                                      : Colors.red.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),

              // 3. Balance Summary Card
              Obx(() => GlassCard(
                child: Column(
                  children: [
                    const Text(
                      'TOTAL BALANCE',
                      style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${txController.netBalance.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: themeController.isDarkMode.value ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryColumn(
                          label: 'INCOME',
                          amount: txController.totalIncome.value,
                          color: const Color(0xFF4CAF50),
                          icon: Icons.arrow_upward,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: themeController.isDarkMode.value ? Colors.white24 : Colors.black12,
                        ),
                        _buildSummaryColumn(
                          label: 'EXPENSES',
                          amount: txController.totalExpense.value,
                          color: const Color(0xFFF44336),
                          icon: Icons.arrow_downward,
                        ),
                      ],
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),

              const TrendChart(),
              const SizedBox(height: 24),
              const ExpenseChart(),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(Routes.TRANSACTIONS),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() {
                final recents = txController.recentTransactions;
                if (recents.isEmpty) {
                  return const GlassCard(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No transactions yet. Tap the + to add one!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recents.length,
                  itemBuilder: (context, index) {
                    final tx = recents[index];
                    return TransactionTile(
                      transaction: tx,
                      onDelete: () => txController.deleteTransaction(tx.id!),
                    );
                  },
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Get.toNamed(Routes.ADD_TRANSACTION),
      ),
    );
  }

  Widget _buildWalletCard(
    BuildContext context, {
    required String name,
    required double balance,
    required Color color,
    required IconData iconData,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 175,
        margin: const EdgeInsets.only(right: 12.0, bottom: 4.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(isSelected ? 0.65 : 0.25),
              color.withOpacity(isSelected ? 0.35 : 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.9)
                : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  iconData,
                  color: isSelected ? color : (isDark ? Colors.white60 : Colors.black54),
                  size: 18,
                ),
              ],
            ),
            const Text(
              '•••• 4242',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddWalletCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showAddWalletDialog(context),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12.0, bottom: 4.0),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_card_rounded,
              color: isDark ? Colors.white30 : Colors.black38,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              'Add Wallet',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final List<int> colors = [
      0xFF4361EE, // Blue
      0xFF4CAF50, // Green
      0xFF9D4EDD, // Purple
      0xFFFF9100, // Orange
      0xFFFF007F, // Pink
      0xFF00BFA5, // Teal
    ];
    int selectedColor = colors[0];

    final List<int> icons = [
      0xe1f8, // credit_card
      0xe850, // account_balance_wallet
      0xe041, // account_balance
      0xe2c6, // savings
    ];
    int selectedIcon = icons[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              title: const Text('Create Wallet'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Wallet Name',
                        hintText: 'e.g. Savings, Card',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Card Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: colors.map((colValue) {
                        final col = Color(colValue);
                        final isSel = selectedColor == colValue;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = colValue),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Card Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: icons.map((iconVal) {
                        final isSel = selectedIcon == iconVal;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = iconVal),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? Color(selectedColor).withOpacity(0.2)
                                  : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? Color(selectedColor) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              IconData(iconVal, fontFamily: 'MaterialIcons'),
                              color: isSel ? Color(selectedColor) : Colors.grey,
                              size: 20,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar('Error', 'Please enter a wallet name.');
                      return;
                    }
                    final txController = Get.find<TransactionController>();
                    await txController.addWallet(name, selectedColor, selectedIcon);
                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteWalletConfirm(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Wallet'),
          content: Text('Are you sure you want to delete "$name"? All transactions in this wallet will be moved to the "Main Account" to prevent data loss.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final txController = Get.find<TransactionController>();
                await txController.deleteWallet(id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, letterSpacing: 1.0, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
