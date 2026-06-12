import 'package:flutter/material.dart';
import 'package:remarkaflutter/remarkaflutter.dart';

void main() {
  ReMarka.init(const ReMarkaConfig(
    projectId: 'demo-project',
    apiKey: 'demo-key',
    // Empty apiUrl → stub mode: the payload is printed to the console instead
    // of being sent over the network. Great for trying the UI out.
    apiUrl: '',
    withShake: true,
    withScreenshot: true,
    showAnimation: ShowAnimation.slide,
    title: 'Send us your feedback',
    fields: [FieldType.email, FieldType.textRequired],
    tag: 'demo',
  ));

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReMarka Example',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2563EB),
        useMaterial3: true,
      ),
      builder: (context, child) => ReMarkaProvider(
        styles: const ReMarkaStyles(buttonColor: Color(0xFF2563EB)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ReMarka Demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Shake the device, or use the buttons below.',
                textAlign: TextAlign.center,
              ),
            ),
            FilledButton(
              onPressed: () {
                ReMarka.log('Opened feedback from button');
                ReMarka.show();
              },
              child: const Text('Open feedback form'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ReMarka.show(const ShowOverrideConfig(
                title: 'Found a bug?',
                tag: 'bug-report',
                buttonLabel: 'Report',
                fields: [FieldType.emailRequired, FieldType.textRequired],
                showAnimation: ShowAnimation.fade,
              )),
              child: const Text('Report a bug (override)'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ReMarka.send(
                const SendData(message: 'Sent without UI', tag: 'silent'),
              ),
              child: const Text('Send silently (no UI)'),
            ),
          ],
        ),
      ),
    );
  }
}
