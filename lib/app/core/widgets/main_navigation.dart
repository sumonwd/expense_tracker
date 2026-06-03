import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/dashboard/views/dashboard_page.dart';
import '../../modules/transactions/views/transactions_page.dart';
import '../../modules/budget/views/budget_page.dart';
import '../../modules/backup/views/backup_page.dart';
import '../../routes/app_pages.dart';

class MainNavigationController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainNavigationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = const [
      DashboardPage(),
      TransactionsPage(),
      SizedBox(), // Placeholder for center FAB
      BudgetPage(),
      BackupPage(),
    ];

    return Obx(() {
      final index = controller.currentIndex.value;

      return Scaffold(
        body: IndexedStack(
          index: index >= 2 ? index : index, // skip the FAB placeholder
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161722) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Home',
                    isSelected: index == 0,
                    onTap: () => controller.changePage(0),
                    isDark: isDark,
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Records',
                    isSelected: index == 1,
                    onTap: () => controller.changePage(1),
                    isDark: isDark,
                  ),
                  // Center FAB
                  GestureDetector(
                    onTap: () => Get.toNamed(Routes.ADD_TRANSACTION),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [const Color(0xFF9D4EDD), const Color(0xFFFF007F)]
                              : [const Color(0xFF4361EE), const Color(0xFF3A86FF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? const Color(0xFF9D4EDD) : const Color(0xFF4361EE))
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                  _NavItem(
                    icon: Icons.pie_chart_rounded,
                    label: 'Budget',
                    isSelected: index == 3,
                    onTap: () => controller.changePage(3),
                    isDark: isDark,
                  ),
                  _NavItem(
                    icon: Icons.cloud_sync_rounded,
                    label: 'Backup',
                    isSelected: index == 4,
                    onTap: () => controller.changePage(4),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? const Color(0xFF9D4EDD) : const Color(0xFF4361EE);
    final inactiveColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
              child: Text(label),
            ),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(top: 3),
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
