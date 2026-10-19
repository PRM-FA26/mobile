import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../providers/core_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/story_detail/presentation/story_detail_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/rankings/presentation/rankings_screen.dart';
import '../../features/studio/presentation/studio_screen.dart';
import '../../features/user_profile/presentation/user_profile_screen.dart';
import '../../shared/widgets/main_shell.dart';

/// GoRouter provider.
final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    routes: [
      // ── Shell: Bottom Navigation ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.explore,
            name: 'explore',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExploreScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.library,
            name: 'library',
            redirect: (context, state) {
              if (!isLoggedIn) return AppRoutes.loginWithRedirect(AppRoutes.library);
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            redirect: (context, state) {
              if (!isLoggedIn) return AppRoutes.loginWithRedirect(AppRoutes.notifications);
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            redirect: (context, state) {
              if (!isLoggedIn) return AppRoutes.loginWithRedirect(AppRoutes.profile);
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Auth Screens (no bottom nav) ────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verify-email',
        builder: (context, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),

      // ── Content Screens ─────────────────────────────────────
      GoRoute(
        path: '/stories/:id',
        name: 'story-detail',
        builder: (context, state) => StoryDetailScreen(
          storyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/stories/:id/chapters/:number',
        name: 'reader',
        builder: (context, state) => ReaderScreen(
          storyId: state.pathParameters['id']!,
          chapterNumber: int.parse(state.pathParameters['number']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        redirect: (context, state) {
          if (!isLoggedIn) return AppRoutes.loginWithRedirect(AppRoutes.history);
          return null;
        },
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        name: 'wallet',
        redirect: (context, state) {
          if (!isLoggedIn) return AppRoutes.loginWithRedirect(AppRoutes.wallet);
          return null;
        },
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.rankings,
        name: 'rankings',
        builder: (context, state) => const RankingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.studio,
        name: 'studio',
        redirect: (context, state) {
          if (!isLoggedIn) return AppRoutes.loginWithRedirect(AppRoutes.studio);
          return null;
        },
        builder: (context, state) => const StudioScreen(),
      ),
      GoRoute(
        path: '/users/:id',
        name: 'user-profile',
        builder: (context, state) => UserProfileScreen(
          userId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
