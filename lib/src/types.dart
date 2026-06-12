import 'package:flutter/widgets.dart';

/// Default backend base URL used when no [ReMarkaConfig.apiUrl] is provided.
const String kDefaultApiUrl = 'https://remarka.tsoftfactory.com/api/v1';

/// Maximum number of log entries that can be attached to a submission.
const int kMaxLogsThreshold = 500;

/// Default number of log entries attached to a submission.
const int kDefaultLogsThreshold = 100;

/// Internal library version reported in every submission's `meta`.
const String kLibraryVersion = '0.2.0';

/// The kind of field rendered in the feedback form.
enum FieldType {
  /// Optional email address field.
  email('email'),

  /// Required email address field (validated).
  emailRequired('email-required'),

  /// Optional free-text area.
  text('text'),

  /// Required free-text area.
  textRequired('text-required');

  const FieldType(this.wire);

  /// The string representation sent to the backend.
  final String wire;

  /// Whether this field is an email field (optional or required).
  bool get isEmail => this == FieldType.email || this == FieldType.emailRequired;

  /// Whether this field is a free-text field (optional or required).
  bool get isText => this == FieldType.text || this == FieldType.textRequired;

  /// Whether this field must be filled in for the form to submit.
  bool get isRequired =>
      this == FieldType.emailRequired || this == FieldType.textRequired;

  /// Resolves a [FieldType] from its wire string (e.g. `'email-required'`).
  static FieldType fromWire(String value) =>
      FieldType.values.firstWhere((f) => f.wire == value);
}

/// Animation used when the feedback modal opens / closes.
enum ShowAnimation { none, slide, fade }

/// Style overrides for the various ReMarka surfaces.
///
/// All fields are optional and are merged on top of the default styles.
/// This is the Flutter analogue of the React Native `ReMarkaStyles` object —
/// React `StyleProp` values are mapped to the closest idiomatic Flutter types.
class ReMarkaStyles {
  const ReMarkaStyles({
    this.containerColor,
    this.containerPadding,
    this.titleStyle,
    this.labelStyle,
    this.inputStyle,
    this.inputBorderColor,
    this.buttonColor,
    this.buttonTextStyle,
    this.sentMessageContainerColor,
    this.sentMessageTextStyle,
    this.responseConsentLabelStyle,
    this.responseContainerColor,
    this.responseTitleStyle,
    this.responseDescriptionStyle,
    this.responseButtonColor,
    this.responseButtonTextStyle,
  });

  /// Background colour of the scrollable form container.
  final Color? containerColor;

  /// Padding of the scrollable form container.
  final EdgeInsetsGeometry? containerPadding;

  /// Style for the modal title text.
  final TextStyle? titleStyle;

  /// Style for all field label texts.
  final TextStyle? labelStyle;

  /// Style for all text inputs (email and message).
  final TextStyle? inputStyle;

  /// Border colour applied to all text inputs.
  final Color? inputBorderColor;

  /// Background colour of the submit button.
  final Color? buttonColor;

  /// Style for the submit button label text.
  final TextStyle? buttonTextStyle;

  /// Background colour of the success screen popup.
  final Color? sentMessageContainerColor;

  /// Style for the success message text.
  final TextStyle? sentMessageTextStyle;

  /// Style for the response-consent checkbox label text.
  final TextStyle? responseConsentLabelStyle;

  /// Background colour of the moderator-response window.
  final Color? responseContainerColor;

  /// Style for the moderator-response window title text.
  final TextStyle? responseTitleStyle;

  /// Style for the moderator-response window description text.
  final TextStyle? responseDescriptionStyle;

  /// Background colour of the moderator-response "read" button.
  final Color? responseButtonColor;

  /// Style for the moderator-response "read" button label text.
  final TextStyle? responseButtonTextStyle;
}

/// A single entry in the rolling log buffer.
class LogEntry {
  LogEntry({required this.message, required this.params, required this.timestamp});

  final String message;
  final List<Object?> params;
  final int timestamp;

