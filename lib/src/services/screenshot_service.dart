import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';

/// Captures a screenshot of the wrapped app, downscaling it to a maximum width
/// and re-encoding as JPEG, mirroring the React Native `ScreenshotService`
/// (`react-native-view-shot` with `{ format: 'jpg', quality, width }`).
///
/// Returns the path to a temporary JPEG file, or `null` if capture fails.
class ScreenshotService {
  ScreenshotService._();

  static Future<String?> capture(
    ScreenshotController controller, {
    double quality = 0.5,
    double maxWidth = 800,
  }) async {
    try {
      final Uint8List? raw = await controller.capture(
        delay: const Duration(milliseconds: 20),
      );
      if (raw == null) return null;

      final decoded = img.decodeImage(raw);
      if (decoded == null) return null;

      final resized = decoded.width > maxWidth
          ? img.copyResize(decoded, width: maxWidth.round())
          : decoded;

      final jpg = img.encodeJpg(
        resized,
        quality: (quality.clamp(0.0, 1.0) * 100).round(),
      );

      final file = File(
        '${Directory.systemTemp.path}/remarka_screenshot_'
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(jpg, flush: true);
      return file.path;
    } catch (error) {
      // ignore: avoid_print
      print('[ReMarka] Screenshot capture failed: $error');
      return null;
    }
  }
}
