import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fish_guard/main.dart';
import 'package:fish_guard/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefDemoMode: true,
    });
  });

  testWidgets('FishGuard app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FishGuardApp());
    await tester.pump();
    expect(find.byType(FishGuardApp), findsOneWidget);

    // Unmount and dispose tree to cancel timers cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
