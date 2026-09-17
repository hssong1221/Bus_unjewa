import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 도착 정보는 이 테스트의 관심사가 아니라 전부 운행 없음으로 돌려준다
class NullBusArrivalRepository implements BusArrivalRepository {
  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async => null;

  @override
  Future<List<BusArrivalModel>> getArrivalsAtStation({required String stationId}) async => const [];
}

UserSaveModel makeUser(int stationId, String routeName) => UserSaveModel(
      stationId: stationId,
      stationName: '정류장$stationId',
      routeId: 1,
      routeName: routeName,
      routeTypeCd: 13,
      routeDestName: '수원역',
      staOrder: 3,
    );

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    storage = StorageService(prefs);
    GetIt.I.registerSingleton<StorageService>(storage);
    GetIt.I.registerSingleton<BusArrivalRepository>(NullBusArrivalRepository());
  });

  tearDown(() async => GetIt.I.reset());

  /// 리스트 화면 + 노선 추가 화면 자리(실제 온보딩 대신 빈 자리)
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
              name: InitSettingScreen.routeName,
              path: InitSettingScreen.routeURL,
              builder: (_, __) => const Scaffold(body: Text('add')),
            ),
          ],
        ),
      );

  final fab = find.byTooltip('노선 추가');

  testWidgets('노선이 있으면 우측 상단 편집 + 우측 하단 플로팅 추가 버튼, 하단 삭제 바는 없다', (tester) async {
    await storage.addUserSaveModel(makeUser(1, '51'));
    await storage.addUserSaveModel(makeUser(2, '7770'));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('편집'), findsOneWidget);
    expect(fab, findsOneWidget);
    expect(find.text('노선 삭제하기'), findsNothing);

    // 플로팅 버튼은 화면 우측 하단에 있다
    final size = tester.getSize(find.byType(MaterialApp));
    final fabCenter = tester.getCenter(fab);
    expect(fabCenter.dx, greaterThan(size.width * 0.75));
    expect(fabCenter.dy, greaterThan(size.height * 0.75));
  });

  testWidgets('편집을 누르면 선택 모드: 완료·삭제 바가 나오고 플로팅 버튼은 숨는다', (tester) async {
    await storage.addUserSaveModel(makeUser(1, '51'));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();

    expect(find.text('0개 선택됨'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('전체 삭제'), findsOneWidget);
    expect(find.text('선택 삭제 (0)'), findsOneWidget);
    expect(fab, findsNothing);
    expect(find.text('편집'), findsNothing);

    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(find.text('편집'), findsOneWidget);
    expect(fab, findsOneWidget);
  });

  testWidgets('빈 상태에는 편집도 플로팅 버튼도 없고 가운데 버튼만 있다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('첫 노선 추가하기'), findsOneWidget);
    expect(find.text('편집'), findsNothing);
    expect(fab, findsNothing);
  });

  testWidgets('플로팅 버튼을 누르면 노선 추가 화면으로 간다', (tester) async {
    await storage.addUserSaveModel(makeUser(1, '51'));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.text('add'), findsOneWidget);
  });
}