  Map<String, Object?> toJson() => {
        'message': message,
        'params': params,
        'timestamp': timestamp,
      };
}

/// A submitted field together with its value.
class FeedbackFieldValue {
  const FeedbackFieldValue({required this.type, required this.value});

  final FieldType type;
  final String value;

  Map<String, Object?> toJson() => {'type': type.wire, 'value': value};
}

/// The full payload sent to the backend for a feedback submission.
class FeedbackPayload {
  const FeedbackPayload({
    required this.projectId,
    required this.tag,
    required this.fields,
    required this.logs,
    required this.meta,
    this.screenshot,
    this.userId,
    this.allowResponse,
    this.allowHandleResponse,
  });

  final String projectId;
  final String tag;
  final List<FeedbackFieldValue> fields;
  final List<LogEntry> logs;
  final Map<String, Object?> meta;

  /// Local file path or base64 data URI of the captured screenshot, if any.
  final String? screenshot;

  /// Stable per-device user identifier used to attach moderator responses.
  final String? userId;

  /// Whether the user allows a moderator to respond to this feedback.
  final bool? allowResponse;

  /// Whether the user was given a choice about receiving a response.
  final bool? allowHandleResponse;

  Map<String, Object?> toDataJson() => {
        'projectId': projectId,
        'tag': tag,
        'fields': fields.map((f) => f.toJson()).toList(),
        'logs': logs.map((l) => l.toJson()).toList(),
        'userId': userId,
        'allowResponse': allowResponse,
        'allowHandleResponse': allowHandleResponse,
        'meta': meta,
      };
}

/// A moderator's reply to a piece of feedback, returned by the backend.
class ResponseMessage {
  const ResponseMessage({
    required this.id,
    required this.description,
    this.title,
    this.createdAt,
  });

  /// Server-side id of the response, used to mark it as read.
  final String id;

  /// Optional title shown at the top of the response window.
  final String? title;

  /// Response body text (required).
  final String description;

  /// Optional creation timestamp in ms.
  final int? createdAt;

  static ResponseMessage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final description = raw['description'];
    if (id == null || description is! String) return null;
    return ResponseMessage(
      id: id.toString(),
      title: raw['title'] is String ? raw['title'] as String : null,
      description: description,
      createdAt: raw['createdAt'] is int ? raw['createdAt'] as int : null,
    );
  }
}

/// Data accepted by `ReMarka.send` for direct, UI-less submissions.
class SendData {
  const SendData({this.email, this.message, this.tag});

  final String? email;
  final String? message;
  final String? tag;
}

/// Per-call overrides for [ReMarka.showWelcome].
class WelcomeOverrideConfig {
  const WelcomeOverrideConfig({
    this.welcomeMessage,
    this.welcomeDuration,
    this.welcomeIcon,
    this.welcomePopupColor,
    this.welcomeMessageStyle,
  });

  final String? welcomeMessage;
  final Duration? welcomeDuration;
  final Widget? welcomeIcon;
  final Color? welcomePopupColor;
  final TextStyle? welcomeMessageStyle;
}

/// Per-call overrides for [ReMarka.show].
///
/// Any base-config value except `projectId`, `apiKey` and `apiUrl` can be
/// overridden for a single call. Mirrors the React `ShowOverrideConfig`.
class ShowOverrideConfig {
  const ShowOverrideConfig({
    this.logsThreshold,
    this.withShake,
    this.shakeThreshold,
    this.withScreenshot,
    this.title,
    this.sentMessage,
    this.sentMessageIcon,
    this.fields,
    this.showAnimation,
    this.emailPlaceholderText,
    this.messagePlaceholderText,
    this.emailLabel,
    this.messageLabel,
    this.buttonLabel,
    this.tag,
    this.meta,
    this.allowResponse,
    this.allowHandleResponse,
    this.allowHandleResponseTitle,
    this.responseReadButtonLabel,
    this.showKeyboardImmediately,
    this.keyboardDelay,
    this.screenshotQuality,
    this.screenshotMaxWidth,
    this.withWelcome,
    this.welcomeMessage,
    this.welcomeDuration,
    this.welcomeIcon,
    this.welcomePopupColor,
    this.welcomeMessageStyle,
  });

