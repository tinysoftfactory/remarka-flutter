import 'package:flutter_test/flutter_test.dart';
import 'package:remarkaflutter/remarkaflutter.dart';

void main() {
  test('FieldType wire round-trips', () {
    for (final type in FieldType.values) {
      expect(FieldType.fromWire(type.wire), type);
    }
  });

  test('applyOverride merges only provided fields', () {
    const base = ReMarkaConfig(projectId: 'p', apiKey: 'k', tag: 'feedback');
    final merged = base.applyOverride(const ShowOverrideConfig(tag: 'bug'));

    expect(merged.tag, 'bug');
    // Untouched fields keep their base values.
    expect(merged.projectId, 'p');
    expect(merged.buttonLabel, base.buttonLabel);
  });

  test('FeedbackFieldValue serialises with wire type', () {
    const value =
        FeedbackFieldValue(type: FieldType.emailRequired, value: 'a@b.co');
    expect(value.toJson(), {'type': 'email-required', 'value': 'a@b.co'});
  });
}
