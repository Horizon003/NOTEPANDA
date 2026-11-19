import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hyzen_pharmd/app/providers.dart';
import 'package:hyzen_pharmd/core/theme/app_theme.dart';
import 'package:hyzen_pharmd/features/study_progress/campus_rank_screen.dart';

class SetupController extends CampusController {
  SetupController(SharedPreferences prefs)
    : super(null, prefs, 'setup-test', 'week') {
    state = const AsyncData(
      CampusBoard(
        'Choose your name.',
        [],
        null,
        null,
        academicYear: 2,
        setupRequired: true,
        verificationRequired: true,
        statusCode: 'setup',
      ),
    );
  }
  String? savedName;
  bool? hidden;
  @override
  Future<void> privacy(String alias, bool optOut, {int? academicYear}) async {
    savedName = alias;
    hidden = optOut;
    state = AsyncData(
      CampusBoard(
        'Your year is under review.',
        [],
        null,
        null,
        academicYear: 2,
        alias: alias,
        optOut: optOut,
        verificationRequired: true,
        statusCode: 'review',
      ),
    );
  }

  @override
  Future<void> load({bool more = false}) async {}
}

void main() {
  testWidgets(
    'first visit prompts for name and explicit visibility; pending year still saves',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      late SetupController controller;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            campusBoardProvider.overrideWith(
              (ref, period) => controller = SetupController(prefs),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const CampusRankScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Make your place in the league'), findsOneWidget);
      expect(find.textContaining('Firebase'), findsNothing);
      final confirm = find.widgetWithText(FilledButton, 'Confirm choices');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(find.byType(TextFormField), 'Haris');
      await tester.tap(find.text('Keep it private'));
      await tester.pump();
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(controller.savedName, 'Haris');
      expect(controller.hidden, true);
      expect(find.text('Your year is under review'), findsOneWidget);
      expect(find.textContaining('unavailable. No privacy'), findsNothing);
    },
  );
}
