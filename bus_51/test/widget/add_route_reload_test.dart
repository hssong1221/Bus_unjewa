import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/screen/init_setting_screen/favorite_setting_screen.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeBusRouteStationRepository implements BusRouteStationRepository {
  FakeBusRouteStationRepository(this.stations);

  final List<BusRouteStationModel> stations;

  @override
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) async => stations;
}

const route = BusRouteModel(
  regionName: '수원',
  routeDestId: '0',
  routeDestName: '수원역',
  routeId: '208000017',
  routeName: '51',
  routeTypeCd: '13',
  routeTypeName: '일반형시내버스',
  staOrder: '3',
);

BusRouteStationModel makeStation(int seq) => BusRouteStationModel(
      centerYn: 'N',
      districtCd: '2',
      mobileNo: '0$seq',
      regionName: '수원',
      stationId: '22600000$seq',
      stationName: '정류장$seq',
      x: '127.0',
      y: '37.2',
      adminName: '수원시',
      stationSeq: '$seq',
      turnSeq: '0',
      turnYn: 'N',
    );

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    GetIt.I.registerSingleton<StorageService>(StorageService(prefs));
    GetIt.I.registerSingleton<BusRouteStationRepository>(
      FakeBusRouteStationRepository([for (var i = 1; i <= 4; i++) makeStation(i)]),
    );
  });

  tearDown(() async => GetIt.I.reset());

  /// 리스트 → 노선 추가(push) → 저장 화면. 온보딩 중간 단계(지도 등)는 건너뛰고
  /// 실제 저장 화면(FavoriteSettingView)만 올린다
  GoRouter buildRouter() => GoRouter(
        initialLocation: BusListScreen.routeURL,
        routes: [
          GoRoute(
            name: BusListScreen.routeName,
            path: BusListScreen.routeURL,
            builder: (_, __) => const BusListScreen(),
          ),
          GoRoute(
            name: InitSettingScreen.routeName,
            path: InitSettingScreen.routeURL,
            builder: (_, __) => ChangeNotifierProvider(
              create: (_) => InitProvider(startIdx: InitProvider.stationStepIdx)
                ..setSelectedRouteModel(route),
              child: const FavoriteSettingView(),
            ),
          ),
        ],
      );

  testWidgets('리스트에서 노선 추가 후 저장하면 앱 재시작 없이 카드가 바로 보인다', (tester) async {
    await tester.pumpWidget(MaterialApp.router(theme: lightTheme, routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('첫 노선 추가하기'), findsOneWidget);
    await tester.tap(find.text('첫 노선 추가하기'));
    await tester.pumpAndSettle();

    expect(find.text('저장하고 시작하기'), findsOneWidget);
    await tester.tap(find.text('저장하고 시작하기'));
    await tester.pumpAndSettle();

    // 리스트로 돌아왔고, 방금 저장한 51번 카드가 보인다
    expect(find.byType(BusListScreen), findsOneWidget);
    expect(find.text('첫 노선 추가하기'), findsNothing);
    expect(find.text('51'), findsOneWidget);
    expect(find.textContaining('수원역 방면'), findsOneWidget);
  });
}
