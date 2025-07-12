import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/splash_screen.dart';
import 'package:go_router/go_router.dart';

//final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  //navigatorKey: navigatorKey,
  initialLocation: SplashScreen.routeURL,
  //observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
  routes: <RouteBase>[
    /// 스플래시
    GoRoute(
      name: SplashScreen.routeName,
      path: SplashScreen.routeURL,
      builder: (context, state) => const SplashScreen(),
    ),

    /// 초기 설정 화면
    GoRoute(
      name: InitSettingScreen.routeName,
      path: InitSettingScreen.routeURL,
      builder: (context, state) => const InitSettingScreen(),
    ),

    /// 메인 리스트
    GoRoute(
      name: BusListScreen.routeName,
      path: BusListScreen.routeURL,
      builder: (context, state) => const BusListScreen(),
    ),

    /// 메인
    GoRoute(
      name: BusMainScreen.routeName,
      path: BusMainScreen.routeURL,
      builder: (context, state) => const BusMainScreen(),
    ),
  ],
);
