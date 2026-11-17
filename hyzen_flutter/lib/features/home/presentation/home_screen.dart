import '../../../core/widgets/polish_ui.dart';
import '../../search/presentation/home_search.dart';
import '../../notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../academics/domain/models.dart';
import '../../academics/presentation/library_screens.dart';
import '../../academics/presentation/discovery_widgets.dart';
import '../../content/data/content_providers.dart';
import '../../downloads/data/downloads_controller.dart';
import '../../downloads/domain/download_record.dart';
import '../../shell/app_shell.dart';
import '../../study_progress/study_tracker.dart';
import '../../study_progress/campus_rank_screen.dart';
import '../data/recent_controller.dart';
import 'home_dashboard_top.dart';
import 'announcement_carousel.dart';

final homeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
String homeGreeting(DateTime time) {
  if (time.hour < 5 || time.hour >= 23) return 'Good night';
  if (time.hour < 12) return 'Good morning';
  if (time.hour < 16) return 'Good afternoon';
  return 'Good evening';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    final name =
        profile?.firstName ?? user?.displayName?.split(' ').first ?? 'there';
    final now = ref.watch(homeClockProvider)();
    final recent = ref.watch(recentProvider);
    final slides = ref.watch(announcementSlidesProvider);
    final downloads = ref.watch(downloadsProvider).values;
    final saved = downloads.where((r) => r.isAvailableOffline).length;
    final fresh = downloads
        .where((r) => r.isAvailableOffline && r.unopened)
        .length;
    final active = downloads
        .where((r) => r.status == DownloadStatus.downloading)
        .length;
    final downloadLabels = [
      if (saved > 0) '$saved Saved',
      if (fresh > 0) '$fresh New',
      if (active > 0) '$active Downloading',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return TabPage(
      title: 'Home',
      integratedHeader: true,
      header: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Tooltip(
                message: 'Profile & settings',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showAccountMenu(context),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: ProfileAvatar(
                        photoUrl: ProfileAvatar.resolveUrl(
                          profile?.photoUrl,
                          user?.photoURL,
                        ),
                        radius: 21,
                        fallback: name,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Hello, $name',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                    Text(
                      'Today ${now.day} ${months[now.month - 1]}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      key: const ValueKey('home-greeting'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: HColors.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HGlassButton(
                icon: 'icon-search',
                label: 'Search academic resources',
                onTap: () => context.go('/search', extra: true),
              ),
              HGlassButton(
                icon: 'icon-bell',
                label: 'Notifications',
                badge: ref
                    .watch(notificationsProvider)
                    .where((m) => m['read'] != true)
                    .length,
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
        ),
      ),
      onRefresh: () => refreshContent(ref, [
        'pw_settings',
        'pw_announcement',
        ...LibraryKind.values.map((k) => k.storageKey),
      ]),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.list(
            children: [
              HomeDashboardTop(year: profile?.professionalYear),
              const SizedBox(height: 16),
              const HomeSearch(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your plan',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('home-professional-badge'),
                    onPressed: () => context.push('/profile'),
                    child: Text(
                      profile?.professionalYear == null
                          ? 'Your year'
                          : 'Year ${profile!.professionalYear}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const _PlanCards(),
              const SizedBox(height: 14),
              const _StudyStats(),
              if (downloadLabels.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: [
                    for (final label in downloadLabels)
                      TextButton(
                        onPressed: () => context.go('/downloads'),
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              if (ref.watch(boolPrefProvider('pref_announcements')) &&
                  slides.isNotEmpty) ...[
                const SizedBox(height: 8),
                AnnouncementCarousel(slides: slides),
                const SizedBox(height: 8),
              ],
              if (recent.isNotEmpty) ...[
                SectionHeader(
                  title: 'Last lessons',
                  action: 'Clear',
                  onAction: () async {
                    if (await confirmDialog(
                      context,
                      title: 'Clear recent history?',
                      message:
                          'Only recently opened history will be cleared. Your files stay saved.',
                      confirm: 'Clear history',
                    )) {
                      await ref.read(recentProvider.notifier).clear();
                    }
                  },
                ),
                for (final item in recent.take(3))
                  FileTile(
                    file: item.file,
                    color: HColors.notes,
                    compact: true,
                  ),
              ],
              const SizedBox(height: 14),
              const SubjectDiscovery(compact: true),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCards extends StatelessWidget {
  const _PlanCards();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    Widget library() => HCard(
      color: HColors.apricot,
      radius: 24,
      shadow: false,
      semanticLabel: 'Study Library',
      onTap: () => context.go('/study'),
      onLongPress: () => showCardPreview(
        context,
        title: 'Study Library',
        description:
            'Explore professional-year notes, practice MCQs, past papers and guide books. Continue with your subjects at your own pace.',
        asset: 'action-notes',
        color: HColors.apricot,
        onOpen: () => context.go('/study'),
      ),
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: large ? 0 : 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PlanTag('Learn'),
            const SizedBox(height: 16),
            Text(
              'Study\nlibrary',
              style: t.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.22,
              ),
            ),
            const SizedBox(height: 8),
            Text('Notes, MCQs &\npast papers', style: t.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0x44FFFFFF),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: HColors.ink,
                    size: 17,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.north_east_rounded, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
    Widget office() => HCard(
      color: HColors.blue,
      radius: 24,
      shadow: false,
      onTap: () => context.go('/pdf-studio'),
      onLongPress: () => showCardPreview(
        context,
        title: 'Office Workspace',
        description:
            'Scan pages, import PDFs, crop and organise documents, annotate files and search recognised text.',
        asset: 'action-scan',
        color: HColors.blue,
        onOpen: () => context.go('/pdf-studio'),
      ),
      semanticLabel: 'Office Workspace',
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: large ? 0 : 122),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PlanTag('Create'),
            const SizedBox(height: 12),
            Text(
              'Office\nworkspace',
              style: t.textTheme.headlineSmall?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Scan · PDF',
                    style: t.textTheme.bodySmall?.copyWith(color: HColors.ink),
                  ),
                ),
                const SizedBox(width: 4),
                ExcludeSemantics(
                  child: Image.asset(
                    'assets/mascot/mascot_peeking.png',
                    width: 36,
                    height: 36,
                    cacheWidth: 108,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    Widget goals() => const _HomeQuickActions();
    if (large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          library(),
          const SizedBox(height: 10),
          office(),
          const SizedBox(height: 10),
          goals(),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Three independent 48dp targets must fit even on a 320dp phone.
        final rightWidth = (constraints.maxWidth * .45).clamp(156.0, 260.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: library()),
            const SizedBox(width: 10),
            SizedBox(
              width: rightWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [office(), const SizedBox(height: 10), goals()],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeQuickActions extends StatelessWidget {
  const _HomeQuickActions();
  @override
  Widget build(BuildContext context) => Material(
    color: HColors.pink,
    borderRadius: BorderRadius.circular(24),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final action in const [
            ('notes', 'Open notes', '/study/notes'),
            ('scan', 'Scan a document', '/create-pdf?source=camera'),
            ('downloads', 'Open downloads', '/downloads'),
          ])
            IconButton(
              key: ValueKey('home-action-${action.$1}'),
              tooltip: action.$2,
              onPressed: () => context.push(action.$3),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                maximumSize: const Size(48, 48),
                padding: const EdgeInsets.all(4),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              icon: Ink(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xB3FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/reference/action-${action.$1}.png',
                    cacheWidth: 120,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _PlanTag extends StatelessWidget {
  const _PlanTag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    ),
  );
}

class _StudyStats extends ConsumerWidget {
  const _StudyStats();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(studyTrackerProvider);
    final board = ref.watch(campusBoardProvider('week')).valueOrNull;
    final entries = [
      ('${p.currentStreak} days', 'Streak', '/study-streak', 'icon-streak'),
      (
        '${p.weekSeconds ~/ 3600}h ${(p.weekSeconds ~/ 60) % 60}m',
        'Time spent',
        '/study-progress',
        'icon-time',
      ),
      (
        board?.mine?.rank == null ? '—' : '#${board!.mine!.rank}',
        'Prof. Rank',
        '/campus-rank',
        'icon-rank',
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = MediaQuery.textScalerOf(context).scale(1) > 1.5 ? 1 : 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in entries)
              SizedBox(
                width: (c.maxWidth - (columns - 1) * 8) / columns,
                child: HCard(
                  radius: 22,
                  outlineColor: const Color(0xFFD2CADF),
                  shadow: false,
                  onTap: () => context.push(e.$3),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HAssetIcon(e.$4, size: 30),
                      const SizedBox(height: 6),
                      Text(
                        e.$1,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(e.$2, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});
  final String doc;
  @override
  Widget build(BuildContext context) {
    final title = doc == 'privacy' ? 'Privacy Policy' : 'Terms of Use';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HTopBar(title: title),
      body: HBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              HSpace.screen,
              80,
              HSpace.screen,
              HSpace.screen,
            ),
            child: PanelBlock(
              child: Text(
                'The official $title has not been supplied yet. The Hyzen owner must provide the final text before public release.\n\n'
                'Summary of current practice: your password is handled only by Firebase Authentication; your profile '
                '(name, mobile, city, professional year, institution) is stored in your private students record; '
                'offline files stay on your device.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
