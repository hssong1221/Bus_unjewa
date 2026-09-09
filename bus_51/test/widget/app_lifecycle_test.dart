import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:bus_51/tracking/bus_tracking_service.dart';
import 'package:bus_51/viewmodel/bus_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../tracking/fake_bus_tracking_service.dart';

/// 호출 횟수만 센다 (리스트의 정류장 단위 조회와 상세의 노선 단위 조회 합산). 응답은 항상 10분 뒤 도착
class CountingBusArrivalRepository implements BusArrivalRepository {
  int callCount = 0;

  /// 저장된 카드(routeId 1 / staOrder 3)에 매칭되는 도착 정보
  static const _arrival = BusArrivalModel(
    predictTime1: '10',
    predictTime2: '',
    predictTimeSec1: '600',
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
  Future<List<BusArrivalModel>> getArrivalsAtStation({required String stationId}) async {
    callCount++;
    return const [_arrival];
  }

  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async {
    callCount++;
    return _arrival;
  }
}

/// 상세 화면의 전체 노선은 이 테스트의 관심사가 아니다
class EmptyBusRouteStationRepository implements BusRouteStationRepository {
  @override
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) async => const [];
}

void main() {
  late CountingBusArrivalRepository repo;

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
    repo = CountingBusArrivalRepository();
    GetIt.I.registerSingleton<StorageService>(storage);
    GetIt.I.registerSingleton<BusArrivalRepository>(repo);
    GetIt.I.registerSingleton<BusRouteStationRepository>(EmptyBusRouteStationRepository());
    GetIt.I.registerSingleton<BusTrackingService>(FakeBusTrackingService());
  });

  tearDown(() async => GetIt.I.reset());

  Widget buildApp() => MaterialApp.router(
        theme: lightTheme,
        routerConfig: GoRouter(
          initialLocation: BusListScreen.routeURL,
          routes: [
            GoRoute(
              name: BusListScreen.routeName,
              path: BusListScreen.routeURL,
              builder: (_, __) => const BusListScreen(),
            ),
            GoRoute(
              name: BusMainScreen.routeName,
              path: BusMainScreen.routeURL,
              builder: (_, state) => BusMainScreen(userDataIdx: int.parse(state.uri.queryParameters['idx']!)),
            ),
          ],
        ),
      );

  /// 실제 플랫폼이 보내는 것과 같은 경로(flutter/lifecycle 채널)로 상태를 바꾼다.
  /// 프레임워크가 중간 상태(inactive·hidden)를 채워 넣으므로 resumed ↔ paused 만 보내면 된다
  Future<void> setLifecycle(WidgetTester tester, AppLifecycleState state) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      const StringCodec().encodeMessage(state.toString()),
      (_) {},
    );
    await tester.pump();
  }

  /// 카운트다운이 매초 프레임을 잡아 pumpAndSettle 이 끝나지 않으므로 프레임을 직접 그린다
  Future<void> pumpList(WidgetTester tester) async {
    // 테스트 바인딩은 생명주기 상태가 null 로 시작해 paused 로 곧장 점프한다(hidden 을 거치지 않음).
    // 실제 앱은 화면이 뜰 때 이미 resumed 이므로 그 상태를 먼저 만들어 준다
    await setLifecycle(tester, AppLifecycleState.resumed);
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump();
  }

  testWidgets('리스트: 백그라운드에서는 2분 갱신이 멈추고, 돌아오면 갱신이 재개된다', (tester) async {
    await pumpList(tester);
    expect(repo.callCount, 1);

    await setLifecycle(tester, AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));
    expect(repo.callCount, 1);

    // VM 은 실제 시계를 쓰므로 위젯 테스트에서는 30초 유효기간 안 → 돌아와도 바로 받지 않고
    // 2분 갱신 타이머만 다시 돈다 (유효기간 자체는 VM 단위 테스트에서 검증)
    await setLifecycle(tester, AppLifecycleState.resumed);
    expect(repo.callCount, 1);
    await tester.pump(BusListViewModel.refreshInterval);
    expect(repo.callCount, 2);
  });

  testWidgets('상세가 떠 있을 때 돌아오면 상세만 다시 조회하고, 뒤에 있는 리스트는 조회하지 않는다', (tester) async {
    await pumpList(tester);
    expect(repo.callCount, 1);

    // 카드 탭 → 상세 진입 (상세가 1회 조회)
    await tester.tap(find.text('51'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(repo.callCount, 2);

    await setLifecycle(tester, AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));
    expect(repo.callCount, 2);

    await setLifecycle(tester, AppLifecycleState.resumed);
    expect(repo.callCount, 3);
  });
}
