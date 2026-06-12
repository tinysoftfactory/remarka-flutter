import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Provides a stable, persisted per-device identifier used to attach moderator
/// responses to the right user.
///
/// Persistence relies on `shared_preferences`. If reading/writing storage fails
/// for any reason, a per-session in-memory id is used instead so responses keep
/// working within a single app session.
class UserIdService {
  UserIdService._();

  static const String _storageKey = '@remarka:userId';

  static String? _cachedId;
  static Future<String>? _pending;

  /// Returns the stable user id, generating and persisting one on first use.
  /// The result is cached for the lifetime of the isolate.
  static Future<String> getUserId() {
    final cached = _cachedId;
    if (cached != null) return Future.value(cached);
    return _pending ??= _resolve();
  }

  static Future<String> _resolve() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_storageKey);
      if (existing != null && existing.isNotEmpty) {
        _cachedId = existing;
        return existing;
      }
      final fresh = _generateUserId();
      await prefs.setString(_storageKey, fresh);
      _cachedId = fresh;
      return fresh;
    } catch (_) {
      // Storage failed — fall back to an ephemeral, session-scoped id.
      final ephemeral = _cachedId ??= _generateUserId();
      return ephemeral;
    }
  }

  /// RFC4122-ish v4 id. Not cryptographically strong — only needs to be unique
  /// per device.
  static String _generateUserId() {
    final rng = Random();
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp('[xy]'),
      (match) {
        final r = rng.nextInt(16);
        final v = match[0] == 'x' ? r : (r & 0x3) | 0x8;
        return v.toRadixString(16);
      },
    );
  }
}
