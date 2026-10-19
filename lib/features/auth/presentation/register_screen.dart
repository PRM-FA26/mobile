import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;
  bool _registerAsWriter = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final api = ref.read(apiClientProvider);
      // Step 1: request an OTP. The account is only created after the OTP is
      // verified on the next screen.
      await api.post(
        ApiEndpoints.register,
        data: {
          'username': _usernameCtrl.text.trim(),
          'email': email,
          'password': _passwordCtrl.text,
          'confirmPassword': _confirmCtrl.text,
          'role': _registerAsWriter ? 'WRITER' : 'READER',
        },
      );

      if (mounted) {
        context.push(AppRoutes.verifyEmailWithAddress(email));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = AppStrings.genericError);
    } finally {
      if (mounted) setState(() => _loading = false);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Back button
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_rounded, color: ext.textMuted),
                style: IconButton.styleFrom(
                  backgroundColor: ext.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                AppStrings.registerTitle,
                style: AppTypography.heading1(textColor).copyWith(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.registerSubtitle,
                style: AppTypography.bodyMedium(ext.textMuted),
              ),

              const SizedBox(height: 32),

              // Error
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTypography.bodySmall(
                            AppColors.error,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              Text(
                AppStrings.registerRoleLabel,
                style: AppTypography.labelLarge(ext.textSecondary),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    setState(() => _registerAsWriter = !_registerAsWriter),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: ext.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _registerAsWriter
                          ? AppColors.emerald500
                          : Theme.of(context).dividerColor,
                      width: _registerAsWriter ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              (_registerAsWriter
                                      ? AppColors.emerald500
                                      : ext.textMuted)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _registerAsWriter
                              ? Icons.edit_rounded
                              : Icons.menu_book_rounded,
                          color: _registerAsWriter
                              ? AppColors.emerald500
                              : ext.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _registerAsWriter ? AppStrings.roleWriter : AppStrings.roleReader,
                              style: AppTypography.labelLarge(
                                _registerAsWriter
                                    ? AppColors.emerald500
                                    : textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _registerAsWriter
                                  ? AppStrings.roleWriterDescription
                                  : AppStrings.roleReaderDescription,
                              style: AppTypography.bodySmall(ext.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _registerAsWriter,
                        onChanged: (value) =>
                            setState(() => _registerAsWriter = value),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      AppStrings.usernameLabel,
                      _usernameCtrl,
                      Icons.person_outline,
                      hint: AppStrings.usernameHint,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return AppStrings.usernameRequired;
                        }
                        if (v.trim().length < 3) {
                          return AppStrings.usernameTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      AppStrings.emailLabel,
                      _emailCtrl,
                      Icons.mail_outline,
                      hint: AppStrings.emailHint,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return AppStrings.emailRequired;
                        }
                        if (!v.contains('@')) {
                          return AppStrings.emailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      AppStrings.passwordLabel,
                      _passwordCtrl,
                      Icons.lock_outline,
                      hint: '••••••••',
                      obscure: _obscurePass,
                      toggleObscure: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return AppStrings.passwordRequired;
                        }
                        if (v.length < 6) {
                          return AppStrings.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      AppStrings.confirmPasswordLabel,
                      _confirmCtrl,
                      Icons.lock_outline,
                      hint: '••••••••',
                      obscure: _obscureConfirm,
                      toggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v != _passwordCtrl.text) {
                          return AppStrings.passwordMismatch;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleRegister,
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
                            const Icon(Icons.person_add_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.registerButton,
                              style: AppTypography.button(Colors.white),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text.rich(
                  TextSpan(
                    text: AppStrings.haveAccountPrompt,
                    style: AppTypography.bodyMedium(ext.textMuted),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.login),
                          child: Text(
                            AppStrings.loginNowLink,
                            style: AppTypography.labelLarge(
                              AppColors.emerald500,
                            ),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    String? hint,
    TextInputType? keyboard,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    final ext = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLarge(ext.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: ext.textMuted, size: 20),
            suffixIcon: toggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: ext.textMuted,
                      size: 20,
                    ),
                    onPressed: toggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
