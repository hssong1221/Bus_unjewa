// Play 스토어 등록용 이미지 생성 스크립트 (테스트 하네스를 렌더러로 사용).
//
// 실행: bus_51/ 에서
//   flutter test tool/store/generate_store_assets_test.dart
//
// 생성 (store_assets/):
//   feature_graphic.png       1024×500  그래픽 이미지
//   screenshot_1_list.png     1080×1920 내 버스 리스트
//   screenshot_2_arrival.png  1080×1920 도착 정보
//   screenshot_3_route.png    1080×1920 노선 확인
//
// 스크린샷은 실제 화면 위젯을 샘플 데이터(가짜 저장소/API)로 띄워 캡처한다.
// 실기기 없이도 만들 수 있고, UI가 바뀌면 다시 실행해 갱신한다.
// test/ 밖에 두어 `flutter test` 전체 실행에는 포함되지 않는다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../icon/bus_icon_painter.dart';

const _outDir = 'store_assets';

// ----- 샘플 데이터 (수원 51번, 성균관대역 탑승) -----

const _stationNames = [
  '수원여자대학교',
  '이목동',
  '밤밭청개구리공원',
  '율전성당',
  '성균관대역',
  '성균관대학교',
  '화서역',
  '화서문',
  '장안문',
  '팔달문',
  '수원역.AK플라자',
  '수원역',
];
const _staOrder = 5; // 성균관대역

const _route51 = BusRouteModel(
  regionName: '수원',
  routeDestId: '0',
  routeDestName: '수원역',
  routeId: '208000017',
  routeName: '51',
  routeTypeCd: '13',
  routeTypeName: '일반형시내버스',
  staOrder: '$_staOrder',
);

List<BusRouteStationModel> _routeStations() => [
      for (var i = 0; i < _stationNames.length; i++)
        BusRouteStationModel(
          centerYn: 'N',
          districtCd: '2',
          mobileNo: '0${4100 + i}',
          regionName: '수원',
          stationId: '2260000${60 + i}',
          stationName: _stationNames[i],
          x: '127.0',
          y: '37.2',
          adminName: '수원시',
          stationSeq: '${i + 1}',
          turnSeq: '0',
          turnYn: 'N',
        ),
    ];

const _arrival = BusArrivalModel(
  predictTime1: '4',
  predictTime2: '11',
  predictTimeSec1: '252',
  predictTimeSec2: '660',
  locationNo1: '2',
  locationNo2: '4',
  stationNm1: '밤밭청개구리공원',
  stationNm2: '수원여자대학교',
  flag: 'PASS', // 실시간 표시 조건
  routeDestName: '수원역',
  routeId: '208000017',
  stationId: '226000064',
);

const _savedBuses = [
  UserSaveModel(
    routeName: '51',
    stationId: 226000064,
    routeId: 208000017,
    staOrder: _staOrder,
    routeTypeCd: 13,
    stationName: '성균관대역',
    routeDestName: '수원역',
  ),
  UserSaveModel(
    routeName: '7770',
    stationId: 226000070,
    routeId: 234000016,
    staOrder: 3,
    routeTypeCd: 11,
    stationName: '수원역.AK플라자',
    routeDestName: '사당역',
  ),
  UserSaveModel(
    routeName: '5',
    stationId: 226000031,
    routeId: 200000228,
    staOrder: 8,
    routeTypeCd: 30,
    stationName: '아주대학교',
    routeDestName: '수원역',
  ),
];

class _FakeArrivalRepository implements BusArrivalRepository {
  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async =>
      _arrival;
}

class _FakeRouteStationRepository implements BusRouteStationRepository {
  @override
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) async =>
      _routeStations();
}

// ----- 폰트: 테스트 환경은 기본 폰트가 네모 글리프라 실제 폰트를 올린다 -----

Future<ByteData> _fileBytes(File f) async => ByteData.view(f.readAsBytesSync().buffer);