  final int? logsThreshold;
  final bool? withShake;
  final double? shakeThreshold;
  final bool? withScreenshot;
  final String? title;
  final String? sentMessage;
  final Widget? sentMessageIcon;
  final List<FieldType>? fields;
  final ShowAnimation? showAnimation;
  final String? emailPlaceholderText;
  final String? messagePlaceholderText;
  final String? emailLabel;
  final String? messageLabel;
  final String? buttonLabel;
  final String? tag;
  final Map<String, Object?>? meta;
  final bool? allowResponse;
  final bool? allowHandleResponse;
  final String? allowHandleResponseTitle;
  final String? responseReadButtonLabel;
  final bool? showKeyboardImmediately;
  final Duration? keyboardDelay;
  final double? screenshotQuality;
  final double? screenshotMaxWidth;
  final bool? withWelcome;
  final String? welcomeMessage;
  final Duration? welcomeDuration;
  final Widget? welcomeIcon;
  final Color? welcomePopupColor;
  final TextStyle? welcomeMessageStyle;
}

/// Immutable configuration for the ReMarka feedback service.
///
/// Required: [projectId] and [apiKey]. Every other field carries the same
/// default as the React Native library so behaviour matches across platforms.
class ReMarkaConfig {
  const ReMarkaConfig({
    required this.projectId,
    required this.apiKey,
    this.apiUrl = kDefaultApiUrl,
    this.logsThreshold = kDefaultLogsThreshold,
    this.withShake = false,
    this.shakeThreshold = 1.8,
    this.withScreenshot = false,
    this.title,
    this.sentMessage = 'Thank you for your feedback!',
    this.sentMessageIcon,
    this.fields = const [FieldType.email, FieldType.text],
    this.showAnimation = ShowAnimation.none,
    this.emailPlaceholderText = 'your@email.com',
    this.messagePlaceholderText = 'Describe the issue or share your thoughts...',
    this.emailLabel = 'E-mail',
    this.messageLabel = 'Message',
    this.buttonLabel = 'Send',
    this.tag = 'feedback',
    this.meta = const {},
    this.allowResponse = true,
    this.allowHandleResponse = true,
    this.allowHandleResponseTitle = 'Allow response',
    this.responseReadButtonLabel = 'Read',
    this.showKeyboardImmediately = true,
    this.keyboardDelay = const Duration(milliseconds: 1500),
    this.screenshotQuality = 0.5,
    this.screenshotMaxWidth = 800,
    this.withWelcome = true,
    this.welcomeMessage = "Shake your device if you'd like to send feedback.",
    this.welcomeDuration = const Duration(milliseconds: 3000),
    this.welcomeIcon,
    this.welcomePopupColor,
    this.welcomeMessageStyle,
  });

  /// Unique project identifier (required).
  final String projectId;

  /// API key for authentication (required).
  final String apiKey;

  /// Base URL of the ReMarka backend.
  final String apiUrl;

  /// Number of recent logs to include in feedback (max [kMaxLogsThreshold]).
  final int logsThreshold;

  /// Show the feedback form when the device is shaken.
  final bool withShake;

  /// Shake sensitivity in G-force units. Lower = more sensitive.
  final double shakeThreshold;

  /// Capture a screenshot before opening the form.
  final bool withScreenshot;

  /// Heading shown at the top of the feedback modal.
  final String? title;

  /// Message shown after feedback is successfully sent.
  final String sentMessage;

  /// Custom widget rendered above the sent message (replaces the default ✓).
  final Widget? sentMessageIcon;

  /// Fields displayed in the feedback form.
  final List<FieldType> fields;

  /// Modal open animation.
  final ShowAnimation showAnimation;

