import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeController extends GetxController {
  final _storage = const FlutterSecureStorage();
  final _key = 'isDarkMode';

  RxBool isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final stored = await _storage.read(key: _key);
    if (stored != null) {
      isDarkMode.value = stored == 'true';
    } else {
      isDarkMode.value = true;
    }
    _updateTheme();
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _storage.write(key: _key, value: isDarkMode.value.toString());
    _updateTheme();
  }

  void _updateTheme() {
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}
