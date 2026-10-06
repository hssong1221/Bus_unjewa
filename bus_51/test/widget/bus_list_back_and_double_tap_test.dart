import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
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
    GetIt.I.registerSingleton<BusArrivalRepository>(NullBusArrivalRepository());
  });

  tearDown(() async => GetIt.I.reset());

  /// 리스트 화면 + 상세 화면 자리(실제 상세 대신 빈 자리)
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
              builder: (_, __) => const Scaffold(body: Text('상세')),
            ),
          ],
        ),
      );

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
  }

  /// 안드로이드 뒤로가기 (시스템이 보내는 popRoute 와 같은 경로)
  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('편집 모드에서 뒤로가기를 누르면 편집 모드만 끝나고 종료 경고는 뜨지 않는다', (tester) async {
    await pumpList(tester);

    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();
    expect(find.text('완료'), findsOneWidget);

    await pressBack(tester);
    expect(find.text('편집'), findsOneWidget);
    expect(find.text('한번 더 누르면 앱이 종료됩니다'), findsNothing);

    // 편집 모드가 아니면 기존대로 종료 경고
    await pressBack(tester);
    expect(find.text('한번 더 누르면 앱이 종료됩니다'), findsOneWidget);
  });

  testWidgets('카드를 빠르게 두 번 눌러도 상세는 한 겹만 열린다', (tester) async {
    await pumpList(tester);

    await tester.tap(find.text('51'));
    await tester.tap(find.text('51'));
    await tester.pumpAndSettle();
    expect(find.text('상세'), findsOneWidget);

    // 한 번만 뒤로가면 리스트로 돌아온다
    await pressBack(tester);
    expect(find.text('상세'), findsNothing);
    expect(find.text('내 버스'), findsOneWidget);

    // 돌아온 뒤에는 다시 들어갈 수 있다
    await tester.tap(find.text('51'));
    await tester.pumpAndSettle();
    expect(find.text('상세'), findsOneWidget);
  });
}
