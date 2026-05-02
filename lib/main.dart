import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/firebase_options.dart';
import 'core/notification/fcm_service.dart';
import 'core/notification/local_notifications.dart';
import 'core/sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotifications.init();
  await FcmService.instance.init();
  await SyncService.instance.init();
  runApp(const ProviderScope(child: TourApp()));
}
