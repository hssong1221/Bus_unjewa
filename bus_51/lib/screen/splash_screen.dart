import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// Screen
// --------------------------------------------------
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const String routeName = "splash";
  static const String routeURL = "/splash";

  @override
  Widget build(BuildContext context) {
    return const SplashView();
  }
}

// --------------------------------------------------
// View
// --------------------------------------------------
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {

  @override
  void initState() {
    super.initState();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () async {
        final readBusProvider = context.read<BusProvider>();
        //readBusProvider.deleteAllData();
        var model = await readBusProvider.loadUserDataList();

        if(model.isEmpty) {
          context.goNamed(InitSettingScreen.routeName);
        } else {
          context.goNamed(BusListScreen.routeName);
        }

        // fcm 토큰 확인
        // 로그인 상태 체크 -> 로컬에 저장데이터 있는지 없는지만 확인하는 것으로 변경하기
        /*final isLogin = (await getIt<StorageServices>().getAccessToken()).isNotEmpty;
        if (!context.mounted) return;*/

        /*if (isLogin) {
          AppConstants.setGuestMode(GuestMode.user);
          context.goNamed(MainScreen.routeName);
        } else {
          AppConstants.setGuestMode(GuestMode.guest);
          context.goNamed(AccountScreen.routeName);
        }*/
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SizedBox.shrink(),
      ),
    );
  }
}
