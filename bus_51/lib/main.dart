import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_route_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/repository/bus_station_repository.dart';
import 'package:bus_51/router/router.dart';
import 'package:bus_51/service/bus_api_service.dart';
import 'package:bus_51/service/dio_singleton.dart';
import 'package:bus_51/service/naver_map_service.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:bus_51/tracking/bus_notifications.dart';
import 'package:bus_51/tracking/bus_tracking_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

GetIt getIt = GetIt.I;

void setUp(SharedPreferencesWithCache prefs) {
  getIt.registerLazySingleton<BusApiService>(() => BusApiService());
  getIt.registerLazySingleton<StorageService>(() => StorageService(prefs));
  getIt.registerLazySingleton<BusArrivalRepository>(() => BusArrivalRepository(getIt<BusApiService>()));
  getIt.registerLazySingleton<BusStationRepository>(() => BusStationRepository(getIt<BusApiService>()));
  getIt.registerLazySingleton<BusRouteRepository>(() => BusRouteRepository(getIt<BusApiService>()));
  getIt.registerLazySingleton<BusRouteStationRepository>(() => BusRouteStationRepository(getIt<BusApiService>()));
  // 도착 알림 (포그라운드 서비스 파사드)
  getIt.registerLazySingleton<BusTrackingService>(() => FlutterForegroundBusTrackingService());
  // 네이버 지도 SDK 초기화·인증 실패 전달
  getIt.registerLazySingleton<NaverMapService>(() => NaverMapService());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 릴리즈에서는 debugPrint를 빈 함수로 바꿔 코드 곳곳의 로그를 한 번에 끈다 (디버그에서는 그대로 찍힘)
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  /// 도착 알림 서비스(별도 isolate)가 "끝났다"고 보내는 메시지를 받을 포트. 앱이 뜰 때 한 번 열어 둔다
  FlutterForegroundTask.initCommunicationPort();

  /// 화면 세로 방향 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  setUp(prefs);

  /// 도착 알람 채널을 미리 만든다 (사용자가 설정에서 끌 수 있고, 켜기 전에 그 상태를 확인한다)
  await initBusNotifications();

  /// Dio
  final Dio dio = DioSingleton.getInstance();

  if (kDebugMode) {
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      compact: true,
      // 줄 길이가 줄 너비를 초과하는 경우 PrettyDioLogger가 뿌려주는 로그에서 Key 값이 잘려보일 수 있음
      maxWidth: 160,
    ));
  }

  /// 네이버 지도 SDK. 인증 실패는 NaverMapService 가 받아 정류장 화면이 재시도 안내를 띄운다
  await getIt<NaverMapService>().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      routerConfig: router,
      builder: (context, child) => AppInitializer(child: child!),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // FCM 서비스 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //final fcmToken = await getIt<FcmService>().getFcmToken();
      //debugPrint("fcmToken: $fcmToken");
    });
  }

  @override
  Widget build(BuildContext context) {
    //return widget.child;
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: widget.child,
    );
  }
}
