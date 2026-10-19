  /// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// Base URL for the backend API.
  /// Override via --dart-define=API_BASE_URL=<url> at build time.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://rotruyen.hoaiphuong.io.vn', // Production server
  );

  /// Pagination defaults
  static const int defaultPageSize = 12;
  static const int rankingPageSize = 18;
  static const int notificationPageSize = 20;
  static const int maxNotificationsInMemory = 50;

  /// Reader defaults
  static const double defaultFontSize = 18.0;
  static const double minFontSize = 14.0;
  static const double maxFontSize = 28.0;
  static const double fontSizeStep = 2.0;

  /// Debounce / timing
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration progressTrackingDebounce = Duration(seconds: 3);
  static const Duration forgotPasswordRedirectDelay = Duration(seconds: 2);
  static const Duration resetPasswordRedirectDelay = Duration(seconds: 3);

  /// Validation
  static const int otpLength = 6;
  static const int maxAvatarSizeBytes = 2 * 1024 * 1024; // 2 MB

  /// Default cover image
  static const String defaultCoverImage =
      'https://images.unsplash.com/photo-1543005127-b6b197e60be2?q=80&w=400&auto=format&fit=crop';
}
