/// Centralized text used by the app UI.
class AppStrings {
  AppStrings._();

  // Wallet
  static const String walletTitle = 'Ví xu';
  static const String walletCurrentBalance = 'Số dư hiện tại';
  static const String walletDeposit = 'Nạp xu';
  static const String walletWithdraw = 'Rút tiền';
  static const String walletTransactionHistory = 'Lịch sử giao dịch';
  static const String walletNoTransactions = 'Chưa có giao dịch nào';
  static const String walletLoadFailed = 'Không thể tải dữ liệu ví.';
  static const String walletRetry = 'Thử lại';
  static const String walletCoinUnit = 'xu';

  static const String walletDepositPackageHint = 'Chọn mệnh giá (VNĐ)';
  static const String walletDepositSuccess = 'Nạp xu thành công!';
  static const String walletDepositMissingPaymentUrl =
      'Máy chủ chưa trả về link thanh toán. Vui lòng thử lại sau.';
  static const String walletDepositInvalidPaymentUrl =
      'Link thanh toán không hợp lệ.';
  static const String walletDepositCannotOpenGateway =
      'Không mở được cổng thanh toán trên thiết bị này.';
  static const String walletDepositCreateFailed =
      'Không thể tạo giao dịch nạp xu. Vui lòng thử lại.';

  static const String walletWithdrawAmountLabel = 'Số xu muốn rút';
  static const String walletWithdrawBankLabel = 'Ngân hàng';
  static const String walletWithdrawAccountNumberLabel = 'Số tài khoản';
  static const String walletWithdrawAccountNameLabel = 'Tên chủ tài khoản';
  static const String walletWithdrawSubmit = 'Gửi yêu cầu';
  static const String walletWithdrawMinimumError =
      'Số xu rút tối thiểu là 200 xu.';
  static const String walletWithdrawFieldRequired = 'Không được để trống.';
  static const String walletWithdrawRequestSent = 'Yêu cầu rút tiền đã gửi!';
  static const String walletWithdrawFailed =
      'Không thể gửi yêu cầu rút tiền. Vui lòng thử lại.';

  static String walletTransactionCount(int count) => '$count giao dịch';

  // ── Common ──────────────────────────────────────────────────
  static const String cancel = 'Hủy';
  static const String save = 'Lưu';
  static const String send = 'Gửi';
  static const String close = 'Đóng';
  static const String retry = 'Thử lại';
  static const String genericError = 'Đã có lỗi xảy ra';
  static const String exploreStories = 'Khám phá truyện';
  static const String actionFailedRetry = 'Thao tác thất bại. Vui lòng thử lại.';
  static const String notificationsLoadFailed = 'Không thể tải thông báo.';
  static const String libraryLoadFailed = 'Không thể tải thư viện.';
  static const String bookmarkRemoveFailed = 'Không thể xóa khỏi thư viện. Vui lòng thử lại.';
  static const String userProfileLoadFailed = 'Không thể tải hồ sơ người dùng.';
  static const String followActionFailed = 'Không thể thực hiện. Vui lòng thử lại.';

  // ── Auth: Login ─────────────────────────────────────────────
  static const String loginWelcomeTitle = 'Chào mừng\ntrở lại! 👋';
  static const String loginSubtitle = 'Đăng nhập để tiếp tục đọc truyện yêu thích.';
  static const String emailLabel = 'Email';
  static const String emailHint = 'you@example.com';
  static const String emailRequired = 'Vui lòng nhập email';
  static const String emailInvalid = 'Email không hợp lệ';
  static const String passwordLabel = 'Mật khẩu';
  static const String passwordRequired = 'Vui lòng nhập mật khẩu';
  static const String forgotPasswordLink = 'Quên mật khẩu?';
  static const String loginButton = 'Đăng nhập';
  static const String orDivider = 'hoặc';
  static const String googleSignInButton = 'Đăng nhập với Google';
  static const String googleSignInLoading = 'Đang đăng nhập...';
  static const String googleTokenMissing = 'Không lấy được token từ Google';
  static const String firebaseTokenMissing = 'Không lấy được Firebase token';
  static String googlePlatformError(String code, String? message) =>
      'Google lỗi $code${message == null ? '' : ': $message'}';
  static String googleSignInFailedWithError(Object error) =>
      'Đăng nhập Google thất bại: $error';
  static const String googleSignInFailed = 'Đăng nhập Google thất bại';
  static const String noAccountPrompt = 'Chưa có tài khoản? ';
  static const String registerNowLink = 'Đăng ký ngay';

