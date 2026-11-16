import 'package:flutter/material.dart';

/// PHARM D WITH HYZEN design tokens.
///
/// Graphite is the quiet product foundation. The selected palette is reserved
/// for primary actions, status, and small category accents.
class HColors {
  HColors._();
  // Brand
  static const primary = Color(0xFF111111);
  static const primaryDeep = Color(0xFF171717);
  static const primarySoft = Color(0xFFF2F2F2);
  static const slate = Color(0xFF242424);
  static const slateDeep = Color(0xFF101010);
  static const teal = Color(0xFF363636);
  static const mint = Color(0xFFD4D4D4);
  static const onPrimary = Colors.white;

  // Ink
  static const ink = Color(0xFF111111);
  static const ink2 = Color(0xFF616161);
  static const ink3 = Color(0xFF737373);

  // Surfaces (light)
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F5F5);
  static const outline = Color(0xFFE5E5E5);
  static const outlineStrong = Color(0xFFB3B3B3);

  // Status
  static const success = Color(0xFF15885A);
  static const warning = Color(0xFFB7791F);
  static const error = Color(0xFFC0392B);
  static const info = Color(0xFF525252);

  // Dark
  static const darkBackground = Colors.black;
  static const darkSurface = Color(0xFF181818);
  static const darkSurfaceAlt = Color(0xFF262626);
  static const darkInk = Color(0xFFFFFFFF);
  static const darkInk2 = Color(0xFFB8B8B8);
  static const darkPrimary = Color(0xFFF5F5F5);

  /// Restrained module accents – used on small icon badges only.
  static const notes = Color(0xFF111111);
  static const mcqs = Color(0xFF525252);
  static const papers = Color(0xFF525252);
  static const special = Color(0xFF525252);
  static const lectures = Color(0xFF525252);
}

/// Four-point rhythm; touch targets remain at least 48dp.
class HSpace {
  HSpace._();
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 20.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
  static const screen = 16.0;
}

class HRadius {
  HRadius._();
  static const sm = 10.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const pill = 999.0;
  static BorderRadius all(double r) => BorderRadius.circular(r);
}

class HMotion {
  HMotion._();
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 360);
  static const curve = Cubic(0.22, 1, 0.36, 1);
  static Duration duration(BuildContext context, [Duration value = fast]) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

class HShadow {
  HShadow._();
  static const soft = [
    BoxShadow(color: Color(0x0D1A1A1A), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const lifted = [
    BoxShadow(color: Color(0x161A1A1A), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const glow = [
    BoxShadow(color: Color(0x261C1C1E), blurRadius: 4, offset: Offset(0, 1)),
  ];
}

/// Quiet graphite hero gradient for selected surfaces only.
const hSlateGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF111111), Color(0xFF111111), Color(0xFF111111)],
  stops: [0, .62, 1],
);

/// Keep module colours legible on both opaque surface themes.
Color adaptiveAccent(BuildContext context, Color color) {
  final theme = Theme.of(context);
  if (color == HColors.primary ||
      color == HColors.primaryDeep ||
      color == HColors.notes) {
    return theme.colorScheme.primary;
  }
  if (color == HColors.primarySoft) return theme.colorScheme.primaryContainer;
  if (theme.brightness != Brightness.dark) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness(hsl.lightness < 0.68 ? 0.68 : hsl.lightness)
      .toColor();
}
