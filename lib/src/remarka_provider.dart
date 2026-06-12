import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import 'remarka.dart';
import 'services/net_info_service.dart';
import 'services/screenshot_service.dart';
import 'services/shake_detector.dart';
import 'types.dart';
import 'widgets/fade_overlay.dart';
import 'widgets/feedback_form.dart';
import 'widgets/feedback_form_screen.dart';
import 'widgets/response_modal.dart';
import 'widgets/success_popup.dart';
import 'widgets/welcome_toast.dart';

const Duration _kSuccessVisible = Duration(milliseconds: 2500);
const Duration _kFormAnimation = Duration(milliseconds: 350);

enum _Phase { none, form, success }

/// Mounts the feedback UI and wires up shake detection, screenshots,
/// connectivity and moderator responses.
///
/// Place it once near the root of your tree — the recommended spot is the
/// `MaterialApp.builder`, so the overlays inherit `Directionality`,
/// `MediaQuery` and Material localizations:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) =>
///       ReMarkaProvider(child: child ?? const SizedBox.shrink()),
///   home: const HomePage(),
/// );
/// ```
///
/// Mirrors the React Native `ReMarkaProvider`.
class ReMarkaProvider extends StatefulWidget {
  const ReMarkaProvider({super.key, required this.child, this.styles});

  /// The app subtree the provider wraps (and screenshots).
  final Widget child;

  /// Optional style overrides merged on top of the defaults.
  final ReMarkaStyles? styles;

  @override
  State<ReMarkaProvider> createState() => _ReMarkaProviderState();
}

