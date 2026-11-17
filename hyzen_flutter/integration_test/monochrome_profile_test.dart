import 'dart:async';
import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/app/app.dart';
import 'package:hyzen_pharmd/app/providers.dart';
import 'package:hyzen_pharmd/app/router.dart';
import 'package:hyzen_pharmd/core/widgets/polish_ui.dart';
import 'package:hyzen_pharmd/features/pdf_studio/data/studio_pdf_engine.dart';
import 'package:hyzen_pharmd/features/viewer/offline_pdf.dart';
import 'package:hyzen_pharmd/main_account_review.dart' as fixture;
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Let the engine schedule its own animation frames. A fixed number of
  // awaited pumps ties real elapsed time to emulator rendering throughput.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  testWidgets(
    'native reference profile: home, retained tabs, scroll, routes and PDF',
    (tester) async {
      _checkpoint('starting fixture');
      await fixture.main().timeout(const Duration(seconds: 20));
      await _waitFor(() => find.byType(HyzenApp).evaluate().isNotEmpty, 'app');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HyzenApp)),
      );
      final router = container.read(routerProvider);
      final ambient = container.read(
        boolPrefProvider('pref_ambient_motion').notifier,
      );
      ambient.set(true);
      tester.platformDispatcher.clearTextScaleFactorTestValue();

      router.go('/home');
      final hero = find.byKey(const ValueKey('home-hero-art'));
      await _waitFor(() => hero.evaluate().isNotEmpty, 'Home hero');
      final art = tester.widget<HSoftArt>(find.byType(HSoftArt));
      expect(art.loop && art.enabled, isTrue);
      await _sample(binding, 'ambient_hero', () async {
        final initial = tester.getCenter(hero);
        var moved = false;
        final elapsed = Stopwatch()..start();
        while (elapsed.elapsed < const Duration(seconds: 6)) {
          await _wait(const Duration(milliseconds: 250));
          moved |= (tester.getCenter(hero) - initial).distance > 0.25;
        }
        expect(
          moved,
          isTrue,
          reason: 'Home artwork must animate in the sample',
        );
      });

      await _sample(binding, 'tab_navigation', () async {
        for (var i = 0; i < 5; i++) {
          for (final path in [
            '/home',
            '/study',
            '/pdf-studio',
            '/downloads',
            '/shop',
          ]) {
            router.go(path);
            await _wait();
          }
        }
      });

      router.go('/home');
      await _wait();
      await _sample(binding, 'home_scroll', () async {
        for (var i = 0; i < 5; i++) {
          for (final dy in [-450.0, 450.0]) {
            final scroll = find.byType(CustomScrollView).first;
            await tester.fling(scroll, Offset(0, dy), 900);
            await _wait(const Duration(milliseconds: 650));
          }
        }
      });

      await _sample(binding, 'route_transitions', () async {
        for (final path in [
          '/study-goals',
          '/study-streak',
          '/campus-rank',
          '/profile',
          '/settings',
        ]) {
          unawaited(router.push<void>(path));
          await _wait();
          router.pop();
          await _wait();
        }
      });

      _checkpoint('creating PDF fixture');
      final path = await StudioPdfEngine.textToPdf(
        'Pharm D profile fixture\nPharmacology revision',
      ).timeout(const Duration(seconds: 15));
      expect(
        await StudioPdfEngine.pageCount(
          path,
        ).timeout(const Duration(seconds: 10)),
        1,
      );
      await _sample(binding, 'pdf_open', () async {
        router.go('/pdf-studio');
        await _wait();
        final nav = Navigator.of(tester.element(find.byType(Scaffold).last));
        var pdfOpened = false;
        unawaited(
          nav.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Profile PDF')),
                body: OfflinePdf(path: path, onOpened: () => pdfOpened = true),
              ),
            ),
          ),
        );
        await _waitFor(() => pdfOpened, 'first rendered PDF frame');
        nav.pop();
        await _wait();
      });

      // Readback runs after profiling with the decorative ticker idle.
      _checkpoint('preparing screenshot surface');
      ambient.set(false);
      await _wait();
      await binding.convertFlutterSurfaceToImage().timeout(
        const Duration(seconds: 15),
      );
      container.read(themeModeProvider.notifier).set(ThemeMode.light);
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
        await _wait();
        final name = 'light-${path.substring(1)}';
        _checkpoint('capturing $name');
        final bytes = await binding
            .takeScreenshot(name)
            .timeout(const Duration(seconds: 15));
        expect(bytes, isNotEmpty, reason: 'Screenshot $name must contain data');
      }
      expect(tester.takeException(), isNull);
      binding.reportData!['profile_complete'] = true;
      _checkpoint('complete');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

void _checkpoint(String message) => debugPrint('Native profile: $message');

Future<void> _wait([Duration duration = const Duration(milliseconds: 380)]) =>
    Future<void>.delayed(duration);

Future<void> _waitFor(bool Function() predicate, String description) async {
  final elapsed = Stopwatch()..start();
  while (!predicate()) {
    if (elapsed.elapsed >= const Duration(seconds: 12)) {
      throw TimeoutException('Waiting for $description');
    }
    await _wait(const Duration(milliseconds: 100));
  }
}

Future<void> _sample(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
  Future<void> Function() action,
) async {
  // Engine timings arrive in batches. Register a fresh listener for each run
  // and leave bounded time for the final batch without forcing extra frames.
  await _wait(const Duration(milliseconds: 1100));
  _checkpoint('sampling $name');
  final frames = <FrameTiming>[];
  final collect = frames.addAll;
  binding.addTimingsCallback(collect);
  try {
    await action().timeout(const Duration(seconds: 25));
    await _wait(const Duration(milliseconds: 1200));
  } finally {
    binding.removeTimingsCallback(collect);
  }
  expect(frames, isNotEmpty, reason: '$name must capture engine timings');
  binding.reportData ??= {};
  binding.reportData![name] = FrameTimingSummarizer(frames).summary;
  _checkpoint('$name recorded ${frames.length} frames');
}
