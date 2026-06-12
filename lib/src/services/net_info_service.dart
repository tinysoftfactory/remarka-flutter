import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity checks backed by `connectivity_plus`.
///
/// Mirrors the React Native `NetInfoService`: an optimistic `true` is returned
/// if connectivity cannot be determined.
class NetInfoService {
  NetInfoService._();

  static final Connectivity _connectivity = Connectivity();

  static bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  /// Returns the current connectivity status.
  static Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isConnected(results);
    } catch (_) {
      return true;
    }
  }

  /// Subscribes to connectivity changes. Returns an unsubscribe function.
  static void Function() subscribe(void Function(bool connected) onChange) {
    final sub = _connectivity.onConnectivityChanged.listen(
      (results) => onChange(_isConnected(results)),
    );
    return sub.cancel;
  }
}
