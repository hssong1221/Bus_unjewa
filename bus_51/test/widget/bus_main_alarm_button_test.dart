import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 항상 같은 도착 정보를 돌려준다. 첫 번째 버스의 남은 초만 바꿔 가며 쓴다
class StubBusArrivalRepository implements BusArrivalRepository {
  StubBusArrivalRepository({required this.sec1});

  final String sec1;

  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async =>
      BusArrivalModel(
        predictTime1: '10',
        predictTime2: '',
        predictTimeSec1: sec1,
        predictTimeSec2: '',
        locationNo1: '5',
        locationNo2: '',
        stationNm1: '앞정류장',
        stationNm2: '',
        flag: 'PASS',
        routeDestName: '수원역',
        routeId: '1',
        stationId: '1',
        staOrder: '3',
      );

  @override
  Future<List<BusArrivalModel>> getArrivalsAtStation({required String stationId}) => throw UnimplementedError();
}

/// 전체 노선 타임라인은 이 테스트의 관심사가 아니다
class EmptyBusRouteStationRepository implements BusRouteStationRepository {
  @override
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) async => const [];
}

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    final storage = StorageService(prefs);
    await storage.addUserSaveModel(const UserSaveModel(
      stationId: 1,
      stationName: '정류장',
      routeId: 1,
      routeName: '51',
      routeTypeCd: 13,
      routeDestName: '수원역',
      staOrder: 3,
    ));
    GetIt.I.registerSingleton<StorageService>(storage);
    GetIt.I.registerSingleton<BusRouteStationRepository>(EmptyBusRouteStationRepository());
  });

  tearDown(() async => GetIt.I.reset());

  /// 남은 초를 정해 메인 화면을 띄운다.
  /// 카운트다운이 매초 프레임을 잡아 pumpAndSettle 이 끝나지 않으므로 프레임을 직접 그린다
  Future<void> pumpMain(WidgetTester tester, {required String sec1}) async {
    // 좁은 폰(360dp) 폭에서 두 버튼이 한 줄에 넘치지 않는지도 같이 본다 (넘치면 RenderFlex 오류로 실패)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    GetIt.I.registerSingleton<BusArrivalRepository>(StubBusArrivalRepository(sec1: sec1));
    await tester.pumpWidget(MaterialApp.router(
      theme: lightTheme,
      routerConfig: GoRouter(
        initialLocation: '${BusMainScreen.routeURL}?idx=0',
        routes: [
          GoRoute(
            name: BusMainScreen.routeName,
            path: BusMainScreen.routeURL,
            builder: (_, state) => BusMainScreen(userDataIdx: int.parse(state.uri.queryParameters['idx']!)),
          ),
        ],
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  /// 도착 알림 버튼 (라벨이 켜짐/꺼짐에 따라 바뀐다). FilledButton.icon 은 하위 타입이라 bySubtype 으로 찾는다
  FilledButton alarmButton(WidgetTester tester, String label) => tester.widget<FilledButton>(
        find.ancestor(of: find.text(label), matching: find.bySubtype<FilledButton>()),
      );

  testWidgets('꺼진 상태: "도착 알림" tonal 버튼이 "전체 노선 보기" 옆에 있다', (tester) async {
    await pumpMain(tester, sec1: '600');

    expect(find.text('도착 알림'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('전체 노선 보기'), findsOneWidget);
    expect(alarmButton(tester, '도착 알림').enabled, isTrue);
    // 설명 문구는 화면에 고정으로 두지 않는다
    expect(find.textContaining('알려드려요'), findsNothing);
  });

  testWidgets('누르면 "알림 켜짐"으로 바뀌고 토스트가 뜬다. 다시 누르면 꺼지고 끔 토스트', (tester) async {
    await pumpMain(tester, sec1: '600');

    await tester.tap(find.text('도착 알림'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('알림 켜짐'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    expect(find.text('도착 알림'), findsNothing);
    expect(find.text('도착 10·5·3·1분 전에 알려드려요'), findsOneWidget);

    // 토스트(2초)가 사라진 뒤 다시 누른다. 시간을 넘긴 프레임에서 사라지는 애니메이션이 시작되므로 한 프레임 더 그린다
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('도착 10·5·3·1분 전에 알려드려요'), findsNothing);

    await tester.tap(find.text('알림 켜짐'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('도착 알림'), findsOneWidget);
    expect(find.text('도착 알림을 껐어요'), findsOneWidget);
  });

  testWidgets('남은 시간이 1분 미만이면 버튼이 비활성화되고 눌러도 아무 일도 없다', (tester) async {
    await pumpMain(tester, sec1: '30');

    expect(alarmButton(tester, '도착 알림').enabled, isFalse);

    await tester.tap(find.text('도착 알림'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('도착 알림'), findsOneWidget);
    expect(find.textContaining('알려드려요'), findsNothing);
  });
}
