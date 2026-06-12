import 'dart:io';

import 'package:flutter/material.dart';

import '../types.dart';
import 'fields/email_field.dart';
import 'fields/text_field.dart';

/// Consent choices captured alongside a submission.
class FeedbackConsent {
  const FeedbackConsent({
    required this.allowResponse,
    required this.allowHandleResponse,
  });

  final bool allowResponse;
  final bool allowHandleResponse;
}

typedef FeedbackSubmitCallback = Future<void> Function(
  List<FeedbackFieldValue> fields,
  FeedbackConsent consent,
);

bool _isValidEmail(String email) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());

/// Resolves the field that should receive focus on open:
/// 1. First required field
/// 2. First message field
/// 3. First field of any type
/// 4. null if no fields
FieldType? _resolveAutoFocusField(List<FieldType> fields) {
  if (fields.isEmpty) return null;
  for (final f in fields) {
    if (f == FieldType.emailRequired || f == FieldType.textRequired) return f;
  }
  for (final f in fields) {
    if (f == FieldType.text || f == FieldType.textRequired) return f;
  }
  return fields.first;
}

/// The scrollable feedback form, mirroring the React Native `FeedbackForm`.
class FeedbackForm extends StatefulWidget {
  const FeedbackForm({
    super.key,
    this.title,
    required this.fields,
    this.screenshotPath,
    required this.emailPlaceholderText,
    required this.messagePlaceholderText,
    required this.emailLabel,
    required this.messageLabel,
    required this.buttonLabel,
    this.showKeyboardImmediately = true,
    this.keyboardDelay = const Duration(milliseconds: 1500),
    this.customStyles,
    this.isOffline = false,
    this.showResponseConsent = false,
    this.responseConsentTitle = 'Allow response',
    this.allowResponseDefault = true,
    this.allowHandleResponse = true,
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
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  late final Map<FieldType, TextEditingController> _controllers;
  late final Map<FieldType, FocusNode> _focusNodes;
  final Map<FieldType, bool> _errors = {};
  bool _loading = false;
  bool _textFieldFocused = false;
  bool _responseAllowed = true;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.fields) f: TextEditingController(),
    };
    _focusNodes = {
      for (final f in widget.fields) f: FocusNode(),
    };

    for (final f in widget.fields) {
      if (f.isText) {
        _focusNodes[f]!.addListener(() {
          final focused = _focusNodes[f]!.hasFocus;
          if (focused != _textFieldFocused) {
            setState(() => _textFieldFocused = focused);
          }
        });
      }
    }

    _scheduleAutoFocus();
  }

  void _scheduleAutoFocus() {
    if (!widget.showKeyboardImmediately || widget.isOffline) return;
    final target = _resolveAutoFocusField(widget.fields);
    if (target == null) return;

    Future.delayed(widget.keyboardDelay, () {
      if (!mounted) return;
      _focusNodes[target]?.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final n in _focusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    final next = <FieldType, bool>{};
    var valid = true;

    for (final field in widget.fields) {
      final value = _controllers[field]?.text.trim() ?? '';
      if (field == FieldType.emailRequired) {
        if (value.isEmpty || !_isValidEmail(value)) {
          next[field] = true;
          valid = false;
        }
      } else if (field == FieldType.email) {
        if (value.isNotEmpty && !_isValidEmail(value)) {
          next[field] = true;
          valid = false;
        }
      } else if (field == FieldType.textRequired) {
        if (value.isEmpty) {
          next[field] = true;
          valid = false;
        }
      }
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(next);
    });
    return valid;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;
    setState(() => _loading = true);

    final payload = widget.fields
        .map((type) => FeedbackFieldValue(
              type: type,
              value: _controllers[type]?.text.trim() ?? '',
            ))
        .toList();

    final allowResponse = widget.showResponseConsent
        ? _responseAllowed
        : widget.allowResponseDefault;

    try {
      await widget.onSubmit(
        payload,
        FeedbackConsent(
          allowResponse: allowResponse,
          allowHandleResponse: widget.allowHandleResponse,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearErrorOnEdit(FieldType field) {
    if (_errors[field] == true) {
      setState(() => _errors[field] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = widget.customStyles;

    return ListView(
      padding: styles?.containerPadding ??
          const EdgeInsets.fromLTRB(20, 20, 20, 40),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: widget.title != null
                  ? Text(
                      widget.title!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ).merge(styles?.titleStyle),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onClose,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  '✕',
                  style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (widget.screenshotPath != null) ...[
          const Text(
            'Screenshot',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFFF3F4F6),
              child: Image.file(
                File(widget.screenshotPath!),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        ...widget.fields.map(_buildField),
        if (!_textFieldFocused) ...[
          if (widget.showResponseConsent) _buildConsentRow(styles),
          if (widget.isOffline)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Check your Internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          _buildSubmitButton(styles),
        ],
      ],
    );
  }

  Widget _buildField(FieldType field) {
    final styles = widget.customStyles;
    if (field.isEmail) {
      return EmailField(
        controller: _controllers[field]!,
        focusNode: _focusNodes[field],
        required: field == FieldType.emailRequired,
        hasError: _errors[field] ?? false,
        placeholder: widget.emailPlaceholderText,
        label: widget.emailLabel,
        inputStyle: styles?.inputStyle,
        labelStyle: styles?.labelStyle,
        borderColor: styles?.inputBorderColor,
        onChanged: (_) => _clearErrorOnEdit(field),
      );
    }
    return MessageField(
      controller: _controllers[field]!,
      focusNode: _focusNodes[field],
      required: field == FieldType.textRequired,
      hasError: _errors[field] ?? false,
      placeholder: widget.messagePlaceholderText,
      label: widget.messageLabel,
      inputStyle: styles?.inputStyle,
      labelStyle: styles?.labelStyle,
      borderColor: styles?.inputBorderColor,
      onChanged: (_) => _clearErrorOnEdit(field),
      showInlineSubmit: _textFieldFocused,
      inlineSubmitLoading: _loading,
      onInlineSubmit: _handleSubmit,
    );
  }

  Widget _buildConsentRow(ReMarkaStyles? styles) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _responseAllowed = !_responseAllowed),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _responseAllowed
                    ? const Color(0xFF2563EB)
                    : Colors.transparent,
                border: Border.all(
                  color: _responseAllowed
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF9CA3AF),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: _responseAllowed
                  ? const Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Text(
                widget.responseConsentTitle,
                style: const TextStyle(fontSize: 15, color: Color(0xFF374151))
                    .merge(styles?.responseConsentLabelStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ReMarkaStyles? styles) {
    final disabled = _loading || widget.isOffline;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Material(
          color: styles?.buttonColor ?? const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: disabled ? null : _handleSubmit,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      widget.buttonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ).merge(styles?.buttonTextStyle),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
