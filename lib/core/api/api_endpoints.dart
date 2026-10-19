/// All backend API endpoint paths in one place.
///
/// Keeps strings DRY and easy to grep-audit.
/// Verified against Swagger spec: https://rotruyen.hoaiphuong.io.vn/api/docs-json
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String registerVerify = '/auth/register/verify';
  static const String registerResendOtp = '/auth/register/resend-otp';
  static const String refresh = '/auth/refresh';
  static const String googleAuth = '/auth/google';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password'; // PATCH

  // ── Users / Profile ─────────────────────────────────────────
  static const String me = '/users/me'; // GET / PATCH
  static String userProfile(String id) => '/users/$id/profile';
  static const String updateProfile = '/users/me'; // PATCH
  static const String uploadAvatar = '/users/me/avatar'; // PATCH multipart

  // ── Stories ─────────────────────────────────────────────────
  static const String stories = '/stories';
  static String storyById(String id) => '/stories/$id';
  static const String genres = '/stories/genres';
  static String storyChapters(String storyId) => '/stories/$storyId/chapters';

  // ── Chapters ────────────────────────────────────────────────
  static String chapterByNumber(String storyId, int number) =>
      '/stories/$storyId/chapters/$number'; // GET/PUT/DELETE

  // ── Comments ────────────────────────────────────────────────
  static String comments(String storyId) =>
      '/stories/$storyId/comments'; // GET/POST
  static String likeComment(String commentId) => '/comments/$commentId/like';
  static String unlikeComment(String commentId) => '/comments/$commentId/like';

  // ── Reviews ─────────────────────────────────────────────────
  static String reviews(String storyId) => '/reviews/story/$storyId';
  static const String createReview = '/reviews';

  // ── Bookmarks ───────────────────────────────────────────────
  static const String bookmarks = '/bookmarks';
  static String toggleBookmark(String storyId) => '/bookmarks/$storyId';
  static String checkBookmark(String storyId) => '/bookmarks/check/$storyId';

  // ── Follow ──────────────────────────────────────────────────
  static String follow(String userId) => '/follow/$userId';
  static String checkFollow(String userId) => '/follow/check/$userId';

  // ── Reading History ─────────────────────────────────────────
  static const String readingHistory = '/reading-history/me';
  static const String saveProgress = '/reading-history';

  // ── Wallet ──────────────────────────────────────────────────
  static const String wallet = '/wallet';
  static const String deposit = '/wallet/deposit';
  static const String depositVerify = '/wallet/deposit/verify';
  static const String withdraw = '/wallet/withdraw';
  static const String purchaseChapter = '/wallet/purchase-chapter';
  static const String transactions = '/wallet/transactions';

  // ── Notifications ───────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationStream = '/notifications/stream';
  static String markRead(String id) => '/notifications/$id/read'; // PUT
  static const String markAllRead = '/notifications/read-all'; // PUT
  static const String fcmToken = '/notifications/fcm-token';

  // ── Studio (Writer) ─────────────────────────────────────────
  static const String myStories = '/stories/my';
  static const String createStory = '/stories'; // POST
  static String updateStory(String id) => '/stories/$id'; // PUT
  static String deleteStory(String id) => '/stories/$id'; // DELETE
  static String createChapter(String storyId) =>
      '/stories/$storyId/chapters'; // POST
  static String updateChapter(String storyId, int number) =>
      '/stories/$storyId/chapters/$number'; // PUT

  // ── Donate ──────────────────────────────────────────────────
  static const String donate = '/wallet/donate';

  // ── FCM Push Notifications ─────────────────────────────────
  static const String registerFcmToken = '/notifications/fcm-token';

  // ── Upload ─────────────────────────────────────────────────
  static const String uploadImage = '/upload/image'; // POST multipart
}
