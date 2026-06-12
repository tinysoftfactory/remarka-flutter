import 'dart:convert';

import 'package:http/http.dart' as http;

import '../types.dart';

/// Talks to the ReMarka backend: submits feedback, fetches moderator
/// responses and marks them as read.
///
/// Mirrors the React Native `ApiService`. When [apiUrl] is an empty string the
/// service runs in "stub mode" — it prints the payload and resolves after a
/// short delay instead of making a network request.
class ApiService {
  ApiService(this.apiUrl, this.apiKey);

  final String apiUrl;
  final String apiKey;

  static const Duration _stubDelay = Duration(milliseconds: 800);

  bool get _isStub => apiUrl.isEmpty;

  Map<String, String> get _headers => {
        'X-Api-Key': apiKey,
        'Accept': 'application/json',
      };

  /// Submits a feedback payload (multipart, optionally with a screenshot file).
  Future<void> sendFeedback(FeedbackPayload payload) async {
    if (_isStub) {
      // ignore: avoid_print
      print('[ReMarka] STUB — feedback payload:\n'
          '${const JsonEncoder.withIndent('  ').convert(payload.toDataJson())}');
      await Future<void>.delayed(_stubDelay);
      return;
    }

    final request = http.MultipartRequest('POST', Uri.parse('$apiUrl/feedback'))
      ..headers.addAll(_headers)
      ..fields['data'] = jsonEncode(payload.toDataJson());

    final screenshot = payload.screenshot;
    if (screenshot != null && screenshot.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'screenshot',
          screenshot,
          filename: 'screenshot.jpg',
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _throwIfNotOk(response);
  }

  /// Fetches pending (unread) moderator responses for this user.
  /// Returns an empty list when there are none.
  Future<List<ResponseMessage>> getResponses(
    String projectId,
    String userId,
  ) async {
    if (_isStub) return const [];

    final uri = Uri.parse('$apiUrl/responses').replace(queryParameters: {
      'projectId': projectId,
      'userId': userId,
    });

    final response = await http.get(uri, headers: _headers);
    _throwIfNotOk(response);

    Object? body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      return const [];
    }

    final list = body is List
        ? body
        : (body is Map ? body['responses'] : null);
    if (list is! List) return const [];

    return list
        .map(ResponseMessage.fromJson)
        .whereType<ResponseMessage>()
        .toList();
  }

  /// Marks a moderator response as read so it is no longer returned.
  Future<void> markResponseRead(
    String projectId,
    String userId,
    String responseId,
  ) async {
    if (_isStub) return;

    final response = await http.post(
      Uri.parse('$apiUrl/responses/${Uri.encodeComponent(responseId)}/read'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'projectId': projectId, 'userId': userId}),
    );
    _throwIfNotOk(response);
  }

  void _throwIfNotOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = response.body.isNotEmpty
          ? response.body
          : response.reasonPhrase ?? '';
      throw Exception('ReMarka API error ${response.statusCode}: $detail');
    }
  }
}
