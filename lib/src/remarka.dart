import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'services/api_service.dart';
import 'services/user_id_service.dart';
import 'types.dart';

/// The ReMarka feedback controller.
///
/// A singleton that owns the configuration, the rolling log buffer, the API
/// client and the event streams that [ReMarkaProvider] listens to. Mirrors the
/// React Native `ReMarkaController`.
///
/// Use the static methods (`ReMarka.init`, `ReMarka.show`, …) from anywhere in
/// your app. The instance members are used internally by [ReMarkaProvider].
class ReMarka {
  ReMarka._();

  static final ReMarka instance = ReMarka._();

  ReMarkaConfig? _config;
  ApiService? _api;
  final List<LogEntry> _logs = [];
  Map<String, Object?> _userMeta = const {};
  bool _enabled = true;

  // ─── Internal event streams (consumed by ReMarkaProvider) ──────────────────

  final StreamController<ShowOverrideConfig?> _showRequests =
      StreamController<ShowOverrideConfig?>.broadcast();
  final StreamController<void> _hideRequests =
      StreamController<void>.broadcast();
  final StreamController<WelcomeOverrideConfig?> _welcomeRequests =
      StreamController<WelcomeOverrideConfig?>.broadcast();

  // ─── Public event streams (for consumers) ──────────────────────────────────

  final StreamController<void> _opened = StreamController<void>.broadcast();
  final StreamController<List<FeedbackFieldValue>> _sent =
      StreamController<List<FeedbackFieldValue>>.broadcast();
  final StreamController<void> _closed = StreamController<void>.broadcast();
  final StreamController<List<ResponseMessage>> _responses =
      StreamController<List<ResponseMessage>>.broadcast();

  /// Emitted when the feedback form becomes visible.
  static Stream<void> get onOpen => instance._opened.stream;

  /// Emitted after feedback is successfully submitted, with the submitted fields.
  static Stream<List<FeedbackFieldValue>> get onSent => instance._sent.stream;

  /// Emitted when the feedback form closes (after success or manual close).
  static Stream<void> get onClose => instance._closed.stream;

  /// Emitted when pending moderator responses are fetched from the backend.
  static Stream<List<ResponseMessage>> get onResponse =>
      instance._responses.stream;

  // ─── Provider-internal stream accessors ────────────────────────────────────

  /// Internal: stream of `show` requests. Used by [ReMarkaProvider].
  Stream<ShowOverrideConfig?> get showRequests => _showRequests.stream;

  /// Internal: stream of `hide` requests. Used by [ReMarkaProvider].
  Stream<void> get hideRequests => _hideRequests.stream;

  /// Internal: stream of `welcome` requests. Used by [ReMarkaProvider].
  Stream<WelcomeOverrideConfig?> get welcomeRequests =>
      _welcomeRequests.stream;

  /// Internal: stream of fetched moderator responses. Used by [ReMarkaProvider].
  Stream<List<ResponseMessage>> get responseRequests => _responses.stream;

  // ─── Public static API ─────────────────────────────────────────────────────

  /// Initializes the SDK. Call once before mounting [ReMarkaProvider].
  static void init(ReMarkaConfig config) {
    final threshold = config.logsThreshold > kMaxLogsThreshold
        ? kMaxLogsThreshold
        : config.logsThreshold;

    final resolved = config.logsThreshold == threshold
        ? config
        : config.applyOverride(ShowOverrideConfig(logsThreshold: threshold));

    instance._config = resolved;
    instance._api = ApiService(resolved.apiUrl, resolved.apiKey);
    instance._userMeta = Map<String, Object?>.from(config.meta);

    if (kDebugMode) {
      debugPrint('[ReMarka] Initialized for project ${resolved.projectId}');
    }
  }

  /// Appends an entry to the in-memory rolling log buffer (capped at
  /// `logsThreshold`). Logs are attached to every submission and cleared after
  /// each successful send.
  static void log(String message, [List<Object?> params = const []]) {
    final inst = instance;
    final threshold = inst._config?.logsThreshold ?? kDefaultLogsThreshold;

    inst._logs.add(LogEntry(
      message: message,
      params: params,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));

    if (inst._logs.length > threshold) {
      inst._logs.removeRange(0, inst._logs.length - threshold);
    }
  }

  /// Programmatically opens the feedback modal (captures a screenshot first if
  /// enabled). Pass [override] to override the base config for this call only.
  static void show([ShowOverrideConfig? override]) {
    if (!instance._enabled) return;
    instance._showRequests.add(override);
  }

  /// Temporarily disable the feedback form (e.g. during gestures or animations).
  static void disable() => instance._enabled = false;

