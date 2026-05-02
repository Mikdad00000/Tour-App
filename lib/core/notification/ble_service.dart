import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'local_notifications.dart';

/// BLE peer-to-peer fallback. When offline, advertises pending notifications
/// and scans nearby tripmates to receive theirs. Best-effort.
///
/// flutter_blue_plus does not support advertising/peripheral mode on iOS but
/// works on Android via the GATT server APIs in newer versions. We implement
/// scan-only here and rely on a small companion native plugin for advertising.
class BleService {
  BleService._();
  static final BleService instance = BleService._();

  static const String tourServiceUuid = '0000face-0000-1000-8000-00805f9b34fb';

  StreamSubscription<List<ScanResult>>? _scanSub;
  String? _activeTripId;
  void Function(Map<String, dynamic> json)? onIncoming;

  Future<bool> ensurePermissions() async {
    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return results.values.every((s) => s.isGranted);
  }

  Future<void> startScan(String tripId) async {
    if (!await ensurePermissions()) return;
    if (!(await FlutterBluePlus.isSupported)) return;
    _activeTripId = tripId;
    await FlutterBluePlus.startScan(
      withServices: [Guid(tourServiceUuid)],
      timeout: const Duration(seconds: 30),
      continuousUpdates: true,
    );
    _scanSub = FlutterBluePlus.scanResults.listen(_onScan);
  }

  Future<void> stop() async {
    await _scanSub?.cancel();
    _scanSub = null;
    await FlutterBluePlus.stopScan();
    _activeTripId = null;
  }

  Future<void> _onScan(List<ScanResult> results) async {
    for (final r in results) {
      // manufacturer data: { 0xFA: <gzip(json) of pending notif> }
      final mdata = r.advertisementData.manufacturerData;
      for (final entry in mdata.entries) {
        try {
          final raw = utf8.decode(entry.value);
          final json = jsonDecode(raw) as Map<String, dynamic>;
          if (json['tripId'] != _activeTripId) continue;
          onIncoming?.call(json);
          await LocalNotifications.show(
            id: json.hashCode,
            title: (json['title'] as String?) ?? 'Tour (offline)',
            body: (json['body'] as String?) ?? '',
          );
        } catch (_) {/* ignore malformed payloads */}
      }
    }
  }
}
