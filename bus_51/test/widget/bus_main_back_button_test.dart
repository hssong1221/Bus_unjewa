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

/// 리스트(정류장 단위)와 상세(노선 단위) 조회 횟수를 따로 센다. 응답은 항상 10분 뒤 도착
class CountingBusArrivalRepository implements BusArrivalRepository {
  int stationCallCount = 0;
  int detailCallCount = 0;

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
    stationCallCount++;
    return const [_arrival];
  }

  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async {
    detailCallCount++;
    return _arrival;
  }
}

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
    await setLifecycle(tester, AppLifecycleState.resumed);
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump();
  }

  /// 리스트 → 카드 탭으로 상세 진입 (상세가 1회 조회)
  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.text('51'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(repo.detailCallCount, 1);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
  }

  testWidgets('상세 화면의 "<" 버튼으로 돌아오면 리스트의 2분 갱신이 다시 돈다', (tester) async {
    await pumpList(tester);
    expect(repo.stationCallCount, 1);
    await openDetail(tester);

    // 상세가 떠 있는 동안 리스트는 멈춰 있어야 한다
    await tester.pump(BusListViewModel.refreshInterval);
    expect(repo.stationCallCount, 1);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    expect(find.text('51'), findsOneWidget);

    // 돌아온 뒤 갱신 주기가 지나면 리스트가 다시 조회한다 (go 로 돌아오면 여기서 멈춘 채 남는다)
    await tester.pump(BusListViewModel.refreshInterval);
    expect(repo.stationCallCount, 2);
  });

  testWidgets('시스템 뒤로가기로 돌아와도 리스트의 2분 갱신이 다시 돈다', (tester) async {
    await pumpList(tester);
    await openDetail(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);

    await tester.pump(BusListViewModel.refreshInterval);
    expect(repo.stationCallCount, 2);
  });
}
