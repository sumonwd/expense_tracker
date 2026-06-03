import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../dashboard/controllers/transaction_controller.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/models/wallet_model.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TransactionController txController = Get.find<TransactionController>();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _transactionType = 'expense';
  int? _selectedCategoryId;
  int _selectedWalletId = 1;
  int _selectedTransferWalletId = 2;
  DateTime _selectedDate = DateTime.now();

  @override
  void onInit() {
    // If selectedWalletId is set in controller, default to that wallet
    final activeWalletId = txController.selectedWalletId.value;
    if (activeWalletId != null) {
      _selectedWalletId = activeWalletId;
      // Make sure destination wallet is different
      if (_selectedWalletId == _selectedTransferWalletId) {
        _selectedTransferWalletId = _selectedWalletId == 1 ? 2 : 1;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallets = txController.wallets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Record'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Transaction Type Toggle Options
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTypeToggleOption('Expense', 'expense', const Color(0xFFF44336)),
                      _buildTypeToggleOption('Income', 'income', const Color(0xFF4CAF50)),
                      _buildTypeToggleOption('Transfer', 'transfer', const Color(0xFF4361EE)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Amount Input Card
              GlassCard(
                child: Column(
                  children: [
                    const Text(
                      'AMOUNT',
                      style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        prefixText: '\$ ',
                        border: InputBorder.none,
                        prefixStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Wallet / Account Selectors
              if (_transactionType != 'transfer') ...[
                _buildWalletSelector(
                  label: 'Account / Wallet',
                  selectedId: _selectedWalletId,
                  wallets: wallets,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedWalletId = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildWalletSelector(
                        label: 'From Account',
                        selectedId: _selectedWalletId,
                        wallets: wallets,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedWalletId = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildWalletSelector(
                        label: 'To Account',
                        selectedId: _selectedTransferWalletId,
                        wallets: wallets,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTransferWalletId = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // 4. Category Selector (Hidden for Transfers)
              if (_transactionType != 'transfer') ...[
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final filteredCats = txController.categories
                      .where((c) => c.type == _transactionType)
                      .toList();

                  if (filteredCats.isEmpty) {
                    return const Center(child: Text('No categories available'));
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: filteredCats.length,
                    itemBuilder: (context, index) {
                      final cat = filteredCats[index];
                      final isSelected = _selectedCategoryId == cat.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = cat.id;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? cat.color.withOpacity(0.15) 
                                : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? cat.color : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cat.color.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cat.iconData,
                                  color: cat.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected 
                                      ? (isDark ? Colors.white : Colors.black87) 
                                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 24),
              ],

              // 5. Details Section (Date & Notes)
              const Text(
                'Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                        ),
                      ],
                    ),
                    Divider(color: isDark ? Colors.white10 : Colors.black12),
                    TextFormField(
                      controller: _noteController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Add a note/description...',
                        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                        border: InputBorder.none,
                        icon: const Icon(Icons.edit_note, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6. Save Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saveRecord,
                  child: const Text(
                    'Save Transaction',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggleOption(String label, String type, Color activeColor) {
    final isSelected = _transactionType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = type;
          _selectedCategoryId = null; 
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : (Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey.shade600),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildWalletSelector({
    required String label,
    required int selectedId,
    required List<WalletModel> wallets,
    required ValueChanged<int?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Ensure selectedId exists in wallets, otherwise fallback to first
    final activeId = wallets.any((w) => w.id == selectedId) ? selectedId : wallets.first.id!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: activeId,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF161722) : Colors.white,
              items: wallets.map((w) {
                return DropdownMenuItem<int>(
                  value: w.id,
                  child: Row(
                    children: [
                      Icon(w.iconData, color: w.color, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        w.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final isTransfer = _transactionType == 'transfer';

    if (!isTransfer && _selectedCategoryId == null) {
      Get.snackbar('Validation Error', 'Please select a category.');
      return;
    }

    if (isTransfer && _selectedWalletId == _selectedTransferWalletId) {
      Get.snackbar('Validation Error', 'Source and destination wallets must be different.');
      return;
    }

    final double amount = double.parse(_amountController.text);
    final String note = _noteController.text.trim();

    final now = DateTime.now();
    final txDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    await txController.addTransaction(
      amount: amount,
      type: _transactionType,
      categoryId: isTransfer ? null : _selectedCategoryId,
      walletId: _selectedWalletId,
      transferWalletId: isTransfer ? _selectedTransferWalletId : null,
      date: txDate,
      note: note.isEmpty ? null : note,
    );

    Get.back();
  }
}
