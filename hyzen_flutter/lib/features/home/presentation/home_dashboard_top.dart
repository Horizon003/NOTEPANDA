import 'package:flutter/material.dart';
import '../../../app/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/polish_ui.dart';
import '../../study_progress/study_tracker.dart';
import 'home_screen.dart' show homeClockProvider;

/// Reference composition; every number and progress bar uses persisted study data.
class HomeDashboardTop extends ConsumerWidget {
  const HomeDashboardTop({super.key, required this.year});
  final int? year;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(studyTrackerProvider);
    final t = Theme.of(context);
    final percent = (p.todaySeconds / (p.dailyGoal * 60)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final largeText =
                MediaQuery.textScalerOf(context).scale(25) > 25 * 1.3;
            final artWidth = (c.maxWidth * .45).clamp(118.0, 200.0);
            return Container(
              key: const ValueKey('home-focus-card'),
              decoration: BoxDecoration(
                gradient: hFocusGradient,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (!largeText)
                    Positioned(
                      right: -8,
                      top: -18,
                      bottom: 0,
                      child: ExcludeSemantics(
                        child: HSoftArt(
                          loop: true,
                          enabled: ref.watch(
                            boolPrefProvider('pref_ambient_motion'),
                          ),
                          child: Image.asset(
                            'assets/reference/focus-shapes.png',
                            key: const ValueKey('home-hero-art'),
                            width: artWidth,
                            fit: BoxFit.contain,
                            cacheWidth: 540,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      18,
                      largeText ? 18 : artWidth * .80,
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily\nchallenge',
                          style: t.textTheme.headlineMedium?.copyWith(
                            fontSize: c.maxWidth < 330 ? 25 : 29,
                            height: 1.12,
                            letterSpacing: -.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Study Time · ${formatStudyTime(p.todaySeconds)}',
                          style: t.textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: HColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Daily Goal · ${p.dailyGoal ~/ 60}h ${p.dailyGoal % 60}m',
                          style: t.textTheme.bodySmall?.copyWith(
                            color: HColors.ink,
                          ),
                        ),
                        const SizedBox(height: 9),
                        LinearProgressIndicator(
                          value: percent,
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            FilledButton(
                              key: const ValueKey('home-continue-study'),
                              onPressed: () {
                                p.start();
                                context.push('/study-progress');
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(36, 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 16),
                                  SizedBox(width: 4),
                                  Text('Start', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(
                              '${(percent * 100).round()}%',
                              style: t.textTheme.labelMedium?.copyWith(
                                color: HColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        StudyWeekRibbon(now: ref.watch(homeClockProvider)(), days: p.days),
      ],
    );
  }
}

/// The date ribbon reflects real activity. Its single action opens study goals.
class StudyWeekRibbon extends StatelessWidget {
  const StudyWeekRibbon({super.key, required this.now, required this.days});
  final DateTime now;
  final Map<String, int> days;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return Semantics(
      button: true,
      label: 'This week’s study activity. Open goals',
      child: InkWell(
        onTap: () => context.push('/study-goals'),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final date = monday.add(Duration(days: i));
                    final today = i + 1 == now.weekday;
                    final recorded = (days[studyDayKey(date)] ?? 0) >= 900;
                    final ink = today ? Colors.white : HColors.ink;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 1,
                      ),
                      decoration: BoxDecoration(
                        color: today
                            ? HColors.ink
                            : Colors.white.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: today ? HColors.ink : HColors.outlineStrong,
                          width: .8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: today || recorded
                                  ? ink
                                  : Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (MediaQuery.textScalerOf(context).scale(1) > 1.3
                                ? ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                                : [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ])[i],
                            maxLines: 1,
                            style: t.textTheme.labelSmall?.copyWith(
                              color: today ? Colors.white70 : HColors.ink2,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${date.day}',
                              maxLines: 1,
                              style: t.textTheme.titleMedium?.copyWith(
                                color: ink,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
