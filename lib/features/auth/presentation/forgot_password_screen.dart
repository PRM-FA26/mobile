import 'package:flutter/material.dart';
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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        ApiEndpoints.forgotPassword,
        data: {'email': _emailCtrl.text.trim()},
      );
      setState(() => _success = true);

      // Auto-redirect after 2s
      Future.delayed(AppConstants.forgotPasswordRedirectDelay, () {
        if (mounted) {
          context.push(AppRoutes.resetPasswordWithEmail(_emailCtrl.text.trim()));
        }
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = AppStrings.forgotPasswordFailed);
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
              Text(AppStrings.forgotPasswordTitle, style: AppTypography.heading1(textColor).copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                AppStrings.forgotPasswordSubtitle,
                style: AppTypography.bodyMedium(ext.textMuted),
              ),
              const SizedBox(height: 36),

              if (_success)
                _SuccessView(email: _emailCtrl.text.trim())
              else
                _FormView(
                  formKey: _formKey,
                  emailCtrl: _emailCtrl,
                  loading: _loading,
                  error: _error,
                  onSubmit: _handleSubmit,
                ),

              const SizedBox(height: 32),

              // Back to login
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text.rich(
                    TextSpan(
                      text: AppStrings.rememberedPasswordPrompt,
                      style: AppTypography.bodyMedium(ext.textMuted),
                      children: [
                        TextSpan(
                          text: AppStrings.loginNowButton,
                          style: AppTypography.labelLarge(AppColors.emerald500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(error!, style: AppTypography.bodySmall(AppColors.error).copyWith(fontWeight: FontWeight.w600)),
            ),

          Text(AppStrings.emailLabel, style: AppTypography.labelLarge(ext.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: AppStrings.emailHint,
              prefixIcon: Icon(Icons.mail_outline, color: ext.textMuted, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return AppStrings.emailRequired;
              if (!v.contains('@')) return AppStrings.emailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(AppStrings.sendOtpButton, style: AppTypography.button(Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.emerald500.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.send_rounded, color: AppColors.emerald500, size: 36),
        ),
        const SizedBox(height: 20),
        Text(AppStrings.otpSentTitle, style: AppTypography.heading3(
          Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        )),
        const SizedBox(height: 8),
        Text(
          AppStrings.otpSentMessage(email),
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium(context.appTheme.textMuted),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => context.push(AppRoutes.resetPasswordWithEmail(email)),
          child: const Text(AppStrings.continueManuallyLink),
        ),
      ],
    );
  }
}
