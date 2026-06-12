# ReMarka for Flutter

A plug-and-play Flutter feedback service. Drop it into any app and let users
submit feedback (with optional screenshot and logs) via a shake gesture or a
programmatic call. A faithful Flutter port of the React Native
[`remarka`](https://remarka.tsoftfactory.com) library.

---

## Installation

```yaml
dependencies:
  remarkaflutter: ^0.2.0
```

The package bundles everything it needs — shake detection
([`shake`](https://pub.dev/packages/shake)), screenshots
([`screenshot`](https://pub.dev/packages/screenshot) + `image`), connectivity
([`connectivity_plus`](https://pub.dev/packages/connectivity_plus)) and a
persisted device id ([`shared_preferences`](https://pub.dev/packages/shared_preferences)) —
so no extra wiring is required.

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:remarkaflutter/remarkaflutter.dart';

void main() {
  // 1. Initialize once before runApp.
  ReMarka.init(const ReMarkaConfig(
    projectId: 'your-project-id',
    apiKey: 'your-api-key',
    logsThreshold: 100,
    withShake: true,
    withScreenshot: false,
    showAnimation: ShowAnimation.slide,
    title: 'Please let us know your thoughts!',
    sentMessage: 'Thank you for your feedback!',
    fields: [FieldType.email, FieldType.textRequired],
    tag: 'feedback',
    meta: {'appVersion': '1.0.0', 'environment': 'production'},
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 2. Mount the provider via MaterialApp.builder so its overlays inherit
      //    Directionality, MediaQuery and Material localizations.
      builder: (context, child) => ReMarkaProvider(
        styles: const ReMarkaStyles(buttonColor: Color(0xFF2563EB)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
    );
  }
}
```

> **Placement.** `ReMarkaProvider` renders its modals as overlays in a `Stack`
> above your app — no `Navigator` is required. Mounting it through
> `MaterialApp.builder` guarantees the overlays have the inherited widgets they
> need. You can also wrap an inner subtree directly with
> `ReMarkaProvider(child: ...)` as long as it sits under a `MaterialApp`.

---

## API

### `ReMarka.init(config)`

`ReMarkaConfig` carries the same defaults as the React Native library:

| Option                     | Type              | Default                                     |
|----------------------------|-------------------|---------------------------------------------|
| `projectId`                | `String`          | — (required)                                |
| `apiKey`                   | `String`          | — (required)                                |
| `apiUrl`                   | `String`          | `https://remarka.tsoftfactory.com/api/v1`   |
| `logsThreshold`            | `int`             | `100` (max `500`)                           |
| `withShake`                | `bool`            | `false`                                     |
| `shakeThreshold`           | `double`          | `1.8` (G-force; lower = more sensitive)     |
| `withScreenshot`           | `bool`            | `false`                                     |
| `screenshotQuality`        | `double`          | `0.5`                                       |
| `screenshotMaxWidth`       | `double`          | `800`                                       |
| `showAnimation`            | `ShowAnimation`   | `ShowAnimation.none`                        |
| `title`                    | `String?`         | —                                           |
| `sentMessage`              | `String`          | `Thank you for your feedback!`              |
| `sentMessageIcon`          | `Widget?`         | `✓` checkmark                               |
| `fields`                   | `List<FieldType>` | `[FieldType.email, FieldType.text]`         |
| `tag`                      | `String`          | `feedback`                                  |
| `emailLabel`               | `String`          | `E-mail`                                    |
| `messageLabel`             | `String`          | `Message`                                   |
| `buttonLabel`              | `String`          | `Send`                                      |
| `emailPlaceholderText`     | `String`          | `your@email.com`                            |
| `messagePlaceholderText`   | `String`          | `Describe the issue or share your thoughts...` |
| `showKeyboardImmediately`  | `bool`            | `true`                                      |
| `keyboardDelay`            | `Duration`        | `1500ms`                                    |
| `meta`                     | `Map<String, Object?>` | `{}`                                   |
| `allowResponse`            | `bool`            | `true`                                      |
| `allowHandleResponse`      | `bool`            | `true`                                      |
| `allowHandleResponseTitle` | `String`          | `Allow response`                            |
| `responseReadButtonLabel`  | `String`          | `Read`                                      |
| `withWelcome`              | `bool`            | `true`                                      |
| `welcomeMessage`           | `String`          | `Shake your device if you'd like to send feedback.` |
| `welcomeDuration`          | `Duration`        | `3000ms`                                    |
| `welcomeIcon`              | `Widget?`         | Animated shake icon                         |
| `welcomePopupColor`        | `Color?`          | —                                           |
| `welcomeMessageStyle`      | `TextStyle?`      | —                                           |

#### Field types

| Value                     | Description                              |
|---------------------------|------------------------------------------|
| `FieldType.email`         | Optional email address field             |
| `FieldType.emailRequired` | Required email address field (validated) |
| `FieldType.text`          | Optional free-text area                  |
| `FieldType.textRequired`  | Required free-text area                  |

### `ReMarka.log(message, [params])`

Appends to a rolling in-memory buffer (capped at `logsThreshold`). Logs are
attached to every submission and cleared after each successful send.

```dart
ReMarka.log('User tapped checkout', [{'cartSize': 3}]);
```

### `ReMarka.show([override])`

Programmatically opens the feedback modal (captures a screenshot first if
enabled). Pass a `ShowOverrideConfig` to override the base config for this call
only (any field except `projectId`, `apiKey`, `apiUrl`).

```dart
ReMarka.show(const ShowOverrideConfig(
  title: 'Found a bug?',
  fields: [FieldType.emailRequired, FieldType.textRequired],
  tag: 'bug-report',
  showAnimation: ShowAnimation.fade,
  buttonLabel: 'Report',
  withScreenshot: true,
));
```

### `ReMarka.hide()`

Programmatically closes the feedback modal.

### `ReMarka.send([SendData])`

Sends feedback directly via the API, bypassing the form UI. Collected logs are
always included. Returns a `Future` that completes when the request finishes.

```dart
await ReMarka.send(const SendData(
  email: 'user@example.com',
  message: 'Payment button does not respond',
  tag: 'bug-report',
));
```

### `ReMarka.setMeta(meta)`

Replaces the custom metadata merged into every submission. The keys
`timestamp`, `platform` and `version` are reserved and always set by the SDK.

### `ReMarka.checkResponses()`

Asks the backend for unread moderator responses and shows them. Called
automatically by `ReMarkaProvider` on mount and on app foreground; call manually
after events the provider can't see (e.g. a push notification). Returns
`Future<List<ResponseMessage>>`.

### `ReMarka.markResponseRead(responseId)`

Marks a response as read so it is never shown again. The response window calls
this for you; exposed for custom flows.

### `ReMarka.userId()`

Resolves the stable, persisted per-device id (`Future<String>`).

### `ReMarka.showWelcome([override])`

Shows the welcome hint regardless of `withWelcome` (which only controls the
automatic show on mount).

### Events

`ReMarkaProvider` exposes outward streams you can listen to:

```dart
ReMarka.onOpen.listen((_) {});        // form became visible
ReMarka.onSent.listen((fields) {});   // submission succeeded
ReMarka.onClose.listen((_) {});       // form closed
ReMarka.onResponse.listen((list) {}); // responses fetched
```

### `ReMarka.enable()` / `disable()` / `isEnabled`

Temporarily suppress the form (e.g. during gestures or animations).

---

## Styling — `ReMarkaStyles`

All fields are optional and merged on top of the defaults. React `StyleProp`
values are mapped to idiomatic Flutter types:

| Prop                          | Type                  | Applies to                       |
|-------------------------------|-----------------------|----------------------------------|
| `containerColor`              | `Color?`              | Form screen background           |
| `containerPadding`            | `EdgeInsetsGeometry?` | Form scroll padding              |
| `titleStyle`                  | `TextStyle?`          | Modal title                      |
| `labelStyle`                  | `TextStyle?`          | Field labels                     |
| `inputStyle`                  | `TextStyle?`          | Text inputs                      |
| `inputBorderColor`            | `Color?`              | Text input borders               |
| `buttonColor` / `buttonTextStyle` | `Color?` / `TextStyle?` | Submit button             |
| `sentMessageContainerColor`   | `Color?`              | Success popup background         |
| `sentMessageTextStyle`        | `TextStyle?`          | Success message text             |
| `responseConsentLabelStyle`   | `TextStyle?`          | Consent checkbox label           |
| `responseContainerColor`      | `Color?`              | Response window background       |
| `responseTitleStyle` / `responseDescriptionStyle` | `TextStyle?` | Response window text |
| `responseButtonColor` / `responseButtonTextStyle` | `Color?` / `TextStyle?` | Response "Read" button |

---

## Moderator responses

ReMarka can show users replies that moderators write to their feedback — a
lightweight one-way "support inbox". The feedback form shows an
**"Allow response"** checkbox (when `allowResponse` and `allowHandleResponse`
are both `true`), and the provider polls the backend on launch / foreground,
popping a window for any unread reply. Pressing **Read** (or dismissing) marks
it read on the server.

A stable per-device `userId` is generated and persisted via `shared_preferences`
so responses survive restarts.

---

## Development / Stub Mode

The default `apiUrl` points to `https://remarka.tsoftfactory.com/api/v1`. To
test locally, pass a custom `apiUrl`. If `apiUrl` is an empty string, the SDK
prints the payload to the console with an 800 ms simulated delay instead of
making a network request.
