import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class HAssetIcon extends StatelessWidget {
  const HAssetIcon(this.name, {super.key, this.size = 26});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/reference/$name.png',
    width: size,
    height: size,
    cacheWidth: (size * 3).ceil(),
    excludeFromSemantics: true,
  );
}

/// Small clipped glass surface, supported by Flutter on Android and iOS.
class HGlassButton extends StatelessWidget {
  const HGlassButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });
  final String icon, label;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    excludeFromSemantics: true,
    child: Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        dimension: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .65),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xE6FFFFFF),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Badge(
                        isLabelVisible: badge > 0,
                        label: Text(badge > 9 ? '9+' : '$badge'),
                        child: HAssetIcon(icon, size: 19),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A finite, low-amplitude art entrance. No idle ticker or animated image decoding.
class HSoftArt extends StatefulWidget {
  const HSoftArt({super.key, required this.child});
  final Widget child;
  @override
  State<HSoftArt> createState() => _HSoftArtState();
}

class _HSoftArtState extends State<HSoftArt>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _started = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !TickerMode.of(context)) {
      _motion.stop();
      _motion.value = 1;
    } else if (!_started) {
      _started = true;
      _motion.forward();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _motion.stop();
      _motion.value = 1;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    child: widget.child,
    builder: (_, child) {
      final wave = math.sin(_motion.value * math.pi * 4) * (1 - _motion.value);
      return Transform.translate(
        offset: Offset(0, wave * 5),
        child: Transform.rotate(angle: wave * .025, child: child),
      );
    },
  );
}

Future<void> showCardPreview(
  BuildContext context, {
  required String title,
  required String description,
  required String asset,
  required Color color,
  required VoidCallback onOpen,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close card preview',
  barrierColor: Colors.black12,
  transitionDuration: HMotion.duration(context, HMotion.medium),
  transitionBuilder: (context, animation, _, child) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween(
        begin: .96,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
  pageBuilder: (dialog, _, __) => BackdropFilter(
    filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              key: const ValueKey('card-hold-preview'),
              color: color,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HAssetIcon(asset, size: 58),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Close preview',
                          onPressed: () => Navigator.pop(dialog),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: Theme.of(dialog).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: Theme.of(dialog).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dialog);
                        onOpen();
                      },
                      child: const Text('Open'),
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
