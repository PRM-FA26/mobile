import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../auth/secure_storage.dart';
import '../services/fcm_service.dart';

// ══════════════════════════════════════════════════════════════
//  CORE PROVIDERS — singletons shared across the entire app.
// ══════════════════════════════════════════════════════════════

/// Global navigator key used for programmatic navigation from
/// non-widget code (e.g. interceptor logout redirect).
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (_) => GlobalKey<NavigatorState>(),
);

/// Secure storage instance.
final secureStorageProvider = Provider<SecureStorage>(
  (_) => SecureStorage(),
);

/// API client singleton.
///
/// Depends on [secureStorageProvider] and wires up the logout callback
/// to clear auth state and navigate to login.
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(
    storage: storage,
    onLoggedOut: () {
      ref.read(authStateProvider.notifier).setLoggedIn(false);
      ref.read(currentUserProvider.notifier).clear();
    },
  );
});

// ══════════════════════════════════════════════════════════════
//  AUTH PROVIDERS
// ══════════════════════════════════════════════════════════════

/// Whether the user is currently authenticated (has a valid access token).
final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoggedIn(bool value) => state = value;
}

/// Current user role: 'READER', 'WRITER', 'ADMIN', or null.
final userRoleProvider = NotifierProvider<UserRoleNotifier, String?>(
  UserRoleNotifier.new,
);

class UserRoleNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setRole(String? role) => state = role;
}

/// Lightweight user profile for display in bottom nav avatar.
final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserProfile?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => null;

  void setUser(UserProfile? user) => state = user;
  void clear() => state = null;
  void updateProfile({String? displayName, String? avatar}) {
    if (state != null) {
      state = state!.copyWith(displayName: displayName, avatar: avatar);
    }
  }
}

/// User profile model for the current authenticated user.
class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? avatar;

  const UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String?,
        avatar: json['avatar'] as String?,
      );

  UserProfile copyWith({
    String? displayName,
    String? avatar,
  }) =>
      UserProfile(
        id: id,
        username: username,
        displayName: displayName ?? this.displayName,
        avatar: avatar ?? this.avatar,
      );
}

// ══════════════════════════════════════════════════════════════
//  THEME PROVIDERS
// ══════════════════════════════════════════════════════════════

/// App-wide theme mode. Persisted to secure storage.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

// ══════════════════════════════════════════════════════════════
//  APP STARTUP
// ══════════════════════════════════════════════════════════════

/// Initializes auth state and preferences from secure storage on app start.
final appStartupProvider = FutureProvider<void>((ref) async {
  final storage = ref.read(secureStorageProvider);

  // 1. Restore auth state
  final isLoggedIn = await storage.isLoggedIn();
  ref.read(authStateProvider.notifier).setLoggedIn(isLoggedIn);

  if (isLoggedIn) {
    final role = await storage.getUserRole();
    ref.read(userRoleProvider.notifier).setRole(role);

    // Fetch current user profile
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>('/users/me');
      ref.read(currentUserProvider.notifier).setUser(
        UserProfile.fromJson(data),
      );
    } catch (_) {
      // Silently fail — user will see login prompt if token is invalid
    }

    // Initialize FCM push notifications
    try {
      final fcm = ref.read(fcmServiceProvider);
      await fcm.initialize();
    } catch (_) {
      // FCM init is non-critical
    }
  }

  // 2. Restore theme preference
  final themeStr = await storage.getThemeMode();
  switch (themeStr) {
    case 'light':
      ref.read(themeModeProvider.notifier).setMode(ThemeMode.light);
    case 'dark':
      ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    default:
      ref.read(themeModeProvider.notifier).setMode(ThemeMode.system);
  }
});
