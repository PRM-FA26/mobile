import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/helpers.dart';
import '../../models/wallet_transaction.dart';

class WalletTransactionHeader extends StatelessWidget {
  final int count;

  const WalletTransactionHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            AppStrings.walletTransactionHistory,
            style: AppTypography.heading3(textColor),
          ),
          const Spacer(),
          Text(
            AppStrings.walletTransactionCount(count),
            style: AppTypography.bodySmall(context.appTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class WalletTransactionList extends StatelessWidget {
  final List<WalletTransaction> transactions;

  const WalletTransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          AppStrings.walletNoTransactions,
          style: AppTypography.bodyMedium(context.appTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: transactions.length,
      itemBuilder: (_, index) =>
          WalletTransactionTile(transaction: transactions[index]),
    );
  }
}

class WalletTransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const WalletTransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _visualForType(context, transaction.type);
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(visual.icon, color: visual.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge(textColor),
                ),
                Text(
                  formatRelativeTime(transaction.createdAt),
                  style: AppTypography.bodySmall(ext.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.isIncoming ? '+' : '-'}'
                '${formatXu(transaction.amount.abs())} '
                '${AppStrings.walletCoinUnit}',
                style: AppTypography.labelLarge(
                  transaction.isIncoming
                      ? AppColors.emerald500
                      : AppColors.error,
                ),
              ),
              if (transaction.status.isNotEmpty)
                Text(
                  transaction.status,
                  style: AppTypography.bodySmall(
                    ext.textMuted,
                  ).copyWith(fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }

  _TransactionVisual _visualForType(BuildContext context, String type) {
    switch (type) {
      case 'DEPOSIT':
        return const _TransactionVisual(
          icon: Icons.add_circle_rounded,
          color: AppColors.emerald500,
        );
      case 'WITHDRAWAL':
        return const _TransactionVisual(
          icon: Icons.upload_rounded,
          color: AppColors.info,
        );
      case 'UNLOCK':
        return const _TransactionVisual(
          icon: Icons.shopping_cart_rounded,
          color: AppColors.amber500,
        );
      case 'DONATE':
        return const _TransactionVisual(
          icon: Icons.favorite_rounded,
          color: AppColors.error,
        );
      default:
        return _TransactionVisual(
          icon: Icons.swap_horiz_rounded,
          color: context.appTheme.textMuted,
        );
    }
  }
}

class _TransactionVisual {
  final IconData icon;
  final Color color;

  const _TransactionVisual({required this.icon, required this.color});
}
