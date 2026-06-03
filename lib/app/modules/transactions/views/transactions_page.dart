import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../dashboard/controllers/transaction_controller.dart';
import 'transaction_tile.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TransactionController txController = Get.find<TransactionController>();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: () {
              searchController.clear();
              txController.clearFilters();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Income', 'income'),
                const SizedBox(width: 8),
                _buildFilterChip('Expense', 'expense'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _showDateRangePicker,
                ),
              ],
            ),
          ),

          Obx(() {
            if (txController.filterStartDate.value != null || txController.filterEndDate.value != null) {
              final start = txController.filterStartDate.value != null
                  ? DateFormat('MM/dd').format(txController.filterStartDate.value!)
                  : 'Start';
              final end = txController.filterEndDate.value != null
                  ? DateFormat('MM/dd').format(txController.filterEndDate.value!)
                  : 'End';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Chip(
                      label: Text('Range: $start - $end'),
                      onDeleted: () {
                        txController.filterStartDate.value = null;
                        txController.filterEndDate.value = null;
                        txController.loadTransactions();
                      },
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: Obx(() {
              final categories = txController.categories;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = txController.filterCategoryId.value == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: const Text('All Categories'),
                        onSelected: (_) {
                          txController.filterCategoryId.value = null;
                          txController.loadTransactions();
                        },
                      ),
                    );
                  }
                  final cat = categories[index - 1];
                  final isSelected = txController.filterCategoryId.value == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        children: [
                          Icon(cat.iconData, size: 14, color: cat.color),
                          const SizedBox(width: 4),
                          Text(cat.name),
                        ],
                      ),
                      onSelected: (_) {
                        txController.filterCategoryId.value = cat.id;
                        txController.loadTransactions();
                      },
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Obx(() {
              final filteredTxs = txController.transactions.where((tx) {
                final matchesSearch = tx.note?.toLowerCase().contains(searchQuery) ?? false;
                final matchesCategory = tx.category?.name.toLowerCase().contains(searchQuery) ?? false;
                return searchQuery.isEmpty || matchesSearch || matchesCategory;
              }).toList();

              if (txController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (filteredTxs.isEmpty) {
                return const Center(
                  child: Text('No transactions found.', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: filteredTxs.length,
                itemBuilder: (context, index) {
                  final tx = filteredTxs[index];
                  return TransactionTile(
                    transaction: tx,
                    onDelete: () => txController.deleteTransaction(tx.id!),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    return Obx(() {
      final isSelected = txController.filterType.value == type;
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            txController.filterType.value = type;
            txController.loadTransactions();
          }
        },
      );
    });
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      initialDateRange: txController.filterStartDate.value != null && txController.filterEndDate.value != null
          ? DateTimeRange(start: txController.filterStartDate.value!, end: txController.filterEndDate.value!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (range != null) {
      txController.filterStartDate.value = range.start;
      txController.filterEndDate.value = range.end;
      txController.loadTransactions();
    }
  }
}