  // ── Auth: Register ──────────────────────────────────────────
  static const String registerTitle = 'Tạo tài khoản';
  static const String registerSubtitle = 'Tham gia cộng đồng đọc truyện ChapterOne.';
  static const String registerRoleQuestion = 'Bạn muốn là...';
  static const String registerRoleLabel = 'Vai trò tài khoản';
  static const String roleReader = 'Người đọc';
  static const String roleWriter = 'Tác giả';
  static const String roleWriterDescription = 'Có thể đăng và quản lý truyện';
  static const String roleReaderDescription = 'Đọc, lưu và theo dõi truyện';
  static const String usernameLabel = 'Username';
  static const String usernameHint = 'username_cool';
  static const String usernameRequired = 'Vui lòng nhập username';
  static const String usernameTooShort = 'Username tối thiểu 3 ký tự';
  static const String confirmPasswordLabel = 'Xác nhận mật khẩu';
  static const String passwordTooShort = 'Mật khẩu tối thiểu 6 ký tự';
  static const String passwordMismatch = 'Mật khẩu không khớp';
  static const String registerButton = 'Đăng ký';
  static const String haveAccountPrompt = 'Đã có tài khoản? ';
  static const String loginNowLink = 'Đăng nhập';

  // ── Auth: Forgot / Reset password ───────────────────────────
  static const String forgotPasswordTitle = 'Quên mật khẩu?';
  static const String forgotPasswordSubtitle = 'Nhập email của bạn để nhận mã xác thực đặt lại mật khẩu.';
  static const String sendOtpButton = 'Gửi mã xác thực';
  static const String otpSentTitle = 'Đã gửi mã xác thực!';
  static String otpSentMessage(String email) => 'Chúng tôi đã gửi mã OTP đến $email. Bạn sẽ được chuyển hướng sau giây lát...';
  static const String continueManuallyLink = 'Tiếp tục thủ công →';
  static const String rememberedPasswordPrompt = 'Đã nhớ mật khẩu? ';
  static const String resetPasswordTitle = 'Đặt lại mật khẩu';
  static const String resetPasswordSubtitle = 'Sử dụng mã OTP đã nhận được để đặt mật khẩu mới.';
  static const String otpLabel = 'Mã xác thực (6 chữ số)';
  static String otpLengthError(int length) => 'Mã OTP phải có $length chữ số';
  static const String newPasswordLabel = 'Mật khẩu mới';
  static const String passwordMinLengthShort = 'Tối thiểu 6 ký tự';
  static const String confirmPasswordMismatch = 'Mật khẩu xác nhận không khớp';
  static const String resetPasswordSuccessTitle = 'Thành công!';
  static const String resetPasswordSuccessMessage = 'Mật khẩu đã được cập nhật. Bạn sẽ được chuyển hướng về trang đăng nhập...';
  static const String loginNowButton = 'Đăng nhập ngay';
  static const String updatePasswordButton = 'Cập nhật mật khẩu';
  static const String forgotPasswordFailed = 'Gửi yêu cầu thất bại';
  static const String resetPasswordFailed = 'Đặt lại mật khẩu thất bại';

  // ── Auth: Verify email (OTP after register) ─────────────────
  static const String verifyEmailTitle = 'Xác thực email';
  static const String verifyEmailIntroPrefix = 'Chúng tôi đã gửi mã OTP gồm 6 chữ số đến ';
  static const String verifyEmailIntroSuffix = '. Vui lòng nhập mã để hoàn tất đăng ký.';
  static const String verifyAndCompleteButton = 'Xác thực & Hoàn tất';
  static String resendCodeCountdown(int seconds) => 'Gửi lại mã sau ${seconds}s';
  static const String resendCodePrompt = 'Không nhận được mã? ';
  static const String resendCodeLink = 'Gửi lại';
  static const String resendOtpSuccess = 'Đã gửi lại mã OTP đến email của bạn';
  static const String verifyFailed = 'Xác thực thất bại';
  static const String resendOtpFailed = 'Gửi lại mã thất bại';

  // ── Home ────────────────────────────────────────────────────
  static const String appDisplayName = 'ChapterOne';
  static const String homeGreetingLoggedIn = 'Chào, ';
  static const String homeGreetingGuest = 'Chào mừng đến ';
  static const String homeGreetingFallbackName = 'bạn';
  static const String homeSubtitle = 'Khám phá hàng nghìn bộ truyện hấp dẫn';
  static const String quickActionExplore = 'Khám phá';
  static const String quickActionRankings = 'Xếp hạng';
  static const String quickActionHistory = 'Lịch sử';
  static const String quickActionWallet = 'Ví xu';
  static const String navHome = 'Trang chủ';
  static const String navExplore = 'Khám phá';
  static const String navLibrary = 'Thư viện';
  static const String navNotifications = 'Thông báo';
  static const String navProfile = 'Tôi';
  static const String continueReadingPrefix = 'Tiếp tục';
  static const String continueReadingSuffix = 'đọc';
  static const String trendingPrefix = 'Đang';
  static const String trendingSuffix = 'thịnh hành';
  static const String newReleasesPrefix = 'Truyện';
  static const String newReleasesSuffix = 'mới cập nhật';
  static const String topRatedPrefix = 'Đánh giá';
  static const String topRatedSuffix = 'cao nhất';
  static const String loadErrorGeneric = 'Lỗi tải dữ liệu';
  static const String noStoriesFound = 'Không có truyện';

