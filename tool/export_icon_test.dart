// Regenerates the launcher icon PNGs from VibeLogoPainter.
// Run:  flutter test tool/export_icon_test.dart
// Then: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_analyser/app/theme/app_colors.dart';
import 'package:ai_chat_analyser/app/widgets/vibe_logo.dart';

Future<void> _export(String path, {required bool background, double markScale = 1.0}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (background) {
    // Full-bleed square (stores reject transparent corners); launchers mask it.
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), Paint()..color = AppColors.background);
  }
  VibeLogoPainter(withBackground: background, markScale: markScale).paint(canvas, const Size(size, size));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('export launcher icons', () async {
    await _export('assets/icon/icon.png', background: true);
    // Adaptive icon foreground: transparent, mark kept inside the 66% safe zone.
    await _export('assets/icon/icon_foreground.png', background: false, markScale: 0.62);
    // Smaller in-app / store preview.
    await _export('assets/icon/icon_preview.png', background: true);
  });
}
