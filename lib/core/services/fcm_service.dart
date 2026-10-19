import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/providers/core_providers.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Manages FCM token registration and foreground notification handling.
class FcmService {
  final Ref _ref;
  FcmService(this._ref);

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request notification permissions
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notification permission denied');
      return;
    }

    // Get and register FCM token
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _registerTokenWithServer(token);
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_registerTokenWithServer);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      // Notification will be shown by the system on Android 13+
      // For older versions, you could use flutter_local_notifications
    });

    // Handle notification taps (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Notification tapped: ${message.data}');
      // TODO: Navigate to relevant screen based on message.data
    });

    // Handle notification that opened the app from terminated state
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from notification: ${initialMessage.data}');
    }
  }

  Future<void> _registerTokenWithServer(String token) async {
    debugPrint('[FCM] Registering token: ${token.substring(0, 20)}...');
    try {
      final isLoggedIn = _ref.read(authStateProvider);
      if (!isLoggedIn) return;

      final api = _ref.read(apiClientProvider);
      await api.post(ApiEndpoints.registerFcmToken, data: {
        'token': token,
        'platform': 'ANDROID',
      });
      debugPrint('[FCM] Token registered successfully');
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }
}

/// Riverpod provider for FCM service
final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(ref));