  // ── Explore ─────────────────────────────────────────────────
  static const String exploreSearchHint = 'Tìm tên truyện, mô tả, tác giả...';
  static const String exploreGenreSearchHint = 'Tìm thể loại';
  static const String exploreClearFilter = 'Xóa lọc';
  static const String exploreLoadStoriesFailed = 'Không thể tải danh sách truyện.';
  static const String exploreGenreSelected = 'Đã chọn';
  static const String exploreGenreFilterLabel = 'Thể loại';
  static const String exploreTypeFilterLabel = 'Loại';
  static const String exploreStatusFilterLabel = 'Trạng thái';
  static const String exploreChooseTypeTitle = 'Chọn loại truyện';
  static const String exploreChooseStatusTitle = 'Chọn trạng thái';
  static const String exploreNoStoriesFound = 'Không tìm thấy truyện nào';
  static const String exploreTryDifferentFilter = 'Thử đổi từ khóa hoặc bỏ bớt bộ lọc.';
  static const String exploreNoStoriesAvailable = 'Hiện chưa có truyện để hiển thị.';
  static const String exploreChooseGenreTitle = 'Chọn thể loại';
  static const String exploreAllGenres = 'Tất cả thể loại';
  static const String exploreGenreNotFound = 'Không tìm thấy thể loại';
  static const String exploreGenreLoadFailed = 'Lỗi tải thể loại';
  static const String storyStatusHiatus = 'Tạm dừng';
  static const String storyStatusDropped = 'Đã dừng';

  // ── Story detail ────────────────────────────────────────────
  static String storyLoadError(Object error) => 'Lỗi: $error';
  static const String readStoryButton = 'Đọc truyện';
  static const String donateAmountLabel = 'Số xu';
  static String donateAmountSuffix(int amount) => '$amount xu';
  static String donateSuccessMessage(int amount) => 'Đã donate $amount xu!';
  static const String donateSubmitButton = 'Gửi donate ❤️';
  static const String writeCommentHint = 'Viết bình luận...';
  static const String writeReviewTitle = 'Viết đánh giá';
  static const String reviewContentHint = 'Nội dung đánh giá (không bắt buộc)';
  static const String reviewSubmitSuccess = 'Gửi đánh giá thành công!';
  static const String tabChapters = 'Chương';
  static const String tabComments = 'Bình luận';
  static const String tabReviews = 'Đánh giá';
  static String storyChapterCountSuffix(int count) => '$count chương';
  static const String collapseLabel = 'Thu gọn';
  static const String expandMoreLabel = 'Xem thêm';
  static String donateToAuthor(String name) => 'Donate cho $name';
  static const String noChaptersYet = 'Chưa có chương nào';
  static String wordCountSuffix(String count) => '$count từ';
  static const String chapterPurchased = 'Đã mua';
  static const String noCommentsYet = 'Chưa có bình luận nào';
  static const String noReviewsYet = 'Chưa có đánh giá nào';
  static String typingLabelOne(String name) => '$name đang nhập...';
  static String typingLabelTwo(String a, String b) => '$a và $b đang nhập...';
  static String typingLabelMany(int count) => '$count người đang nhập...';

  // ── Reader ──────────────────────────────────────────────────
  static String readerChapterLabel(int number) => 'Chương $number';
  static const String readerLoadingTitle = 'Đang tải...';
  static const String readerPrevChapter = 'Chương trước';
  static const String readerNextChapter = 'Chương sau';
  static const String readerPremiumTitle = 'Chương Premium';
  static String readerPremiumHint(int price) => 'Chương này yêu cầu $price xu để mở khóa';
  static String readerBuyChapterButton(int price) => 'Mua $price xu';
  static const String readerBackButton = 'Quay lại';
  static const String readerChapterInfoMissing = 'Không tìm thấy thông tin chương để mua.';

  // ── Library ─────────────────────────────────────────────────
  static const String libraryTitle = 'Thư viện';
  static const String librarySearchHint = 'Tìm trong thư viện...';
  static String libraryStoryCount(int count) => '$count truyện';
  static const String libraryEmptyTitle = 'Thư viện trống';
  static const String libraryEmptySearchTitle = 'Không tìm thấy truyện';
  static String libraryBookmarkRemoved(String title) => 'Đã xóa "$title" khỏi thư viện';

