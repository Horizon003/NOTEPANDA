import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/rive_mascot.dart';
import '../../study_progress/study_tracker.dart';
import 'home_screen.dart' show homeClockProvider;
import '../../study_progress/campus_rank_screen.dart';

/// Content-driven study summary. The panda is the only decorative element.
class HomeDashboardTop extends ConsumerWidget {
  const HomeDashboardTop({super.key, required this.year});
  final int? year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(studyTrackerProvider);
    final board = ref.watch(campusBoardProvider('week')).valueOrNull;
    final t = Theme.of(context);
    final percent = (p.todaySeconds / (p.dailyGoal * 60)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HCard(
            shadow: false,
            onTap: () => context.push('/study-progress'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study Time', style: t.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  formatStudyTime(p.todaySeconds),
                  style: t.textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percent,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Daily Goal · ${p.dailyGoal ~/ 60}h ${p.dailyGoal % 60}m',
                      style: t.textTheme.bodyMedium,
                    ),
                    Text(
                      '${(percent * 100).round()}%',
                      style: t.textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < 340 &&
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final tiles = [
                _StatTile(
                  value: '${p.currentStreak} Days',
                  label: 'Study Streak',
                  onTap: () => context.push('/study-streak'),
                ),
                _StatTile(
                  value: board?.mine?.rank == null
                      ? '—'
                      : '#${board!.mine!.rank}${board.cached ? '*' : ''}',
                  label: board?.cached == true ? 'Saved rank' : 'Prof. Rank',
                  onTap: () => context.push('/campus-rank'),
                ),
                _StatTile(
                  value:
                      '${p.weekSeconds ~/ 3600}h ${(p.weekSeconds ~/ 60) % 60}m',
                  label: 'This Week',
                  onTap: () => context.push('/study-goals'),
                ),
              ];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tile in tiles)
                    SizedBox(
                      width: narrow
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 3,
                      child: tile,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _StudyWeek(now: ref.watch(homeClockProvider)(), days: p.days),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('home-continue-study'),
                      onPressed: () {
                        p.start();
                        context.go('/study');
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Continue to Study'),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      key: const ValueKey('home-professional-badge'),
                      onPressed: () => context.push('/profile'),
                      icon: const Icon(Icons.school_outlined, size: 18),
                      label: Text(
                        year == null
                            ? 'Your academic year'
                            : 'Pharm D · Year $year',
                      ),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                const HyzenRiveMascot(state: HyzenRiveState.studying, size: 64),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.onTap,
  });
  final String value, label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => HCard(
    onTap: onTap,
    shadow: false,
    padding: const EdgeInsets.all(HSpace.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

/// Reference-inspired week ribbon, driven by persisted study days.
/// A single target opens Goals; dates are an overview, not fake filter controls.
class _StudyWeek extends StatelessWidget {
  const _StudyWeek({required this.now, required this.days});
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
    return HCard(
      onTap: () => context.push('/study-goals'),
      semanticLabel: 'This week’s study activity. Open goals',
      shadow: false,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final date = monday.add(Duration(days: i));
                  final today = i + 1 == now.weekday;
                  final recorded = (days[studyDayKey(date)] ?? 0) >= 900;
                  final ink = today
                      ? t.colorScheme.onPrimary
                      : t.colorScheme.onSurface;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: today ? t.colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                          style: t.textTheme.bodySmall?.copyWith(color: ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: t.textTheme.labelLarge?.copyWith(color: ink),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: recorded ? ink : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
