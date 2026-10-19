import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/wallet_withdraw_request.dart';
import 'wallet_sheet_handle.dart';

typedef WalletWithdrawSubmit =
    Future<void> Function(WalletWithdrawRequest request);

class WalletWithdrawSheet extends StatefulWidget {
  final WalletWithdrawSubmit onSubmit;

  const WalletWithdrawSheet({super.key, required this.onSubmit});

  @override
  State<WalletWithdrawSheet> createState() => _WalletWithdrawSheetState();
}

class _WalletWithdrawSheetState extends State<WalletWithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  final _accountNameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        WalletWithdrawRequest(
          amount: int.parse(_amountController.text.trim()),
          bankName: _bankController.text.trim(),
          accountNumber: _accountController.text.trim(),
          accountName: _accountNameController.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(AppStrings.walletWithdrawFailed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String? _validateAmount(String? value) {
    final amount = int.tryParse(value?.trim() ?? '');
    if (amount == null) return AppStrings.walletWithdrawFieldRequired;
    if (amount < 200) return AppStrings.walletWithdrawMinimumError;
    return null;
  }

  String? _validateRequired(String? value) {
    return value == null || value.trim().isEmpty
        ? AppStrings.walletWithdrawFieldRequired
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WalletSheetHandle(),
              const SizedBox(height: 16),
              Text(
                AppStrings.walletWithdraw,
                style: AppTypography.heading3(textColor),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: _validateAmount,
                decoration: const InputDecoration(
                  labelText: AppStrings.walletWithdrawAmountLabel,
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankController,
                validator: _validateRequired,
                decoration: const InputDecoration(
                  labelText: AppStrings.walletWithdrawBankLabel,
                  prefixIcon: Icon(Icons.account_balance_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountController,
                validator: _validateRequired,
                decoration: const InputDecoration(
                  labelText: AppStrings.walletWithdrawAccountNumberLabel,
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNameController,
                validator: _validateRequired,
                decoration: const InputDecoration(
                  labelText: AppStrings.walletWithdrawAccountNameLabel,
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.walletWithdrawSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
