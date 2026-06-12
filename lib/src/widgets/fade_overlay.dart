import 'package:flutter/material.dart';

/// Fades [child] in when [visible] becomes true and out when it becomes false,
/// invoking [onHidden] once the fade-out completes so the parent can unmount it.
///
/// Used for the success, welcome and moderator-response popups, matching the
/// React Native fade timing (250ms in, 200ms out).
class FadeOverlay extends StatefulWidget {
  const FadeOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.onHidden,
  });

  final bool visible;
  final Widget child;
  final VoidCallback? onHidden;

  @override
  State<FadeOverlay> createState() => _FadeOverlayState();
}

class _FadeOverlayState extends State<FadeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    reverseDuration: const Duration(milliseconds: 200),
    value: widget.visible ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.visible) _controller.forward();
  }

  @override
  void didUpdateWidget(FadeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _controller.forward();
    } else if (!widget.visible && oldWidget.visible) {
      _controller.reverse().then((_) {
        if (mounted && !widget.visible) widget.onHidden?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => IgnorePointer(
        ignoring: _controller.value == 0,
        child: Opacity(opacity: _controller.value, child: child),
      ),
      child: widget.child,
    );
  }
}
