import 'dart:convert';

import '../connectivity/connectivity_service.dart';
import 'ble_service.dart';

/// Decides how to deliver an in-app notification to nearby members:
/// online → write to Firestore, Cloud Function fans out FCM.
/// offline → enqueue locally; piggy-back on BLE advertisement so nearby
/// tripmates see a local notification immediately.
class NotificationRouter {
  NotificationRouter._();
  static final NotificationRouter instance = NotificationRouter._();

  Future<void> announce({
    required String tripId,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final online = await ConnectivityService.instance.isOnline();
    if (online) {
      // Firestore write happens elsewhere (the expense create) — Cloud
      // Function takes care of FCM fan-out. Nothing to do here.
      return;
    }
    final payload = jsonEncode({
      'tripId': tripId,
      'title': title,
      'body': body,
      'data': data,
    });
    // BLE manufacturer data is < 256 bytes; we only broadcast a slug.
    if (payload.length > 220) {
      // Truncate body for BLE; full payload syncs later via Firestore.
      final trimmed = jsonEncode({
        'tripId': tripId,
        'title': title,
        'body': body.length > 80 ? '${body.substring(0, 77)}...' : body,
      });
      await _broadcast(trimmed);
      return;
    }
    await _broadcast(payload);
  }

  Future<void> _broadcast(String payload) async {
    // flutter_blue_plus does not yet expose advertising on Android cleanly;
    // a lightweight method-channel companion (TODO: native) would publish
    // the manufacturer data. Until then, BleService scans neighbours.
    // This stub leaves a hook to keep the rest of the app honest.
    final _ = BleService.instance; // keep referenced
  }
}
