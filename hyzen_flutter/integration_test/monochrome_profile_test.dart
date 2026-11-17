import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hyzen_pharmd/main_account_review.dart' as fixture;
import 'package:hyzen_pharmd/app/app.dart';
import 'package:hyzen_pharmd/app/router.dart';
import 'package:hyzen_pharmd/app/providers.dart';
import 'package:hyzen_pharmd/features/pdf_studio/data/studio_pdf_engine.dart';
import 'package:hyzen_pharmd/features/viewer/offline_pdf.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native reference profile: home, retained tabs, scroll, routes and PDF',
    (tester) async {
      await fixture.main();
      await tester.pumpAndSettle();
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
            await tester.pumpAndSettle();
          }
        }
      }, reportKey: 'tab_navigation');
      router.go('/home');
      await tester.pumpAndSettle();
      await binding.watchPerformance(() async {
        for (var i = 0; i < 5; i++) {
          await tester.fling(
            find.byType(CustomScrollView).first,
            const Offset(0, -450),
            900,
          );
          await tester.pumpAndSettle();
          await tester.fling(
            find.byType(CustomScrollView).first,
            const Offset(0, 450),
            900,
          );
          await tester.pumpAndSettle();
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
          await tester.pumpAndSettle();
          router.pop();
          await tester.pumpAndSettle();
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
        await tester.pumpAndSettle();
        final nav = Navigator.of(tester.element(find.byType(Scaffold).last));
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Profile PDF')),
              body: OfflinePdf(path: path, onOpened: () => pdfOpened = true),
            ),
          ),
        );
        await tester.pumpAndSettle();
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
        await tester.pumpAndSettle();
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
          await tester.pumpAndSettle();
          await binding.takeScreenshot('${mode.name}-${path.substring(1)}');
        }
      }
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