  /// Re-enable the feedback form after it was disabled.
  static void enable() => instance._enabled = true;

  /// Whether the feedback form is currently allowed to appear.
  static bool get isEnabled => instance._enabled;

  /// Replaces the custom metadata merged into every submission.
  static void setMeta(Map<String, Object?> meta) =>
      instance._userMeta = Map<String, Object?>.from(meta);

  /// Programmatically closes the feedback modal.
  static void hide() => instance._hideRequests.add(null);

  /// Programmatically shows the welcome hint, regardless of `withWelcome`.
  static void showWelcome([WelcomeOverrideConfig? override]) =>
      instance._welcomeRequests.add(override);

  /// Sends feedback directly via the API, bypassing the form UI.
  static Future<void> send([SendData data = const SendData()]) async {
    final inst = instance;
    final config = inst.getConfig();
    final api = inst.getApi();

    final fields = <FeedbackFieldValue>[];
    if (data.email != null) {
      fields.add(FeedbackFieldValue(type: FieldType.email, value: data.email!));
    }
    if (data.message != null) {
      fields.add(
          FeedbackFieldValue(type: FieldType.text, value: data.message!));
    }

    await api.sendFeedback(FeedbackPayload(
      projectId: config.projectId,
      tag: data.tag ?? config.tag,
      fields: fields,
      logs: inst.getLogs(),
      userId: await inst.getUserId(),
      allowResponse: config.allowResponse,
      allowHandleResponse: config.allowHandleResponse,
      meta: inst.getMeta(),
    ));
  }

  /// Checks the backend for pending moderator responses and, if any are found,
  /// emits them so [ReMarkaProvider] can display the response window.
  static Future<List<ResponseMessage>> checkResponses() async {
    final inst = instance;
    final config = inst._config;
    if (config == null) return const [];
    if (!config.allowResponse) return const [];

    try {
      final userId = await inst.getUserId();
      final responses = await inst.getApi().getResponses(
            config.projectId,
            userId,
          );
      if (responses.isNotEmpty) {
        inst._responses.add(responses);
      }
      return responses;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ReMarka] Failed to check for responses: $error');
      }
      return const [];
    }
  }

  /// Marks a moderator response as read so it is no longer shown.
  static Future<void> markResponseRead(String responseId) async {
    final inst = instance;
    final config = inst._config;
    if (config == null) return;

    try {
      final userId = await inst.getUserId();
      await inst.getApi().markResponseRead(
            config.projectId,
            userId,
            responseId,
          );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ReMarka] Failed to mark response as read: $error');
      }
    }
  }

  /// Resolves the stable, persisted per-device user id.
  static Future<String> userId() => UserIdService.getUserId();

  // ─── Internal helpers used by ReMarkaProvider ──────────────────────────────

  /// Internal: the resolved configuration. Throws if [init] was not called.
  ReMarkaConfig getConfig() {
    final config = _config;
    if (config == null) {
      throw StateError(
        '[ReMarka] Not initialized. Call ReMarka.init() before using '
        'ReMarkaProvider.',
      );
    }
    return config;
  }

  /// Internal: the configuration, or `null` if not initialized.
  ReMarkaConfig? get configOrNull => _config;

  /// Internal: a snapshot of the current log buffer.
  List<LogEntry> getLogs() {
    final threshold = _config?.logsThreshold ?? kDefaultLogsThreshold;
    if (_logs.length <= threshold) return List.unmodifiable(_logs);
    return List.unmodifiable(_logs.sublist(_logs.length - threshold));
  }

  /// Internal: clears the log buffer (after a successful send).
  void clearLogs() => _logs.clear();

  /// Internal: the API client. Throws if [init] was not called.
  ApiService getApi() {
    final api = _api;
    if (api == null) {
      throw StateError(
        '[ReMarka] Not initialized. Call ReMarka.init() before using '
        'ReMarkaProvider.',
      );
    }
    return api;
  }

  /// Internal: the merged metadata, with reserved keys always set.
  Map<String, Object?> getMeta() => {
        ..._userMeta,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'platform': _platformName(),
        'version': kLibraryVersion,
      };

  /// Internal: resolves the per-device user id.
  Future<String> getUserId() => UserIdService.getUserId();

  /// Internal: emits the `open` event.
  void emitOpen() => _opened.add(null);

  /// Internal: emits the `sent` event.
  void emitSent(List<FeedbackFieldValue> fields) => _sent.add(fields);

  /// Internal: emits the `close` event.
  void emitClose() => _closed.add(null);

  static String _platformName() {
    if (kIsWeb) return 'web';
    return Platform.operatingSystem;
  }
}
