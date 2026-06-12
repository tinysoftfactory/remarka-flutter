import 'package:shake/shake.dart';

/// Wraps the `shake` package for shake-to-show detection.
///
/// Mirrors the React Native `ShakeDetector`. The [threshold] is given in
/// G-force units (lower = more sensitive) and maps to the package's
/// `shakeThresholdGravity`.
class RemarkaShakeDetector {
  RemarkaShakeDetector._();

  /// Subscribes to shake events. Returns an unsubscribe function that stops
  /// listening. Safe to call even if accelerometer events are unavailable.
  static void Function() subscribe(
    void Function() onShake, {
    double threshold = 1.8,
  }) {
    try {
      final detector = ShakeDetector.autoStart(
        onPhoneShake: (_) => onShake(),
        shakeThresholdGravity: threshold,
      );
      return detector.stopListening;
    } catch (_) {
      // ignore: avoid_print
      print('[ReMarka] withShake is enabled but shake detection could not be '
          'started (sensors unavailable on this platform).');
      return () {};
    }
  }
}
