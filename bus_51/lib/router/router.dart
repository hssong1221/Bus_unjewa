import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/splash_screen.dart';
import 'package:flutter/material.dart';
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
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const InitSettingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeInOutCubic),
              ),
            ),
            child: child,
          ),
      ),
    ),

    /// 메인 리스트
    GoRoute(
      name: BusListScreen.routeName,
      path: BusListScreen.routeURL,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const BusListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeInOutCubic),
              ),
            ),
            child: child,
          ),
      ),
    ),

    /// 메인
    GoRoute(
      name: BusMainScreen.routeName,
      path: BusMainScreen.routeURL,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const BusMainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeInOutCubic),
              ),
            ),
            child: child,
          ),
      ),
    ),
  ],
);
