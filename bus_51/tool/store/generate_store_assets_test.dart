// Play 스토어 등록용 이미지 생성 스크립트 (테스트 하네스를 렌더러로 사용).
//
// 실행: bus_51/ 에서
//   flutter test tool/store/generate_store_assets_test.dart
//
// 생성 (store_assets/):
//   feature_graphic.png             1024×500  그래픽 이미지
//   screenshot_1_list.png           1080×1920 내 버스 리스트 (카드마다 실시간 도착 시간)
//   screenshot_2_arrival.png        1080×1920 도착 정보 (도착 알림 켜짐)
//   screenshot_3_route_select.png   1080×1920 온보딩 노선 선택 (여러 노선 체크)
//   screenshot_4_route_confirm.png  1080×1920 온보딩 노선 확인
//   screenshot_5_welcome.png        1080×1920 온보딩 웰컴
//
// 스크린샷은 실제 화면 위젯을 샘플 데이터(가짜 저장소·API·알림 서비스)로 띄워 캡처한다.
// 실기기 없이도 만들 수 있고, UI가 바뀌면 다시 실행해 갱신한다.
// 정류장 지도 화면은 네이버 지도 SDK 가 있어야 그려지므로 여기서는 만들지 않는다.
// test/ 밖에 두어 `flutter test` 전체 실행에는 포함되지 않는다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_route_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:bus_51/tracking/bus_tracking_service.dart';
import 'package:bus_51/tracking/bus_tracking_target.dart';
import 'package:bus_51/viewmodel/route_setting_view_model.dart';
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

import '../../test/tracking/fake_bus_tracking_service.dart';
import '../icon/bus_icon_painter.dart';

const _outDir = 'store_assets';

// ----- 샘플 데이터 (수원 성균관대역 탑승, 51번 기준) -----

/// 온보딩에서 고른 정류장
const _station = BusStationModel(
  mobileNo: '04104',
  regionName: '수원',
  stationId: '226000064',
  stationName: '성균관대역',
  distance: '35',
  x: '126.9738',
  y: '37.2999',
);

/// 51번이 지나는 정류장 (노선 확인 화면 타임라인)
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

const _route3000 = BusRouteModel(
  regionName: '수원',
  routeDestId: '0',
  routeDestName: '강남역',
  routeId: '234000024',
  routeName: '3000',
  routeTypeCd: '11',
  routeTypeName: '직행좌석시내버스',
  staOrder: '12',
);

/// 노선 선택 화면 목록. 앞의 두 개(51·3000)를 체크한 상태로 캡처한다
const _routesAtStation = [
  _route51,
  _route3000,
  BusRouteModel(
    regionName: '수원',
    routeDestId: '0',
    routeDestName: '수원역',
    routeId: '200000103',
    routeName: '7-2',
    routeTypeCd: '13',
    routeTypeName: '일반형시내버스',
    staOrder: '9',
  ),
  BusRouteModel(
    regionName: '수원',
    routeDestId: '0',
    routeDestName: '병점',
    routeId: '200000068',
    routeName: '62-1',
    routeTypeCd: '13',
    routeTypeName: '일반형시내버스',
    staOrder: '7',
  ),
  BusRouteModel(
    regionName: '수원',
    routeDestId: '0',
    routeDestName: '수원역',
    routeId: '200000059',
    routeName: '92-1',
    routeTypeCd: '13',
    routeTypeName: '일반형시내버스',
    staOrder: '4',
  ),
  BusRouteModel(
    regionName: '수원',
    routeDestId: '0',
    routeDestName: '정자동',
    routeId: '200000301',
    routeName: '2-1',
    routeTypeCd: '30',
    routeTypeName: '마을버스',
    staOrder: '6',
  ),
];

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

/// 내 버스 리스트에 저장된 노선 (리스트 화면 순서)
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

/// 저장 노선별 도착 정보 (routeId → 응답). 카드마다 다르게 줘서 실제 화면처럼 보이게 한다:
/// 51 은 4분 뒤, 7770 은 12분 뒤, 5 는 "잠시 후 도착"
const _arrivals = <String, BusArrivalModel>{
  '208000017': BusArrivalModel(
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
    staOrder: '$_staOrder',
    plateNo1: '경기70아1234',
  ),
  '234000016': BusArrivalModel(
    predictTime1: '12',
    predictTime2: '23',
    predictTimeSec1: '765',
    predictTimeSec2: '1380',
    locationNo1: '6',
    locationNo2: '11',
    stationNm1: '수원종합운동장',
    stationNm2: '장안구청',
    flag: 'PASS',
    routeDestName: '사당역',
    routeId: '234000016',
    stationId: '226000070',
    staOrder: '3',
    plateNo1: '경기70아5678',
  ),
  '200000228': BusArrivalModel(
    predictTime1: '1',
    predictTime2: '9',
    predictTimeSec1: '40',
    predictTimeSec2: '540',
    locationNo1: '1',
    locationNo2: '4',
    stationNm1: '아주대삼거리',
    stationNm2: '우만주공아파트',
    flag: 'PASS',
    routeDestName: '수원역',
    routeId: '200000228',
    stationId: '226000031',
    staOrder: '8',
    plateNo1: '경기70아9012',
  ),
};

