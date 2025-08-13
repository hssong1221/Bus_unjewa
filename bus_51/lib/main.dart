import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/router/router.dart';
import 'package:bus_51/service/bus_api_service.dart';
import 'package:bus_51/service/dio_singleton.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:provider/provider.dart';

GetIt getIt = GetIt.I;

void setUp() {
  getIt.registerLazySingleton<BusApiService>(() => BusApiService());
  getIt.registerLazySingleton<StorageService>(() => StorageService());
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// 화면 세로 방향 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  setUp();

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

  await GetStorage.init();

  await FlutterNaverMap().init(
      clientId:"573iatcw1j",
      onAuthFailed: (ex) =>
      switch (ex) {
        NQuotaExceededException(:final message) =>
            print("사용량 초과 (message: $message)"),
        NUnauthorizedClientException() ||
        NClientUnspecifiedException() ||
        NAnotherAuthFailedException() =>
            print("인증 실패: $ex"),
      },
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              BusProvider(
                getIt<BusApiService>(),
                getIt<StorageService>(),
              ),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
