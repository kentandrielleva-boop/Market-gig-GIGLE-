import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Conversation id tapped from a push notification. Set by the notification
/// tap handlers; [MarketplaceApp] consumes it and navigates to `/inbox/:id`.
final pushConversationTap = ValueNotifier<String?>(null);

/// Must stay top-level for background isolate entry.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification-payload messages are shown by the OS. Data-only payloads
  // while terminated need a sender backend (Blaze/Functions) — no-op on Spark.
}

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Call once after Firebase init + sign-in. Saves the FCM token under
/// `profiles/{uid}/fcm_tokens/{token}` and shows foreground messages locally.
/// Sending is NOT client-side (Spark has no Functions): pair with a
/// Blaze backend later that fans out on new `messages` docs.
Future<void> initPushNotifications(FirebaseFirestore db, String uid) async {
  final messaging = FirebaseMessaging.instance;
  try {
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  } catch (_) {
    return;
  }

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotifications.initialize(
    settings: const InitializationSettings(android: android),
    onDidReceiveNotificationResponse: (response) {
      final convId = _conversationIdOf(response.payload);
      if (convId != null) pushConversationTap.value = convId;
    },
  );

  String? token;
  try {
    token = await messaging.getToken();
  } catch (_) {
    token = null;
  }
  if (token != null) {
    await db
        .collection('profiles')
        .doc(uid)
        .collection('fcm_tokens')
        .doc(token)
        .set({
          'created_at': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        }, SetOptions(merge: true));
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.instance.onTokenRefresh.listen((t) {
    db.collection('profiles').doc(uid).collection('fcm_tokens').doc(t).set({
      'created_at': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.name,
    }, SetOptions(merge: true));
  });

  FirebaseMessaging.onMessage.listen((message) {
    final convId = message.data['conversationId'] as String?;
    final notif = message.notification;
    if (notif == null) return;
    _localNotifications.show(
      id: notif.hashCode,
      title: notif.title,
      body: notif.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('chat_messages', 'Chat messages'),
      ),
      payload: convId,
    );
  });
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final convId = message.data['conversationId'] as String?;
    if (convId != null) pushConversationTap.value = convId;
  });
}

String? _conversationIdOf(String? payload) =>
    (payload == null || payload.isEmpty) ? null : payload;
