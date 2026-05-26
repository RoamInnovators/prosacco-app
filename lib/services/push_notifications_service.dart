import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screens/member_notifications_screen.dart';
import '../utils/prosacco_member_auth_api.dart';

class PushNotificationsService {
  PushNotificationsService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _initialized = false;
  static String? _authToken;
  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _syncTokenBestEffort(token);
      }

      _tokenRefreshSub = messaging.onTokenRefresh.listen((token) async {
        await _syncTokenBestEffort(token);
      });

      _onMessageSub = FirebaseMessaging.onMessage.listen((msg) {
        _showForegroundNotificationHint(msg);
      });

      _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((_) {
        _openNotificationsPage();
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _openNotificationsPage();
      }
    } catch (_) {
      // Keep app usable even if Firebase config is missing.
    }
  }

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    _tokenRefreshSub = null;
    _onMessageSub = null;
    _onMessageOpenedSub = null;
  }

  static Future<void> _syncTokenBestEffort(String token) async {
    final auth = _authToken;
    if (auth == null || auth.isEmpty) return;
    try {
      final api = ProsaccoMemberAuthApi();
      await api.registerPushToken(token: auth, pushToken: token);
    } catch (_) {}
  }

  static void _showForegroundNotificationHint(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? 'You have a new update.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _openNotificationsPage() {
    final nav = navigatorKey.currentState;
    final auth = _authToken;
    if (nav == null || auth == null || auth.isEmpty) return;
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => MemberNotificationsScreen(authToken: auth),
      ),
    );
  }
}