/// 상세 화면(51번)에서 도착 알림이 켜져 있는 상태
const _trackingTarget = BusTrackingTarget(
  stationId: 226000064,
  routeId: 208000017,
  staOrder: _staOrder,
  routeName: '51',
  plateNo: '경기70아1234',
  remainingSeconds: 252,
);

// ----- 가짜 데이터 계층 -----

class _FakeArrivalRepository implements BusArrivalRepository {
  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async =>
      _arrivals[routeId];

  /// 리스트 화면용: 그 정류장에 저장된 노선의 도착 정보만 돌려준다 (routeId·staOrder 로 카드에 매칭)
  @override
  Future<List<BusArrivalModel>> getArrivalsAtStation({required String stationId}) async => [
        for (final arrival in _arrivals.values)
          if (arrival.stationId == stationId) arrival,
      ];
}

class _FakeRouteRepository implements BusRouteRepository {
  @override
  Future<List<BusRouteModel>> getRoutesThroughStation({required String stationId}) async =>
      _routesAtStation;
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

// ----- 화면 구성 -----

/// 온보딩을 [step] 단계까지 진행한 상태의 InitProvider.
/// welcome: ① 웰컴 / select: ③ 노선 선택(51·3000 체크) / confirm: ④ 노선 확인
InitProvider _initProviderAt(String step) {
  final init = InitProvider();
  if (step == 'welcome') return init;
  init
    ..setSelectedStationModel(_station)
    ..nextAccountView() // ② 정류장 지도 (캡처하지 않음)
    ..nextAccountView() // ③ 노선 선택
    ..toggleSelectedRoute(_routesAtStation[0])
    ..toggleSelectedRoute(_routesAtStation[1]);
  if (step == 'confirm') init.nextAccountView(); // ④ 노선 확인
  return init;
}

/// InitSettingScreen 은 GetIt 에서 지도 뷰모델(GPS)까지 만들므로,
/// 여기서는 단계 상태와 노선 뷰모델만 직접 넣어 InitSettingView 를 띄운다
Widget _onboarding(String step) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _initProviderAt(step)),
        ChangeNotifierProvider(create: (_) => RouteSettingViewModel(_FakeRouteRepository())),
      ],
      child: const InitSettingView(),
    );

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
          builder: (_, state) => _onboarding(state.uri.queryParameters['step'] ?? 'welcome'),
        ),
      ],
    );

// ----- 캡처 -----

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
  late FakeBusTrackingService tracking;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    final storage = StorageService(prefs);
    for (final bus in _savedBuses) {
      await storage.addUserSaveModel(bus);
    }
    tracking = FakeBusTrackingService();
    GetIt.I.registerSingleton<StorageService>(storage);
    GetIt.I.registerSingleton<BusArrivalRepository>(_FakeArrivalRepository());
    GetIt.I.registerSingleton<BusRouteStationRepository>(_FakeRouteStationRepository());
    GetIt.I.registerSingleton<BusTrackingService>(tracking);
  });

  tearDown(() async => GetIt.I.reset());

  testWidgets('스토어 이미지 생성', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(_loadFonts);

    await _captureScreen(tester, BusListScreen.routeURL, 'screenshot_1_list.png');

    // 상세 화면은 51번 도착 알림을 켜 둔 상태로 (서비스가 이 버스를 추적 중이면 "알림 켜짐"으로 그린다)
    tracking.running = _trackingTarget;
    await _captureScreen(tester, '${BusMainScreen.routeURL}?idx=0', 'screenshot_2_arrival.png');
    tracking.running = null;

    await _captureScreen(tester, '${InitSettingScreen.routeURL}?step=select', 'screenshot_3_route_select.png');
    await _captureScreen(tester, '${InitSettingScreen.routeURL}?step=confirm', 'screenshot_4_route_confirm.png');
    await _captureScreen(tester, '${InitSettingScreen.routeURL}?step=welcome', 'screenshot_5_welcome.png');

    await tester.runAsync(_featureGraphic);

    expect(File('$_outDir/feature_graphic.png').existsSync(), isTrue);
  });
}
