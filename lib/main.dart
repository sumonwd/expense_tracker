import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/core/controllers/theme_controller.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inject global dependencies
  Get.put(ThemeController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      return GetMaterialApp(
        title: 'Personal Expense Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
      );
    });
  }
}
