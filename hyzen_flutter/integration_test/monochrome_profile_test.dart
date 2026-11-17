import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hyzen_pharmd/main_account_review.dart' as fixture;
import 'package:hyzen_pharmd/app/app.dart';
import 'package:hyzen_pharmd/app/router.dart';
import 'package:hyzen_pharmd/app/providers.dart';
import 'package:hyzen_pharmd/core/widgets/polish_ui.dart';
import 'package:hyzen_pharmd/features/pdf_studio/data/studio_pdf_engine.dart';
import 'package:hyzen_pharmd/features/viewer/offline_pdf.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native reference profile: home, retained tabs, scroll, routes and PDF',
    (tester) async {
      await fixture.main();
      for (
        var attempt = 0;
        attempt < 30 && find.byType(HyzenApp).evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await pumpFrames(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HyzenApp)),
      );
      final router = container.read(routerProvider);
      await binding.watchPerformance(() async {
        for (var i = 0; i < 5; i++) {
          for (final path in [
            '/home',
            '/study',
            '/pdf-studio',
            '/downloads',
            '/shop',
          ]) {
            router.go(path);
            await pumpFrames(tester);
          }
        }
      }, reportKey: 'tab_navigation');
      router.go('/home');
      await pumpFrames(tester);
      final art = tester.widget<HSoftArt>(find.byType(HSoftArt));
      expect(art.loop && art.enabled, isTrue);
      await binding.watchPerformance(() async {
        await pumpFrames(tester, count: 375);
      }, reportKey: 'ambient_hero');
      await binding.watchPerformance(() async {
        for (var i = 0; i < 5; i++) {
          await tester.fling(
            find.byType(CustomScrollView).first,
            const Offset(0, -450),
            900,
          );
          await pumpFrames(tester, count: 60);
          await tester.fling(
            find.byType(CustomScrollView).first,
            const Offset(0, 450),
            900,
          );
          await pumpFrames(tester, count: 60);
        }
      }, reportKey: 'home_scroll');
      await binding.watchPerformance(() async {
        for (final path in [
          '/study-goals',
          '/study-streak',
          '/campus-rank',
          '/profile',
          '/settings',
        ]) {
          router.push(path);
          await pumpFrames(tester);
          router.pop();
          await pumpFrames(tester);
        }
      }, reportKey: 'route_transitions');
      final path = await StudioPdfEngine.textToPdf(
        'Pharm D profile fixture\nPharmacology revision',
      );
      expect(await StudioPdfEngine.pageCount(path), 1);
      var pdfOpened = false;
      await binding.watchPerformance(() async {
        final context = tester.element(find.byType(HyzenApp));
        router.go('/pdf-studio');
        await pumpFrames(tester);
        final nav = Navigator.of(tester.element(find.byType(Scaffold).last));
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Profile PDF')),
              body: OfflinePdf(path: path, onOpened: () => pdfOpened = true),
            ),
          ),
        );
        await pumpFrames(tester);
        for (var attempt = 0; attempt < 15 && !pdfOpened; attempt++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(context.mounted, isTrue);
        expect(
          pdfOpened,
          isTrue,
          reason: 'PDF renderer must report a successfully opened document',
        );
        nav.pop();
        await pumpFrames(tester);
      }, reportKey: 'pdf_open');
      // Captures happen outside performance windows: readback affects timings.
      await binding.convertFlutterSurfaceToImage();
      for (final mode in [ThemeMode.light]) {
        container.read(themeModeProvider.notifier).set(mode);
        for (final path in [
          '/home',
          '/study',
          '/pdf-studio',
          '/downloads',
          '/profile',
          '/settings',
          '/study-goals',
        ]) {
          router.go(path);
          await pumpFrames(tester);
          await binding.takeScreenshot('${mode.name}-${path.substring(1)}');
        }
      }
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Future<void> pumpFrames(WidgetTester tester, {int count = 24}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
