import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/theme/app_background.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // 리스트의 노선 추가로 진입하면 웰컴을 건너뛰고 ② 정류장 선택부터 시작
    final startFromStation = GoRouterState.of(context).uri.queryParameters['startFromStation'] == 'true';

    return ChangeNotifierProvider(
      create: (_) => InitProvider(
        startIdx: startFromStation ? InitProvider.stationStepIdx : 0,
      ),
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

    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _goToPrevStep() {
    _transitionController.reset();
    context.read<InitProvider>().prevAccountView();
    _transitionController.forward();
  }

  /// 상단 ← 버튼과 하드웨어 뒤로가기가 공유하는 동작
  void _goBack() {
    if (!context.read<InitProvider>().isFirstStep) {
      _goToPrevStep();
    } else if (context.canPop()) {
      // 노선 추가 플로우(push 진입)면 웰컴으로 가지 않고 리스트 화면으로 복귀
      context.pop();
    } else {
      // 스플래시에서 go로 진입한 최초 온보딩이면 앱 종료
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final watchProvider = context.watch<InitProvider>();
    // 최초 온보딩의 첫 단계(웰컴)에서만 ← 버튼 비활성. 추가 플로우는 첫 단계에서도 리스트로 나갈 수 있다
    final canGoBack = !watchProvider.isFirstStep || context.canPop();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Container(
          decoration: appBackgroundDecoration(colorScheme),
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
                              onPressed: canGoBack ? _goBack : null,
                              icon: Icon(
                                Icons.arrow_back,
                                color: canGoBack
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
                                        final progress = watchProvider.stepNumber / watchProvider.totalSteps;
                                        return FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            height: double.infinity,
                                            color: colorScheme.primary,
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
                              '${watchProvider.stepNumber}/${watchProvider.totalSteps}',
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
