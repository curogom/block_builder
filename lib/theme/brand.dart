import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

class BrandPalette {
  BrandPalette._();

  static Color primary = const Color(0xFF00BFA6); // fallback

  static Future<void> loadFromAsset(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = Uint8List.view(data.buffer);
      final img = await decodeImageFromList(bytes);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;
      final pixels = byteData.buffer.asUint8List();
      // Sample every Nth pixel for speed
      const step = 16; // adjust sampling density
      int r = 0, g = 0, b = 0, count = 0;
      for (int i = 0; i < pixels.length; i += 4 * step) {
        final pr = pixels[i];
        final pg = pixels[i + 1];
        final pb = pixels[i + 2];
        r += pr;
        g += pg;
        b += pb;
        count++;
      }
      if (count > 0) {
        primary = Color.fromARGB(0xFF, (r ~/ count), (g ~/ count), (b ~/ count));
      }
    } catch (_) {
      // Keep fallback color on failure
    }
  }
}
