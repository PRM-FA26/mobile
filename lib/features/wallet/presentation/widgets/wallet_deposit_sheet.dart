import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/helpers.dart';
import '../../wallet_logic.dart';
import 'wallet_sheet_handle.dart';

class WalletDepositSheet extends StatelessWidget {
  final List<int> amountsVnd;
  final ValueChanged<int> onAmountSelected;

  const WalletDepositSheet({
    super.key,
    required this.amountsVnd,
    required this.onAmountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WalletSheetHandle(),
          const SizedBox(height: 16),
          Text(
            AppStrings.walletDeposit,
            style: AppTypography.heading3(textColor),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.walletDepositPackageHint,
            style: AppTypography.bodyMedium(context.appTheme.textMuted),
          ),
          const SizedBox(height: 16),
          ...amountsVnd.map(
            (amount) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                tileColor: context.appTheme.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.amber500,
                ),
                title: Text(
                  '${formatXu(amount)} VNĐ',
                  style: AppTypography.labelLarge(textColor),
                ),
                subtitle: Text(
                  '= ${vndToXu(amount)} ${AppStrings.walletCoinUnit}',
                  style: AppTypography.bodySmall(AppColors.emerald500),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  onAmountSelected(amount);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
