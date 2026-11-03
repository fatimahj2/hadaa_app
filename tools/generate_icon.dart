// Generates the Hadaa app launcher icon as a 1024x1024 PNG.
//
// Run from the project root with:
//   dart run tools/generate_icon.dart
//
// It writes assets/icon/icon.png. After it runs, generate the actual
// launcher icons for Android with:
//   dart run flutter_launcher_icons
//
// Design: lavender background, white watch face circle, darker lavender
// heart in the middle. Matches the app's color palette and the project's
// "panic detection via heartbeat" theme.

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  // Make sure the output folder exists.
  Directory('assets/icon').createSync(recursive: true);

  const size = 1024;
  final image = img.Image(width: size, height: size);

  // ---- Background: solid lavender (#B89BE7) ----
  img.fill(image, color: img.ColorRgb8(0xB8, 0x9B, 0xE7));

  // ---- Watch face: white circle ----
  const cx = size ~/ 2;
  const cy = size ~/ 2;
  img.fillCircle(
    image,
    x: cx,
    y: cy,
    radius: 380,
    color: img.ColorRgb8(0xFF, 0xFF, 0xFF),
  );

  // Subtle inner lavender ring for depth
  img.fillCircle(
    image,
    x: cx,
    y: cy,
    radius: 360,
    color: img.ColorRgb8(0xFA, 0xF6, 0xFE),
  );

  // ---- Heart in lavender dark (#7C62B7) ----
  final heart = img.ColorRgb8(0x7C, 0x62, 0xB7);

  // Two lobes
  img.fillCircle(image, x: 440, y: 470, radius: 110, color: heart);
  img.fillCircle(image, x: 584, y: 470, radius: 110, color: heart);

  // Heart bottom point: a triangle drawn as horizontal lines so we
  // don't have to depend on the polygon API (which has had API churn
  // across image package versions).
  const topY = 510;
  const bottomY = 770;
  const halfWidthAtTop = 175;
  for (int y = topY; y <= bottomY; y++) {
    final t = (y - topY) / (bottomY - topY); // 0..1 down the triangle
    final halfWidth = (halfWidthAtTop * (1 - t)).round();
    if (halfWidth <= 0) continue;
    img.drawLine(
      image,
      x1: cx - halfWidth,
      y1: y,
      x2: cx + halfWidth,
      y2: y,
      color: heart,
      thickness: 1,
    );
  }

  // ---- Save ----
  final file = File('assets/icon/icon.png');
  file.writeAsBytesSync(img.encodePng(image));
  print('Wrote ${file.path} (${file.lengthSync()} bytes)');
}
