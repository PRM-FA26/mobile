import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/reader_theme.dart';

/// Shown instead of chapter content when the chapter is premium and locked.
class ReaderPremiumGate extends StatelessWidget {
  final ReaderColors colors;
  final int price;
  final VoidCallback onPurchase;
  final VoidCallback onBack;

  const ReaderPremiumGate({
    super.key,
    required this.colors,
    required this.price,
    required this.onPurchase,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 40, color: AppColors.amber500),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.readerPremiumTitle,
              style: TextStyle(color: colors.text, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.readerPremiumHint(price),
              style: TextStyle(color: colors.text.withValues(alpha: 0.7), fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onPurchase,
                icon: const Icon(Icons.monetization_on_rounded),
                label: Text(AppStrings.readerBuyChapterButton(price)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber500),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onBack,
              child: Text(AppStrings.readerBackButton, style: TextStyle(color: colors.accent)),
            ),
          ],
        ),
      ),
    );
  }
}