  // ── Rankings ────────────────────────────────────────────────
  static const String rankingsTitle = 'Xếp hạng';
  static const String rankingsPeriodDay = 'Ngày';
  static const String rankingsPeriodWeek = 'Tuần';
  static const String rankingsPeriodMonth = 'Tháng';
  static const String rankingsNoData = 'Không có dữ liệu';

  // ── History ─────────────────────────────────────────────────
  static const String historyTitle = 'Lịch sử đọc';
  static const String historyEmptyTitle = 'Chưa có lịch sử đọc';

  // ── Notifications ───────────────────────────────────────────
  static const String notificationsTitle = 'Thông báo';
  static const String notificationsMarkAllRead = 'Đọc hết';
  static const String notificationsEmptyTitle = 'Chưa có thông báo';

  // ── Profile (own) ───────────────────────────────────────────
  static const String profileTitle = 'Hồ sơ';
  static const String logoutTitle = 'Đăng xuất';
  static const String logoutConfirmMessage = 'Bạn có chắc muốn đăng xuất?';
  static const String themeSectionTitle = 'Giao diện';
  static const String themeModeSystem = 'Hệ thống';
  static const String themeModeLight = 'Sáng';
  static const String themeModeDark = 'Tối';
  static const String defaultUsernameFallback = 'User';
  static const String editProfileTitle = 'Chỉnh sửa hồ sơ';
  static const String displayNameLabel = 'Tên hiển thị';
  static const String bioLabel = 'Giới thiệu';
  static const String saveChangesButton = 'Lưu thay đổi';
  static const String changePasswordTitle = 'Đổi mật khẩu';
  static const String currentPasswordLabel = 'Mật khẩu hiện tại';
  static const String confirmPasswordShortLabel = 'Xác nhận';
  static const String updateButton = 'Cập nhật';
  static const String changePasswordSuccess = 'Đổi mật khẩu thành công!';

  // ── User profile (public) ───────────────────────────────────
  static const String followersLabel = 'Followers';
  static const String followingLabel = 'Following';
  static const String userStoriesLabel = 'Truyện';
  static const String followingButtonLabel = 'Đang theo dõi';
  static const String followButtonLabel = 'Theo dõi';
  static const String donateButtonLabel = 'Donate';
  static const String writerRoleLabel = 'Tác giả';
  static const String readerRoleLabel = 'Người đọc';
  static String userStoriesSectionTitle(String displayName) => 'Truyện của $displayName';

  // ── Studio (writer) ─────────────────────────────────────────
  static const String studioTitle = 'Writer Studio';
  static const String studioEmptyMessage = 'Bắt đầu sáng tác truyện đầu tiên!';
  static String studioChapterCount(int count) => '$count chương';
  static const String studioCreateStoryButton = 'Tạo truyện';
  static const String studioCreateStoryTitle = 'Tạo truyện mới';
  static const String storyNameLabel = 'Tên truyện';
  static const String descriptionLabel = 'Mô tả';
  static const String storyTypeLabel = 'Loại: ';
  static const String storyTypeNovel = 'Novel';
  static const String storyTypeManga = 'Manga';
  static const String studioCreateStorySuccess = 'Đã tạo truyện mới!';
  static const String studioAddChapterTitle = 'Thêm chương mới';
  static const String chapterTitleLabel = 'Tiêu đề chương';
  static const String chapterContentLabel = 'Nội dung';
  static const String chapterPremiumLabel = 'Chương Premium';
  static const String chapterPriceLabel = 'Giá (xu)';
  static const String studioPublishChapterButton = 'Xuất bản chương';
  static const String studioAddChapterSuccess = 'Đã thêm chương mới!';
  static const String studioEditStoryTitle = 'Chỉnh sửa truyện';
  static const String storyStatusLabel = 'Trạng thái: ';
  static const String storyStatusOngoing = 'Tiến hành';
  static const String storyStatusCompleted = 'Hoàn thành';
  static const String studioUpdateStorySuccess = 'Đã cập nhật truyện!';
  static const String studioDeleteStoryTitle = 'Xóa truyện';
  static String studioDeleteStoryConfirm(String title) =>
      'Bạn có chắc muốn xóa "$title"? Hành động này không thể hoàn tác.';
  static const String deleteButton = 'Xóa';
  static String studioDeleteStorySuccess(String title) => 'Đã xóa "$title"';
  static const String storyStatusCompletedShort = 'Hoàn';
  static const String studioEditStoryTooltip = 'Sửa truyện';
  static const String studioAddChapterTooltip = 'Thêm chương';
  static const String studioDeleteStoryTooltip = 'Xóa truyện';
}