class _ReMarkaProviderState extends State<ReMarkaProvider>
    with WidgetsBindingObserver {
  final ScreenshotController _screenshotController = ScreenshotController();

  _Phase _phase = _Phase.none;

  // Reactive flags driven without setState so the form's OverlayEntry (and the
  // TextEditingControllers it owns) stay mounted while the form is open.
  final ValueNotifier<bool> _formVisible = ValueNotifier(false);
  final ValueNotifier<bool> _isOffline = ValueNotifier(false);

  ReMarkaConfig? _formConfig;
  String? _screenshotPath;
  String _successMessage = '';
  Widget? _successIcon;
  bool _successVisible = false;

  // Welcome hint state.
  bool _welcomeVisible = false;
  String _welcomeMessage = '';
  Widget? _welcomeIcon;
  Color? _welcomePopupColor;
  TextStyle? _welcomeMessageStyle;

  final List<ResponseMessage> _responseQueue = [];

  Timer? _successTimer;
  Timer? _closeTimer;
  Timer? _welcomeTimer;

  void Function()? _shakeUnsub;
  void Function()? _netUnsub;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final inst = ReMarka.instance;
    _subs.add(inst.showRequests.listen(_openForm));
    _subs.add(inst.hideRequests.listen((_) => _dismiss()));
    _subs.add(inst.welcomeRequests.listen(_openWelcome));
    _subs.add(inst.responseRequests.listen(_enqueueResponses));

    final config = inst.configOrNull;
    if (config != null && config.withShake) {
      _shakeUnsub = RemarkaShakeDetector.subscribe(() {
        if (ReMarka.isEnabled) _openForm(null);
      }, threshold: config.shakeThreshold);

      if (config.withWelcome) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openWelcome(null));
      }
    }

    // Check for pending responses on mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReMarka.checkResponses();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ReMarka.checkResponses();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subs) {
      s.cancel();
    }
    _shakeUnsub?.call();
    _netUnsub?.call();
    _clearTimers();
    _formVisible.dispose();
    _isOffline.dispose();
    super.dispose();
  }

  void _clearTimers() {
    _successTimer?.cancel();
    _closeTimer?.cancel();
    _welcomeTimer?.cancel();
  }

  // ─── Form open / close ─────────────────────────────────────────────────────

  Future<void> _openForm(ShowOverrideConfig? override) async {
    if (_phase != _Phase.none) return;

    final base = ReMarka.instance.configOrNull;
    if (base == null) return;
    final config = base.applyOverride(override);

    String? screenshotPath;
    if (config.withScreenshot) {
      screenshotPath = await ScreenshotService.capture(
        _screenshotController,
        quality: config.screenshotQuality,
        maxWidth: config.screenshotMaxWidth,
      );
    }

    final connected = await NetInfoService.isConnected();
    if (!mounted) return;

    _netUnsub?.call();
    _netUnsub = NetInfoService.subscribe((c) => _isOffline.value = !c);
    _isOffline.value = !connected;

    setState(() {
      _formConfig = config;
      _screenshotPath = screenshotPath;
      _phase = _Phase.form;
    });
    _formVisible.value = config.showAnimation == ShowAnimation.none;

    // Animate in on the next frame so the entrance transition runs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _formVisible.value = true;
      ReMarka.instance.emitOpen();
    });
  }

  void _closeForm() {
    _clearTimers();
    _formVisible.value = false;
    ReMarka.instance.emitClose();

    final config = _formConfig;
    final delay = config?.showAnimation == ShowAnimation.none
        ? Duration.zero
        : _kFormAnimation;
    _closeTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.none;
        _screenshotPath = null;
      });
      _netUnsub?.call();
      _netUnsub = null;
    });
  }

  void _showSuccess(String message, Widget? icon) {
    _clearTimers();
    setState(() {
      _phase = _Phase.success;
      _successMessage = message;
      _successIcon = icon;
      _successVisible = true;
    });
    _successTimer = Timer(_kSuccessVisible, _closeSuccess);
  }

  void _closeSuccess() {
    _clearTimers();
    setState(() => _successVisible = false);
    ReMarka.instance.emitClose();
    // Unmounting happens in FadeOverlay.onHidden.
  }

  void _dismiss() {
    if (_phase == _Phase.form) {
      _closeForm();
    } else if (_phase == _Phase.success) {
      _closeSuccess();
    }
  }

  Future<void> _handleSubmit(
    List<FeedbackFieldValue> fields,
    FeedbackConsent consent,
  ) async {
    final base = ReMarka.instance.getConfig();
    final config = _formConfig ?? base;
    final api = ReMarka.instance.getApi();

    try {
      await api.sendFeedback(
        FeedbackPayload(
          projectId: base.projectId,
          tag: config.tag,
          fields: fields,
          logs: ReMarka.instance.getLogs(),
          screenshot: _screenshotPath,
          userId: await ReMarka.instance.getUserId(),
          allowResponse: consent.allowResponse,
          allowHandleResponse: consent.allowHandleResponse,
          meta: ReMarka.instance.getMeta(),
        ),
      );
    } catch (error) {
      debugPrint('[ReMarka] Failed to send feedback: $error');
    }

    ReMarka.instance.emitSent(fields);
    ReMarka.instance.clearLogs();
    if (!mounted) return;
    _showSuccess(config.sentMessage, config.sentMessageIcon);
  }

  // ─── Welcome ───────────────────────────────────────────────────────────────

  void _openWelcome(WelcomeOverrideConfig? override) {
    final config = ReMarka.instance.configOrNull;
    if (config == null) return;

    final message = override?.welcomeMessage ?? config.welcomeMessage;
    final duration = override?.welcomeDuration ?? config.welcomeDuration;

    setState(() {
      _welcomeMessage = message;
      _welcomeIcon = override?.welcomeIcon ?? config.welcomeIcon;
      _welcomePopupColor =
          override?.welcomePopupColor ?? config.welcomePopupColor;
      _welcomeMessageStyle =
          override?.welcomeMessageStyle ?? config.welcomeMessageStyle;
      _welcomeVisible = true;
    });

    _welcomeTimer?.cancel();
    _welcomeTimer = Timer(duration, () {
      if (mounted) setState(() => _welcomeVisible = false);
    });
  }

  // ─── Responses ─────────────────────────────────────────────────────────────

  void _enqueueResponses(List<ResponseMessage> responses) {
    setState(() {
      final seen = _responseQueue.map((r) => r.id).toSet();
      _responseQueue.addAll(responses.where((r) => !seen.contains(r.id)));
    });
  }

  void _handleResponseRead() {
    if (_responseQueue.isEmpty) return;
    final current = _responseQueue.first;
    ReMarka.markResponseRead(current.id);
    setState(() => _responseQueue.removeWhere((r) => r.id == current.id));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentResponse = _responseQueue.isNotEmpty
        ? _responseQueue.first
        : null;

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(
          child: Screenshot(
            controller: _screenshotController,
            child: widget.child,
          ),
        ),
        if (_phase == _Phase.form && _formConfig != null)
          // The form hosts TextFields, which require an Overlay ancestor for
          // cursor/selection handles. We give it a dedicated Overlay and feed
          // reactive state through ValueNotifiers so the entry (and its
          // TextEditingControllers) survives rebuilds.
          Positioned.fill(
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => ListenableBuilder(
                    listenable: Listenable.merge([_formVisible, _isOffline]),
                    builder: (_, __) => _buildFormLayer(_formConfig!),
                  ),
                ),
              ],
            ),
          ),
        if (_phase == _Phase.success)
          Positioned.fill(
            child: FadeOverlay(
              visible: _successVisible,
              onHidden: () {
                if (mounted) setState(() => _phase = _Phase.none);
              },
              child: SuccessPopup(
                message: _successMessage,
                icon: _successIcon,
                customStyles: widget.styles,
                onClose: _closeSuccess,
              ),
            ),
          ),
        Positioned.fill(
          child: FadeOverlay(
            visible: _welcomeVisible,
            child: WelcomeToast(
              message: _welcomeMessage,
              icon: _welcomeIcon,
              popupColor: _welcomePopupColor,
              messageStyle: _welcomeMessageStyle,
              onDismiss: () {
                _welcomeTimer?.cancel();
                setState(() => _welcomeVisible = false);
              },
            ),
          ),
        ),
        Positioned.fill(
          child: FadeOverlay(
            visible: currentResponse != null,
            child: currentResponse == null
                ? const SizedBox.shrink()
                : ResponseModal(
                    response: currentResponse,
                    readButtonLabel:
                        ReMarka
                            .instance
                            .configOrNull
                            ?.responseReadButtonLabel ??
                        'Read',
                    customStyles: widget.styles,
                    onRead: _handleResponseRead,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormLayer(ReMarkaConfig config) {
    final allowResponse = config.allowResponse;
    final allowHandleResponse = config.allowHandleResponse;

    final form = FeedbackFormScreen(
      title: config.title,
      fields: config.fields,
      screenshotPath: _screenshotPath,
      emailPlaceholderText: config.emailPlaceholderText,
      messagePlaceholderText: config.messagePlaceholderText,
      emailLabel: config.emailLabel,
      messageLabel: config.messageLabel,
      buttonLabel: config.buttonLabel,
      showKeyboardImmediately: config.showKeyboardImmediately,
      keyboardDelay: config.keyboardDelay,
      customStyles: widget.styles,
      isOffline: _isOffline.value,
      showResponseConsent: allowResponse && allowHandleResponse,
      responseConsentTitle: config.allowHandleResponseTitle,
      allowResponseDefault: allowResponse,
      allowHandleResponse: allowHandleResponse,
      onSubmit: _handleSubmit,
      onClose: _closeForm,
    );

    switch (config.showAnimation) {
      case ShowAnimation.none:
        return form;
      case ShowAnimation.fade:
        return AnimatedOpacity(
          opacity: _formVisible.value ? 1 : 0,
          duration: _kFormAnimation,
          child: form,
        );
      case ShowAnimation.slide:
        return AnimatedSlide(
          offset: _formVisible.value ? Offset.zero : const Offset(0, 1),
          duration: _kFormAnimation,
          curve: Curves.easeOut,
          child: form,
        );
    }
  }
}
