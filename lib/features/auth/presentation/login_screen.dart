import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectTo;
  const LoginScreen({super.key, this.redirectTo});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  String? _error;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final api = ref.read(apiClientProvider);
      final data = await api.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      await _completeLogin(data);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = AppStrings.genericError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() { _googleLoading = true; _error = null; });

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '319281485286-m5dkdhhubf0k1tm3h6t740bqogsgin1d.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        setState(() => _googleLoading = false);
        return;
      }

      final auth = await account.authentication;
      if (auth.idToken == null) {
        setState(() {
          _error = AppStrings.googleTokenMissing;
          _googleLoading = false;
        });
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final firebaseUserCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = firebaseUserCredential.user;
      final firebaseIdToken = await firebaseUser?.getIdToken();
      if (firebaseIdToken == null) {
        setState(() {
          _error = AppStrings.firebaseTokenMissing;
          _googleLoading = false;
        });
        return;
      }

      // Send Firebase Auth ID token to backend.
      final api = ref.read(apiClientProvider);
      final data = await api.post<Map<String, dynamic>>(
        ApiEndpoints.googleAuth,
        data: {'idToken': firebaseIdToken},
      );

      await _completeLogin(data);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on PlatformException catch (e) {
      setState(() {
        _error = AppStrings.googlePlatformError(e.code, e.message);
      });
    } catch (e) {
      setState(() => _error = AppStrings.googleSignInFailedWithError(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  /// Shared login completion: save tokens, fetch profile, init FCM, navigate
  Future<void> _completeLogin(Map<String, dynamic> data) async {
    final storage = ref.read(secureStorageProvider);
    await storage.setTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
      data['user']?['role'] as String?,
    );

    ref.read(authStateProvider.notifier).setLoggedIn(true);
    ref.read(userRoleProvider.notifier).setRole(data['user']?['role'] as String?);

    // Fetch user profile
    try {
      final api = ref.read(apiClientProvider);
      final profile = await api.get<Map<String, dynamic>>(ApiEndpoints.me);
      ref.read(currentUserProvider.notifier).setUser(
        UserProfile.fromJson(profile),
      );
    } catch (_) {}

    // Initialize FCM after login
    try {
      final fcm = ref.read(fcmServiceProvider);
      await fcm.initialize();
    } catch (_) {}

    if (mounted) {
      context.go(widget.redirectTo ?? AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald500.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald500.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Back Button
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                        icon: Icon(Icons.arrow_back_rounded, color: ext.textMuted),
                        style: IconButton.styleFrom(
                          backgroundColor: ext.surfaceElevated,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.emerald500, AppColors.emerald600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emerald500.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(AppStrings.appDisplayName, style: AppTypography.heading2(
                            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          )),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Title
                      Text(
                        AppStrings.loginWelcomeTitle,
                        style: AppTypography.heading1(
                          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ).copyWith(fontSize: 32, height: 1.15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.loginSubtitle,
                        style: AppTypography.bodyMedium(ext.textMuted),
                      ),

                      const SizedBox(height: 36),

                      // Error
                      if (_error != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: AppTypography.bodySmall(AppColors.error)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email
                            Text(AppStrings.emailLabel, style: AppTypography.labelLarge(ext.textSecondary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
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

                            const SizedBox(height: 20),

                            // Password
                            Text(AppStrings.passwordLabel, style: AppTypography.labelLarge(ext.textSecondary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: Icon(Icons.lock_outline, color: ext.textMuted, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: ext.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppStrings.passwordRequired;
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push(AppRoutes.forgotPassword),
                                child: const Text(AppStrings.forgotPasswordLink),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emerald500,
                                  foregroundColor: isDark ? const Color(0xFF020617) : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
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
                                          const Icon(Icons.login_rounded, size: 20),
                                          const SizedBox(width: 8),
                                          Text(AppStrings.loginButton, style: AppTypography.button(
                                            isDark ? const Color(0xFF020617) : Colors.white,
                                          )),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: ext.textMuted.withValues(alpha: 0.2))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(AppStrings.orDivider, style: AppTypography.bodySmall(ext.textMuted)),
                          ),
                          Expanded(child: Divider(color: ext.textMuted.withValues(alpha: 0.2))),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google Sign In
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _googleLoading ? null : _handleGoogleSignIn,
                          icon: _googleLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ext.textMuted,
                                  ),
                                )
                              : SvgPicture.network(
                                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                  width: 20,
                                  height: 20,
                                  placeholderBuilder: (_) => const Icon(Icons.g_mobiledata, size: 24),
                                ),
                          label: Text(
                            _googleLoading ? AppStrings.googleSignInLoading : AppStrings.googleSignInButton,
                            style: AppTypography.button(
                              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Register link
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: AppStrings.noAccountPrompt,
                            style: AppTypography.bodyMedium(ext.textMuted),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: () => context.push(AppRoutes.register),
                                  child: Text(
                                    AppStrings.registerNowLink,
                                    style: AppTypography.labelLarge(AppColors.emerald500),
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
            ),
          ),
        ],
      ),
    );
  }
}
