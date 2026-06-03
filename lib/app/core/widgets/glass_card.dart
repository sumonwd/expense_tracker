import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;

      Widget cardContent = Container(
        decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: borderRadius),
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      );

      if (isDark) {
        cardContent = ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: cardContent,
          ),
        );
      }

      if (onTap != null) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        );
      }

      return cardContent;
    });
  }
}
