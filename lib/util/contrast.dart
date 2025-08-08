import 'dart:ui';

// Returns asset path for better-contrasting logo (black or white) on given color.
// Prefers .webp assets for better web performance.
String logoForColor(Color background) {
  final lum = background.computeLuminance();
  // If background is dark (low luminance), prefer white logo; else black.
  // For Flame 1.30.x, Images has prefix 'assets/images',
  // so keys should be file names without the directory.
  return lum < 0.5
      ? 'logo_imweb_white.webp'
      : 'logo_imweb_black.webp';
}
