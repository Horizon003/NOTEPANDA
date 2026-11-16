import 'package:flutter/material.dart';

/// PHARM D WITH HYZEN design tokens.
///
/// Warm nude surfaces and charcoal ink, refined from the owner’s mobile references.
/// Semantic status colors and document annotation ink remain meaningful.
class HColors {
  HColors._();
  // Brand
  static const primary = Color(0xFF43372F);
  static const primaryDeep = Color(0xFF292522);
  static const primarySoft = Color(0xFFEFE2D3);
  static const slate = Color(0xFF352E29);
  static const slateDeep = Color(0xFF211C18);
  static const teal = Color(0xFF6D6256);
  static const mint = Color(0xFFD7C3AE);
  static const onPrimary = Colors.white;

  // Ink
  static const ink = Color(0xFF292522);
  static const ink2 = Color(0xFF62584F);
  static const ink3 = Color(0xFF786C60);

  // Surfaces (light)
  static const background = Color(0xFFFBF7F2);
  static const surface = Color(0xFFFFFCF8);
  static const surfaceAlt = Color(0xFFF0E7DC);
  static const outline = Color(0xFFE0D5C9);
  static const outlineStrong = Color(0xFFB4A492);

  // Warm nude accents: confined to content surfaces, never text on pale ink.
  static const nudePeach = Color(0xFFE8CDBB);
  static const nudeSand = Color(0xFFE9DECF);
  static const darkPeach = Color(0xFF49382D);

  // Status
  static const success = Color(0xFF15885A);
  static const warning = Color(0xFFB7791F);
  static const error = Color(0xFFC0392B);
  static const info = Color(0xFF6D6258);

  // Dark
  static const darkBackground = Color(0xFF171411);
  static const darkSurface = Color(0xFF231F1B);
  static const darkSurfaceAlt = Color(0xFF322B25);
  static const darkInk = Color(0xFFF7EFE5);
  static const darkInk2 = Color(0xFFC3B6A7);
  static const darkPrimary = Color(0xFFE7D2BC);

  /// Restrained module accents – used on small icon badges only.
  static const notes = Color(0xFF43372F);
  static const mcqs = Color(0xFF6D6258);
  static const papers = Color(0xFF6D6258);
  static const special = Color(0xFF6D6258);
  static const lectures = Color(0xFF6D6258);
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
