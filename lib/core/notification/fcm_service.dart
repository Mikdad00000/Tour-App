import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await LocalNotifications.show(
    id: message.messageId.hashCode,
    title: message.notification?.title ?? 'Tour',
    body: message.notification?.body ?? '',
  );
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _fm = FirebaseMessaging.instance;

  Future<void> init() async {
    await _fm.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_bgHandler);
    FirebaseMessaging.onMessage.listen((m) {
      LocalNotifications.show(
        id: m.messageId.hashCode,
        title: m.notification?.title ?? 'Tour',
        body: m.notification?.body ?? '',
      );
    });
    await _saveTokenIfLoggedIn();
    _fm.onTokenRefresh.listen((_) => _saveTokenIfLoggedIn());
  }

  Future<void> _saveTokenIfLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _fm.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }
}
