import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/core/theme/app_theme.dart';
import 'package:hyzen_pharmd/core/widgets/press_feedback.dart';
import 'package:hyzen_pharmd/core/widgets/common.dart';

void main() {
  test('both themes stay achromatic even with a legacy palette seed', () {
    for (final theme in [
      AppTheme.light(Colors.purple),
      AppTheme.dark(Colors.blue),
    ]) {
      final scheme = theme.colorScheme;
      for (final color in [
        theme.scaffoldBackgroundColor,
        scheme.surface,
        scheme.primary,
        scheme.onPrimary,
        scheme.onSurface,
        scheme.onSurfaceVariant,
        scheme.primaryContainer,
        scheme.surfaceContainer,
        scheme.outlineVariant,
      ]) {
        expect(color.r, color.g);
        expect(color.g, color.b);
      }
    }
    expect(AppTheme.light().scaffoldBackgroundColor, Colors.white);
    expect(AppTheme.dark().scaffoldBackgroundColor, Colors.black);
  });
  testWidgets('reduced motion retains taps and never scales pressed controls', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: HPressFeedback(
              child: FilledButton(
                onPressed: () => taps++,
                child: const Text('Study'),
              ),
            ),
          ),
        ),
      ),
    );
    final pointer = await tester.startGesture(
      tester.getCenter(find.text('Study')),
    );
    await tester.pump();
    final animation = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(animation.scale, 1);
    expect(animation.duration, Duration.zero);
    await pointer.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
  testWidgets(
    'long resource title and loading placeholder settle without idle tickers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              child: Column(
                children: const [
                  HMarqueeText(
                    'Pharmaceutical chemistry and medicinal compounds',
                  ),
                  Skeleton(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.byType(Tooltip), findsOneWidget);
    },
  );
}