Future<void> _loadFonts() async {
  final pretendard = FontLoader('Pretendard');
  for (final f in Directory('assets/font').listSync().whereType<File>()) {
    if (f.uri.pathSegments.last.startsWith('Pretendard')) pretendard.addFont(_fileBytes(f));
  }
  await pretendard.load();

  // Material 아이콘 폰트는 Flutter SDK 캐시에 있다 (flutter_tester 위치에서 위로 탐색)
  Directory dir = File(Platform.resolvedExecutable).parent;
  File? icons;
  for (var i = 0; i < 8 && icons == null; i++) {
    for (final rel in ['artifacts/material_fonts', 'bin/cache/artifacts/material_fonts']) {
      final f = File('${dir.path}/$rel/MaterialIcons-Regular.otf');
      if (f.existsSync()) icons = f;
    }
    dir = dir.parent;
  }
  if (icons == null) {
    debugPrint('MaterialIcons-Regular.otf 을 찾지 못해 아이콘이 네모로 나옵니다');
    return;
  }
  await (FontLoader('MaterialIcons')..addFont(_fileBytes(icons))).load();
}

// ----- 캡처 -----

GoRouter _router(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          name: BusListScreen.routeName,
          path: BusListScreen.routeURL,
          builder: (_, __) => const BusListScreen(),
        ),
        GoRoute(
          name: BusMainScreen.routeName,
          path: BusMainScreen.routeURL,
          builder: (_, state) => BusMainScreen(
            userDataIdx: int.tryParse(state.uri.queryParameters['idx'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          name: InitSettingScreen.routeName,
          path: InitSettingScreen.routeURL,
          // 노선 추가 플로우의 마지막 단계(노선 확인)까지 진행한 상태로 온보딩 화면을 띄운다
          builder: (_, __) => ChangeNotifierProvider(
            create: (_) => InitProvider(startIdx: InitProvider.stationStepIdx)
              ..setSelectedRouteModel(_route51)
              ..nextAccountView()
              ..nextAccountView(),
            child: const InitSettingView(),
          ),
        ),
      ],
    );

Future<void> _writePng(ui.Image image, String name) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_outDir/$name')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// 화면을 띄우고 몇 프레임 진행한 뒤 1080×1920 PNG 로 저장
Future<void> _captureScreen(WidgetTester tester, String initialLocation, String name) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp.router(
        theme: lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _router(initialLocation),
      ),
    ),
  );
  // 카운트다운 타이머가 있어 pumpAndSettle 은 쓰지 않는다
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await _writePng(await boundary.toImage(pixelRatio: 3), name);
  });

  // 뷰모델 타이머 정리
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void _drawText(Canvas c, String text, double size, FontWeight weight, Color color, Offset at) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Pretendard'))
    ..pushStyle(ui.TextStyle(fontFamily: 'Pretendard', fontSize: size, fontWeight: weight, color: color))
    ..addText(text);
  final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 540));
  c.drawParagraph(paragraph, at);
}

/// 그래픽 이미지 1024×500: 왼쪽 아이콘 버스, 오른쪽 앱 이름
Future<void> _featureGraphic() async {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.drawRect(const Rect.fromLTWH(0, 0, 1024, 500), Paint()..color = iconMint);

  c.save();
  c.translate(0, -32);
  c.scale(0.5);
  drawBusIcon(c, withBackground: false);
  c.restore();

  _drawText(c, '버스 언제와', 84, FontWeight.w800, iconTeal, const Offset(470, 168));
  _drawText(c, '내 정류장 버스가 언제 오는지 바로', 32, FontWeight.w500, iconTire, const Offset(474, 286));

  await _writePng(await recorder.endRecording().toImage(1024, 500), 'feature_graphic.png');
}

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    final storage = StorageService(prefs);
    for (final bus in _savedBuses) {
      await storage.addUserSaveModel(bus);
    }
    GetIt.I.registerSingleton<StorageService>(storage);
    GetIt.I.registerSingleton<BusArrivalRepository>(_FakeArrivalRepository());
    GetIt.I.registerSingleton<BusRouteStationRepository>(_FakeRouteStationRepository());
  });

  tearDown(() async => GetIt.I.reset());

  testWidgets('스토어 이미지 생성', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(_loadFonts);

    await _captureScreen(tester, BusListScreen.routeURL, 'screenshot_1_list.png');
    await _captureScreen(tester, '${BusMainScreen.routeURL}?idx=0', 'screenshot_2_arrival.png');
    await _captureScreen(tester, InitSettingScreen.routeURL, 'screenshot_3_route.png');

    await tester.runAsync(_featureGraphic);

    expect(File('$_outDir/feature_graphic.png').existsSync(), isTrue);
  });
}
