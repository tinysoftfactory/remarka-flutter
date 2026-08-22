import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remarkaflutter/src/types.dart';
import 'package:remarkaflutter/src/widgets/feedback_form.dart';

Widget _hostForm({required double keyboardInset}) {
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(400, 800),
      viewInsets: EdgeInsets.only(bottom: keyboardInset),
    ),
    child: Localizations(
      locale: const Locale('en', 'US'),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: FeedbackForm(
            title: 'Title',
            fields: const [FieldType.emailRequired, FieldType.textRequired],
            emailPlaceholderText: 'email',
            messagePlaceholderText: 'msg',
            emailLabel: 'Email',
            messageLabel: 'Message',
            buttonLabel: 'Send',
            showKeyboardImmediately: false,
            showResponseConsent: true,
            onSubmit: (_, __) async {},
            onClose: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('consent and submit stay visible above an open keyboard',
      (tester) async {
    await tester.pumpWidget(_hostForm(keyboardInset: 0));
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Allow response'), findsOneWidget);

    await tester.pumpWidget(_hostForm(keyboardInset: 340));
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Allow response'), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Send')).dy, lessThan(800 - 340));
  });
}
