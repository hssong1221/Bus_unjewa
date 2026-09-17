// 런처 아이콘 원본 PNG 생성 스크립트 (테스트 하네스를 렌더러로 사용).
//
// 실행: bus_51/ 에서
//   flutter test tool/icon/generate_icon_test.dart
//
// 생성:
//   assets/icon/app_icon.png             1024px, 민트 배경 포함 (레거시 런처 아이콘)
//   assets/icon/app_icon_foreground.png  1024px, 투명 배경 (adaptive icon 전경)
//   store_assets/app_icon_512.png       512px, Play 콘솔 등록용
//
// 이후 `dart run flutter_launcher_icons` 로 mipmap 전체를 생성한다.
// test/ 밖에 두어 `flutter test` 전체 실행에는 포함되지 않는다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bus_icon_painter.dart';

Future<void> _savePng(String path, int size, {required bool withBackground}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(size / 1024);
  drawBusIcon(canvas, withBackground: withBackground);
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('런처 아이콘 원본 PNG 생성', (tester) async {
    await tester.runAsync(() async {
      await _savePng('assets/icon/app_icon.png', 1024, withBackground: true);
      await _savePng('assets/icon/app_icon_foreground.png', 1024, withBackground: false);
      await _savePng('store_assets/app_icon_512.png', 512, withBackground: true);
    });
    expect(File('assets/icon/app_icon.png').existsSync(), isTrue);
  });
}
