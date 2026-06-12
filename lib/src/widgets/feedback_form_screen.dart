import 'package:flutter/material.dart';

import '../types.dart';
import 'feedback_form.dart';

/// Full-screen container that hosts the [FeedbackForm], mirroring the React
/// Native fullscreen `FeedbackModal` form view (background `#F9FAFB`, safe-area
/// padded).
class FeedbackFormScreen extends StatelessWidget {
  const FeedbackFormScreen({
    super.key,
    this.title,
    required this.fields,
    this.screenshotPath,
    required this.emailPlaceholderText,
    required this.messagePlaceholderText,
    required this.emailLabel,
    required this.messageLabel,
    required this.buttonLabel,
    required this.showKeyboardImmediately,
    required this.keyboardDelay,
    this.customStyles,
    required this.isOffline,
    required this.showResponseConsent,
    required this.responseConsentTitle,
    required this.allowResponseDefault,
    required this.allowHandleResponse,
    required this.onSubmit,
    required this.onClose,
  });

  final String? title;
  final List<FieldType> fields;
  final String? screenshotPath;
  final String emailPlaceholderText;
  final String messagePlaceholderText;
  final String emailLabel;
  final String messageLabel;
  final String buttonLabel;
  final bool showKeyboardImmediately;
  final Duration keyboardDelay;
  final ReMarkaStyles? customStyles;
  final bool isOffline;
  final bool showResponseConsent;
  final String responseConsentTitle;
  final bool allowResponseDefault;
  final bool allowHandleResponse;
  final FeedbackSubmitCallback onSubmit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: customStyles?.containerColor ?? const Color(0xFFF9FAFB),
      child: SafeArea(
        child: FeedbackForm(
          title: title,
          fields: fields,
          screenshotPath: screenshotPath,
          emailPlaceholderText: emailPlaceholderText,
          messagePlaceholderText: messagePlaceholderText,
          emailLabel: emailLabel,
          messageLabel: messageLabel,
          buttonLabel: buttonLabel,
          showKeyboardImmediately: showKeyboardImmediately,
          keyboardDelay: keyboardDelay,
          customStyles: customStyles,
          isOffline: isOffline,
          showResponseConsent: showResponseConsent,
          responseConsentTitle: responseConsentTitle,
          allowResponseDefault: allowResponseDefault,
          allowHandleResponse: allowHandleResponse,
          onSubmit: onSubmit,
          onClose: onClose,
        ),
      ),
    );
  }
}