  final String emailPlaceholderText;
  final String messagePlaceholderText;
  final String emailLabel;
  final String messageLabel;
  final String buttonLabel;

  /// Tag sent with every submission for categorisation.
  final String tag;

  /// Custom metadata merged into every submission.
  final Map<String, Object?> meta;

  /// Master switch for the moderator-response feature.
  final bool allowResponse;

  /// Show a consent checkbox so the user can opt in/out of receiving a reply.
  final bool allowHandleResponse;

  /// Title of the response-consent checkbox.
  final String allowHandleResponseTitle;

  /// Label for the "read" button on the moderator-response window.
  final String responseReadButtonLabel;

  /// Automatically focus the first relevant input after the form opens.
  final bool showKeyboardImmediately;

  /// Delay before the keyboard is shown after the form opens.
  final Duration keyboardDelay;

  /// JPEG quality for screenshot compression, 0–1.
  final double screenshotQuality;

  /// Max width in pixels for screenshot downscaling.
  final double screenshotMaxWidth;

  /// Show a welcome hint after init when [withShake] is true.
  final bool withWelcome;

  /// Text shown in the welcome hint.
  final String welcomeMessage;

  /// How long the welcome hint stays visible.
  final Duration welcomeDuration;

  /// Custom widget rendered above the welcome message (replaces the shake icon).
  final Widget? welcomeIcon;

  /// Background colour of the welcome popup container.
  final Color? welcomePopupColor;

  /// Style for the welcome message text.
  final TextStyle? welcomeMessageStyle;

  /// Returns a new config with [override] applied on top of this one,
  /// mirroring the React `{ ...config, ...override }` spread.
  ReMarkaConfig applyOverride(ShowOverrideConfig? o) {
    if (o == null) return this;
    return ReMarkaConfig(
      projectId: projectId,
      apiKey: apiKey,
      apiUrl: apiUrl,
      logsThreshold: o.logsThreshold ?? logsThreshold,
      withShake: o.withShake ?? withShake,
      shakeThreshold: o.shakeThreshold ?? shakeThreshold,
      withScreenshot: o.withScreenshot ?? withScreenshot,
      title: o.title ?? title,
      sentMessage: o.sentMessage ?? sentMessage,
      sentMessageIcon: o.sentMessageIcon ?? sentMessageIcon,
      fields: o.fields ?? fields,
      showAnimation: o.showAnimation ?? showAnimation,
      emailPlaceholderText: o.emailPlaceholderText ?? emailPlaceholderText,
      messagePlaceholderText: o.messagePlaceholderText ?? messagePlaceholderText,
      emailLabel: o.emailLabel ?? emailLabel,
      messageLabel: o.messageLabel ?? messageLabel,
      buttonLabel: o.buttonLabel ?? buttonLabel,
      tag: o.tag ?? tag,
      meta: o.meta ?? meta,
      allowResponse: o.allowResponse ?? allowResponse,
      allowHandleResponse: o.allowHandleResponse ?? allowHandleResponse,
      allowHandleResponseTitle:
          o.allowHandleResponseTitle ?? allowHandleResponseTitle,
      responseReadButtonLabel:
          o.responseReadButtonLabel ?? responseReadButtonLabel,
      showKeyboardImmediately:
          o.showKeyboardImmediately ?? showKeyboardImmediately,
      keyboardDelay: o.keyboardDelay ?? keyboardDelay,
      screenshotQuality: o.screenshotQuality ?? screenshotQuality,
      screenshotMaxWidth: o.screenshotMaxWidth ?? screenshotMaxWidth,
      withWelcome: o.withWelcome ?? withWelcome,
      welcomeMessage: o.welcomeMessage ?? welcomeMessage,
      welcomeDuration: o.welcomeDuration ?? welcomeDuration,
      welcomeIcon: o.welcomeIcon ?? welcomeIcon,
      welcomePopupColor: o.welcomePopupColor ?? welcomePopupColor,
      welcomeMessageStyle: o.welcomeMessageStyle ?? welcomeMessageStyle,
    );
  }
}
