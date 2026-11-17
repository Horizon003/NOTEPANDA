import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/content/data/content_providers.dart';
import '../theme/tokens.dart';
import 'navigation_preferences.dart';

enum DockDestination {
  home('Home', '/home', 0, Icons.home_outlined),
  study('Study', '/study', 1, Icons.grid_view_rounded),
  office('Office Workspace', '/pdf-studio', 3, Icons.description_outlined),
  shop('Shop', '/shop', 6, Icons.shopping_bag_outlined),
  downloads('Downloads', '/downloads', 4, Icons.file_download_outlined);

  const DockDestination(this.label, this.route, this.branchIndex, this.icon);
  final String label, route;
  final int branchIndex;
  final IconData icon;
  bool matches(String path) => path == route || path.startsWith('$route/');
}

/// Compact pill dock from the reference. Navigation stacks stay in the shell.
class MainDock extends ConsumerWidget {
  const MainDock({super.key, required this.path, required this.onSelected});
  final String path;
  final ValueChanged<DockDestination> onSelected;
  static double height(BuildContext context) => 60;
  static double contentInset(BuildContext context) =>
      height(context) +
      16 +
      math.max(10, MediaQuery.viewPaddingOf(context).bottom);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    final size = ref.watch(dockSizeProvider).clamp(.9, 1.05);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Material(
            key: const ValueKey('main-dock'),
            color: const Color(0xFFF0F0F2),
            elevation: 0,
            shape: const StadiumBorder(
              side: BorderSide(color: Color(0xFFE5E5E8)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: LayoutBuilder(
                builder: (context, c) {
                  final selected = DockDestination.values
                      .where((d) => d.matches(path))
                      .firstOrNull;
                  final iconOnly =
                      MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
                      c.maxWidth < 278;
                  final activeWidth = iconOnly || selected == null
                      ? c.maxWidth / 5
                      : (c.maxWidth - 192).clamp(48.0, 124.0);
                  final restWidth = (c.maxWidth - activeWidth) / 4;
                  return Row(
                    children: [
                      for (final d in DockDestination.values)
                        AnimatedContainer(
                          duration: HMotion.duration(context),
                          curve: HMotion.curve,
                          width: selected == null || iconOnly
                              ? c.maxWidth / 5
                              : (d == selected ? activeWidth : restWidth),
                          height: 48,
                          child: Tooltip(
                            message: d.label,
                            excludeFromSemantics: true,
                            child: Semantics(
                              key: ValueKey('dock-${d.name}'),
                              button: true,
                              selected: d == selected,
                              label: d.label,
                              onTap: () => onSelected(d),
                              child: ExcludeSemantics(
                                child: _DockButton(
                                  destination: d,
                                  selected: d == selected,
                                  iconOnly: iconOnly,
                                  iconSize: 19 * size,
                                  onTap: () => onSelected(d),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animate only the compact control, never a retained tab's document/content.
class _DockButton extends StatefulWidget {
  const _DockButton({
    required this.destination,
    required this.selected,
    required this.iconOnly,
    required this.iconSize,
    required this.onTap,
  });
  final DockDestination destination;
  final bool selected, iconOnly;
  final double iconSize;
  final VoidCallback onTap;

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: widget.onTap,
    onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
    customBorder: const StadiumBorder(),
    child: AnimatedScale(
      scale: _pressed && !MediaQuery.disableAnimationsOf(context) ? .97 : 1,
      duration: HMotion.duration(context),
      curve: HMotion.curve,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.selected ? 1 : 0),
        duration: HMotion.duration(context, const Duration(milliseconds: 200)),
        curve: HMotion.curve,
        builder: (context, selection, _) {
          final foreground = Color.lerp(HColors.ink, Colors.white, selection)!;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Color.lerp(Colors.white, HColors.ink, selection),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.iconOnly ? 0 : 10 * selection,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.destination.icon,
                  size: widget.iconSize,
                  color: foreground,
                ),
                if (!widget.iconOnly)
                  Flexible(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: selection,
                        child: Opacity(
                          opacity: selection,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text(
                              widget.destination == DockDestination.office
                                  ? 'Office'
                                  : widget.destination.label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: foreground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

Future<void> showStudyMenu(BuildContext context) {
  final router = GoRouter.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close study menu',
    barrierColor: Colors.black12,
    transitionDuration: HMotion.duration(context),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .05),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    pageBuilder: (c, _, __) => Consumer(
      builder: (c, ref, _) {
        final settings = ref.watch(siteSettingsProvider);
        final t = Theme.of(c);
        var expanded = true;
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: (MediaQuery.sizeOf(c).width * .16).clamp(12, 150),
                bottom: 92,
                right: 16,
              ),
              child: StatefulBuilder(
                builder: (c, setState) => SizedBox(
                  width: 216,
                  child: Material(
                    color: t.colorScheme.surface,
                    elevation: 10,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(
                          180,
                          MediaQuery.sizeOf(c).height - 150,
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (settings.sectionEnabled('notes')) ...[
                              _StudyRow(
                                'Notes',
                                Icons.menu_book_rounded,
                                Theme.of(context).colorScheme.primary,
                                () => setState(() => expanded = !expanded),
                                expanded: expanded,
                              ),
                              if (expanded)
                                Container(
                                  margin: const EdgeInsets.only(
                                    left: 25,
                                    bottom: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: t.colorScheme.primary.withValues(
                                      alpha: .07,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      _StudyRow(
                                        'Regular',
                                        Icons.description_outlined,
                                        t.colorScheme.onSurfaceVariant,
                                        () {
                                          Navigator.pop(c);
                                          router.go('/study/notes');
                                        },
                                        small: true,
                                      ),
                                      if (settings.sectionEnabled('special'))
                                        _StudyRow(
                                          'Special',
                                          Icons.auto_stories_outlined,
                                          t.colorScheme.onSurfaceVariant,
                                          () {
                                            Navigator.pop(c);
                                            router.go('/study/special');
                                          },
                                          small: true,
                                        ),
                                    ],
                                  ),
                                ),
                              const Divider(height: 9),
                            ],
                            if (settings.sectionEnabled('mcqs'))
                              _StudyRow(
                                'MCQs',
                                Icons.quiz_rounded,
                                HColors.mcqs,
                                () {
                                  Navigator.pop(c);
                                  router.go('/study/mcqs');
                                },
                              ),
                            if (settings.sectionEnabled('papers'))
                              _StudyRow(
                                'PPS',
                                Icons.assignment_rounded,
                                HColors.special,
                                () {
                                  Navigator.pop(c);
                                  router.go('/study/papers');
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _StudyRow extends StatelessWidget {
  const _StudyRow(
    this.label,
    this.icon,
    this.color,
    this.onTap, {
    this.small = false,
    this.expanded,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool small;
  final bool? expanded;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: small ? 8 : 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: small ? 20 : 23),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: small ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!small)
            Icon(
              expanded == true
                  ? Icons.expand_more_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
            ),
        ],
      ),
    ),
  );
}
