import 'package:flutter/material.dart';

/// Centered welcome hint shown when shake-to-feedback is enabled, mirroring the
/// React Native `WelcomeToast`. The default icon does a repeating shake wiggle.
/// Tapping the barrier or popup dismisses it.
class WelcomeToast extends StatefulWidget {
  const WelcomeToast({
    super.key,
    required this.message,
    this.icon,
    this.popupColor,
    this.messageStyle,
    required this.onDismiss,
  });

  final String message;
  final Widget? icon;
  final Color? popupColor;
  final TextStyle? messageStyle;
  final VoidCallback onDismiss;

  @override
  State<WelcomeToast> createState() => _WelcomeToastState();
}

class _WelcomeToastState extends State<WelcomeToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    // A short wiggle (~260ms) followed by a 1200ms pause, repeated forever.
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1460),
    )..repeat();

    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 60),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 40),
      TweenSequenceItem(tween: ConstantTween(0), weight: 1200),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon ??
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shake.value, 0),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Image.asset(
              'assets/shake.png',
              package: 'remarkaflutter',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
          ),
        );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDismiss,
      child: Container(
        color: const Color(0x73000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
            decoration: BoxDecoration(
              color: widget.popupColor ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E000000),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                    height: 1.5,
                  ).merge(widget.messageStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
