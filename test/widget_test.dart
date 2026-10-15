import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_chat_analyser/app/app.dart';

void main() {
  testWidgets('App renders splash screen successfully and navigates to onboarding', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AiChatAnalyserApp());
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('haha ok'), findsOneWidget);

    // Advance past the splash delay and the fade route transition. Onboarding
    // has endless decorative animations, so pump fixed durations instead of settling.
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('01 / 03'), findsOneWidget);
  });
}
