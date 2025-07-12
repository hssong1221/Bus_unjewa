import 'package:bus_51/provider/init_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// Screen
// --------------------------------------------------
class InitSettingScreen extends StatelessWidget {
  const InitSettingScreen({super.key});

  static const String routeName = "init";
  static const String routeURL = "/init";

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InitProvider(),
        ),
      ],
      child: const InitSettingView(),
    );
  }
}

// --------------------------------------------------
// View
// --------------------------------------------------
class InitSettingView extends StatefulWidget {
  const InitSettingView({super.key});

  @override
  State<InitSettingView> createState() => _InitSettingViewState();
}

class _InitSettingViewState extends State<InitSettingView> {

  @override
  Widget build(BuildContext context) {
    final watchProvider = context.watch<InitProvider>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.pop();
        }
      },
      child: watchProvider.curView,
    );
  }
}
