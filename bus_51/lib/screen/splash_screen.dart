import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/theme/custom_text_style.dart';
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

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // Animation constants
  static const Duration _fadeDuration = Duration(milliseconds: 1500);
  static const Duration _scaleDuration = Duration(milliseconds: 2000);
  static const Duration _splashDelay = Duration(milliseconds: 2500);
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashSequence();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(duration: _fadeDuration, vsync: this);
    _scaleController = AnimationController(duration: _scaleDuration, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  void _startSplashSequence() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(_splashDelay, () async {
        try {
          final readBusProvider = context.read<BusProvider>();
          var model = await readBusProvider.loadUserDataList();

          if(model.isEmpty) {
            context.goNamed(InitSettingScreen.routeName);
          } else {
            context.goNamed(BusListScreen.routeName);
          }
        } catch (e) {
          // 로컬 데이터 로딩 실패 = 데이터 없음으로 처리
          context.goNamed(InitSettingScreen.routeName);
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
              colorScheme.secondary,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            size: 64,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Bus 언제와',
                          style: context.textStyle.headlineMedium.copyWith(
                            color: colorScheme.onPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '실시간 버스 정보 서비스',
                          style: context.textStyle.bodyLarge.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
