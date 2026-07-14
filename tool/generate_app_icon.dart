// Cong cu sinh anh icon app tu BrandCrest (khien vang thuong hieu) — render
// ra PNG 1024x1024 de flutter_launcher_icons dung lam icon launcher.
//
// Chay: flutter test tool/generate_app_icon.dart
// Sinh: assets/icon/app_icon.png (nen toi + crest) va
//       assets/icon/app_icon_foreground.png (crest trong suot cho adaptive icon)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/widgets/brand_crest.dart';

Future<void> _capture(WidgetTester tester, Widget child, String path) async {
  final key = GlobalKey();
  tester.view.physicalSize = const Size(1024, 1024);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(RepaintBoundary(
    key: key,
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  ));
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    return image.toByteData(format: ui.ImageByteFormat.png);
  });
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('sinh icon app tu BrandCrest', (tester) async {
    Directory('assets/icon').createSync(recursive: true);

    // Icon day du: nen gradient xanh dam thuong hieu + crest lon.
    await _capture(
      tester,
      Container(
        width: 1024,
        height: 1024,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF0B1026)],
          ),
        ),
        child: const Center(child: BrandCrest(size: 640)),
      ),
      'assets/icon/app_icon.png',
    );

    // Lop foreground cho adaptive icon (Android): crest nho hon, nen trong
    // suot de vung an toan khong bi mask cat.
    await _capture(
      tester,
      const SizedBox(
        width: 1024,
        height: 1024,
        child: Center(child: BrandCrest(size: 540)),
      ),
      'assets/icon/app_icon_foreground.png',
    );

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
