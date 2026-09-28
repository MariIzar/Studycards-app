import 'package:flutter_test/flutter_test.dart';
import 'package:study_cards/main.dart';

void main() {
  testWidgets('Smoke test do StudyCards', (WidgetTester tester) async {
    // Carrega o StudyCardsApp correto no teste
    await tester.pumpWidget(const StudyCardsApp());
  });
}
