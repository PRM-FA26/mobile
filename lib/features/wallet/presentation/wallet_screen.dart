import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../models/wallet_transaction.dart';
import '../models/wallet_withdraw_request.dart';
import '../wallet_logic.dart';
import 'widgets/wallet_balance_card.dart';
import 'widgets/wallet_deposit_sheet.dart';
import 'widgets/wallet_transaction_list.dart';
import 'widgets/wallet_withdraw_sheet.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with WidgetsBindingObserver {
  int _balance = 0;
  List<WalletTransaction> _transactions = const [];
  bool _isLoading = true;
  bool _isDepositing = false;
  String? _errorMessage;
  int? _pendingOrderCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyPendingDeposit();
    }
  }

  /// The payment gateway returns through an external app/browser. When the user
  /// comes back, verify the pending deposit so the balance refreshes promptly.
  Future<void> _verifyPendingDeposit() async {
    final orderCode = _pendingOrderCode;
    if (orderCode == null) {
      await _fetchData(showLoading: false);
      return;
    }

    try {
      final api = ref.read(apiClientProvider);
      final result = await api.get<Map<String, dynamic>>(
        ApiEndpoints.depositVerify,
        queryParameters: {'orderCode': '$orderCode'},
      );

      if (result['status'] == 'PAID') {
        _pendingOrderCode = null;
        _showSnack(
          result['message']?.toString() ?? AppStrings.walletDepositSuccess,
          backgroundColor: AppColors.emerald500,
        );
      }
    } catch (_) {
      // Webhook confirmation may still credit the wallet; refresh below either way.
    } finally {
      await _fetchData(showLoading: false);
    }
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final api = ref.read(apiClientProvider);
      final responses = await Future.wait<dynamic>([
        api.get<Map<String, dynamic>>(ApiEndpoints.wallet),
        api.get<dynamic>(
          ApiEndpoints.transactions,
          queryParameters: {'page': '1', 'limit': '50'},
        ),
      ]);

      final walletData = responses[0] as Map<String, dynamic>;
      final transactionPayload = extractListPayload(responses[1]);
      final transactions = transactionPayload
          .whereType<Map>()
          .map(
            (tx) => WalletTransaction.fromJson(Map<String, dynamic>.from(tx)),
          )
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _balance = readWalletBalance(walletData);
        _transactions = transactions;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      final message = error is ApiException
          ? error.message
          : AppStrings.walletLoadFailed;
      if (!mounted) return;

      if (showLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      } else {
        _showSnack(message, backgroundColor: AppColors.error);
      }
    }
  }

  Future<void> _handleDeposit(int amount) async {
    if (_isDepositing) return;

    setState(() => _isDepositing = true);
    try {
      final api = ref.read(apiClientProvider);
      final result = await api.post<dynamic>(
        ApiEndpoints.deposit,
        data: {'packageVnd': amount},
      );

      if (result is Map) {
        _pendingOrderCode = readIntValue(result['orderCode']);
      }

      final paymentUrl = extractPaymentUrl(result);
      if (paymentUrl == null) {
        _showSnack(
          AppStrings.walletDepositMissingPaymentUrl,
          backgroundColor: AppColors.error,
        );
        return;
      }

      final uri = Uri.tryParse(paymentUrl);
      if (uri == null || !uri.hasScheme) {
        _showSnack(
          AppStrings.walletDepositInvalidPaymentUrl,
          backgroundColor: AppColors.error,
        );
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showSnack(
          AppStrings.walletDepositCannotOpenGateway,
          backgroundColor: AppColors.error,
        );
      }
    } on ApiException catch (e) {
      _showSnack(e.message, backgroundColor: AppColors.error);
    } catch (_) {
      _showSnack(
        AppStrings.walletDepositCreateFailed,
        backgroundColor: AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _isDepositing = false);
    }
  }

  Future<void> _submitWithdraw(WalletWithdrawRequest request) async {
    final api = ref.read(apiClientProvider);
    await api.post(ApiEndpoints.withdraw, data: request.toJson());
    await _fetchData(showLoading: false);
    _showSnack(AppStrings.walletWithdrawRequestSent);
  }

  void _handleWithdraw() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WalletWithdrawSheet(onSubmit: _submitWithdraw),
    );
  }

  void _showDepositSheet(BuildContext context) {
    if (_isDepositing) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => WalletDepositSheet(
        amountsVnd: kDepositPackagesVnd,
        onAmountSelected: _handleDeposit,
      ),
    );
  }

  void _showSnack(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.walletTitle,
          style: AppTypography.heading3(textColor),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _WalletErrorView(message: _errorMessage!, onRetry: _fetchData);
    }

    return Column(
      children: [
        WalletBalanceCard(
          balance: _balance,
          isDepositing: _isDepositing,
          onDepositPressed: () => _showDepositSheet(context),
          onWithdrawPressed: _handleWithdraw,
        ),
        WalletTransactionHeader(count: _transactions.length),
        const SizedBox(height: 8),
        Expanded(child: WalletTransactionList(transactions: _transactions)),
      ],
    );
  }
}

class _WalletErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _WalletErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: context.appTheme.textMuted,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(context.appTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(AppStrings.walletRetry),
            ),
          ],
        ),
      ),
    );
  }
}
