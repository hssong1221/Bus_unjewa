import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/theme/custom_text_style.dart';
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

class _InitSettingViewState extends State<InitSettingView> with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOutCubic,
    ));
    
    // URL 파라미터 확인하여 StationSettingView부터 시작할지 결정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final startFromStation = uri.queryParameters['startFromStation'] == 'true';
      
      if (startFromStation) {
        context.read<InitProvider>().setInitialIndex(1); // StationSettingView부터 시작 (index 1)
      }
    });
    
    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final watchProvider = context.watch<InitProvider>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.secondary.withValues(alpha: 0.03),
                colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              // Progress Indicator
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 0),
                  child: Row(
                        children: [
                          // 뒤로가기 버튼
                          SizedBox(
                            width: 48,
                            child: IconButton(
                              onPressed: watchProvider.curIdx > 0 
                                  ? () {
                                      _transitionController.reset();
                                      watchProvider.prevAccountView();
                                      _transitionController.forward();
                                    }
                                  : null,
                              icon: Icon(
                                Icons.arrow_back,
                                color: watchProvider.curIdx > 0 
                                    ? colorScheme.onSurface 
                                    : colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          // 프로그레스바 (중앙)
                          Expanded(
                            child: Container(
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: colorScheme.surfaceContainerHighest,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Stack(
                                  children: [
                                    // 백그라운드
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.transparent,
                                    ),
                                    // 프로그레스 바
                                    AnimatedBuilder(
                                      animation: _transitionController,
                                      builder: (context, child) {
                                        final progress = (watchProvider.curIdx + 1) / 4;
                                        return FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  colorScheme.primary.withValues(alpha: 0.8),
                                                  colorScheme.primary,
                                                  colorScheme.secondary,
                                                ],
                                                stops: const [0.0, 0.7, 1.0],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                                  blurRadius: 6,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 카운터 (우측 고정 너비)
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${watchProvider.curIdx + 1}/4',
                              style: context.textStyle.labelSmall.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                  ),
                ),
              ),
              // Content Area
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: watchProvider.curView,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
