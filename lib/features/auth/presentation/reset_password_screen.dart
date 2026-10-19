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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': widget.email,
          'otp': _otpCtrl.text.trim(),
          'newPassword': _passCtrl.text,
        },
      );
      setState(() => _success = true);

      Future.delayed(AppConstants.resetPasswordRedirectDelay, () {
        if (mounted) context.go(AppRoutes.login);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = AppStrings.resetPasswordFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
              Text(AppStrings.resetPasswordTitle, style: AppTypography.heading1(textColor).copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                AppStrings.resetPasswordSubtitle,
                style: AppTypography.bodyMedium(ext.textMuted),
              ),
              const SizedBox(height: 36),

              if (_success)
                _buildSuccess(context)
              else
                _buildForm(context, ext, textColor),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.emerald500.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_rounded, color: AppColors.emerald500, size: 36),
        ),
        const SizedBox(height: 20),
        Text(AppStrings.resetPasswordSuccessTitle, style: AppTypography.heading3(
          Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        )),
        const SizedBox(height: 8),
        Text(
          AppStrings.resetPasswordSuccessMessage,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium(context.appTheme.textMuted),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text(AppStrings.loginNowButton),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AppThemeExtension ext, Color textColor) {
    return Form(
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
              child: Text(_error!, style: AppTypography.bodySmall(AppColors.error).copyWith(fontWeight: FontWeight.w600)),
            ),

          // Email (disabled)
          Text(AppStrings.emailLabel, style: AppTypography.labelLarge(ext.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.email,
            enabled: false,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.mail_outline, color: ext.textMuted, size: 20),
            ),
          ),

          const SizedBox(height: 20),

          // OTP
          Text(AppStrings.otpLabel, style: AppTypography.labelLarge(ext.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otpCtrl,
            maxLength: AppConstants.otpLength,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              prefixIcon: Icon(Icons.key_rounded, color: ext.textMuted, size: 20),
            ),
            validator: (v) => (v?.length ?? 0) != AppConstants.otpLength ? AppStrings.otpLengthError(AppConstants.otpLength) : null,
          ),

          const SizedBox(height: 20),

          // New Password
          Text(AppStrings.newPasswordLabel, style: AppTypography.labelLarge(ext.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline, color: ext.textMuted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: ext.textMuted, size: 20),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return AppStrings.passwordRequired;
              if (v.length < 6) return AppStrings.passwordMinLengthShort;
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Confirm
          Text(AppStrings.confirmPasswordLabel, style: AppTypography.labelLarge(ext.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline, color: ext.textMuted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: ext.textMuted, size: 20),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) => v != _passCtrl.text ? AppStrings.confirmPasswordMismatch : null,
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleSubmit,
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(AppStrings.updatePasswordButton, style: AppTypography.button(Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
