import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Pointer feedback complements Material focus, keyboard and ink behavior.
/// Only the transform is animated; the content is retained by AnimatedScale.
class HPressFeedback extends StatefulWidget {
  const HPressFeedback({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<HPressFeedback> createState() => _HPressFeedbackState();
}

class _HPressFeedbackState extends State<HPressFeedback> {
  bool _pressed = false;
  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => _set(true) : null,
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale:
          widget.enabled && _pressed && !MediaQuery.disableAnimationsOf(context)
          ? .98
          : 1,
      duration: HMotion.duration(context),
      curve: HMotion.curve,
      child: widget.child,
    ),
  );
}
