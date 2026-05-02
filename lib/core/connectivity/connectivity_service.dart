import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _conn = Connectivity();

  Future<bool> isOnline() async {
    final result = await _conn.checkConnectivity();
    return _hasNetwork(result);
  }

  Stream<bool> onChange() => _conn.onConnectivityChanged.map(_hasNetwork);

  bool _hasNetwork(List<ConnectivityResult> r) =>
      r.any((e) => e == ConnectivityResult.wifi || e == ConnectivityResult.mobile || e == ConnectivityResult.ethernet);
}

final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.onChange();
});
