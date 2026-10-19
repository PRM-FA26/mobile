/// Centralized route paths for [GoRouter] navigation.
///
/// Keeps path strings in one place so `context.go`/`context.push` calls and
/// the router config in `core/router/app_router.dart` never drift apart.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String explore = '/explore';
  static const String library = '/library';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String history = '/history';
  static const String wallet = '/wallet';
  static const String rankings = '/rankings';
  static const String studio = '/studio';

  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static String storyDetail(String storyId) => '/stories/$storyId';
  static String reader(String storyId, int chapterNumber) =>
      '/stories/$storyId/chapters/$chapterNumber';
  static String userProfile(String userId) => '/users/$userId';

  static String verifyEmailWithAddress(String email) =>
      '$verifyEmail?email=${Uri.encodeComponent(email)}';
  static String resetPasswordWithEmail(String email) =>
      '$resetPassword?email=${Uri.encodeComponent(email)}';

  /// Login path carrying a `redirect` query param so the user lands back on
  /// [target] after authenticating (used by every auth-gated route/screen).
  static String loginWithRedirect(String target) => '$login?redirect=$target';
}
