import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';

/// Second step of registration: the user enters the 6-digit OTP that was sent to
/// their email. On success the account is created server-side and tokens are
/// returned, logging the user straight into the app.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  static const int _resendCooldown = 60;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final data = await api.post<Map<String, dynamic>>(
        ApiEndpoints.registerVerify,
        data: {'email': widget.email, 'otp': _otpCtrl.text.trim()},
      );

      final storage = ref.read(secureStorageProvider);
      await storage.setTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
        data['user']?['role'] as String?,
      );

      ref.read(authStateProvider.notifier).setLoggedIn(true);
      ref
          .read(userRoleProvider.notifier)
          .setRole(data['user']?['role'] as String?);

      if (mounted) context.go(AppRoutes.home);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = AppStrings.verifyFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        ApiEndpoints.registerResendOtp,
        data: {'email': widget.email},
      );
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.resendOtpSuccess)),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = AppStrings.resendOtpFailed);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                AppStrings.verifyEmailTitle,
                style: AppTypography.heading1(textColor).copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: AppStrings.verifyEmailIntroPrefix,
                  style: AppTypography.bodyMedium(ext.textMuted),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: AppTypography.labelLarge(textColor),
                    ),
                    const TextSpan(text: AppStrings.verifyEmailIntroSuffix),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _error!,
                          style: AppTypography.bodySmall(
                            AppColors.error,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),

                    Text(
                      AppStrings.otpLabel,
                      style: AppTypography.labelLarge(ext.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _otpCtrl,
                      maxLength: AppConstants.otpLength,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '123456',
                        counterText: '',
                        prefixIcon: Icon(
                          Icons.key_rounded,
                          color: ext.textMuted,
                          size: 20,
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) != AppConstants.otpLength
                          ? AppStrings.otpLengthError(AppConstants.otpLength)
                          : null,
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleVerify,
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.verifyAndCompleteButton,
                                    style: AppTypography.button(Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Resend
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        AppStrings.resendCodeCountdown(_secondsLeft),
                        style: AppTypography.bodyMedium(ext.textMuted),
                      )
                    : TextButton(
                        onPressed: _resending ? null : _handleResend,
                        child: _resending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text.rich(
                                TextSpan(
                                  text: AppStrings.resendCodePrompt,
                                  style: AppTypography.bodyMedium(ext.textMuted),
                                  children: [
                                    TextSpan(
                                      text: AppStrings.resendCodeLink,
                                      style: AppTypography.labelLarge(
                                        AppColors.emerald500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
