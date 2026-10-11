## 0.5.1

- Add `emailErrorText`, `requiredErrorText`, `screenshotLabel` and `offlineWarningText` config options so every form text can be localized.
- Add `ReMarka.updateConfig(ShowOverrideConfig)` to change the base config (e.g. texts after a language switch) without calling `init()` again.
- The moderator-response "read" button now uses the current config plus the last `show()` override instead of the value captured at `init()`.

## 0.5.0

- The consent checkbox and the submit button now stay visible while the keyboard is open; the form lifts them above the keyboard instead of hiding them.
- Remove the inline send button from the message field (`MessageField.showInlineSubmit`, `inlineSubmitLoading` and `onInlineSubmit` are gone).
- Tapping empty space in the form dismisses the keyboard.

## 0.4.1

- Add `emailDefaultText` and `messageDefaultText` config options to pre-fill the email and message fields.
- Fix button state on Android when the keyboard is dismissed with the system back button: the submit button now reappears and the inline send button hides correctly.

## 0.2.0

- Initial Flutter port of the React Native ReMarka feedback SDK.
- Shake-to-feedback, screenshots, rolling logs, offline detection.
- Moderator responses with per-device persisted user id.
- Welcome hint, configurable fields, styles and open animations.
