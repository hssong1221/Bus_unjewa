import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/theme/app_background.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/viewmodel/bus_main_view_model.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// Screen
// --------------------------------------------------
class BusMainScreen extends StatelessWidget {
  const BusMainScreen({super.key});

  static const String routeName = "main";
  static const String routeURL = "/main";

  @override
  Widget build(BuildContext context) {
    final busProvider = context.read<BusProvider>();
    return ChangeNotifierProvider(
      create: (_) => BusMainViewModel(
        GetIt.I<BusArrivalRepository>(),
        GetIt.I<BusRouteStationRepository>(),
        savedBuses: busProvider.loadUserDataList(),
        index: busProvider.userDataIdx,
      )..init(),
      child: const BusMainView(),
    );
  }
}

// --------------------------------------------------
// View
// --------------------------------------------------
class BusMainView extends StatefulWidget {
  const BusMainView({super.key});

  @override
  State<BusMainView> createState() => _BusMainViewState();
}

class _BusMainViewState extends State<BusMainView> with TickerProviderStateMixin {
  // Animation constants
  static const Duration _fadeDuration = Duration(milliseconds: 1000);
  static const Duration _pulseDuration = Duration(milliseconds: 2000);

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _expandController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expandAnimation;

  // 확장 상태 관리
  bool _isExpanded = false;

  // 전체 노선 타임라인
  static const double _timelineItemHeight = 60;
  final ScrollController _timelineScrollController = ScrollController();
  bool _timelineScrolledToCurrent = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _setupAnimations() {
    _fadeController = AnimationController(duration: _fadeDuration, vsync: this);
    _pulseController = AnimationController(duration: _pulseDuration, vsync: this);
    _expandController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOutCubic),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
      // 확장할 때 전체 노선 정류장 로드 (최초 1회)
      context.read<BusMainViewModel>().loadTimeline();
    } else {
      _expandController.reverse();
      // 다시 펼칠 때 탑승 정류장 위치로 스크롤되도록 되돌린다
      _timelineScrolledToCurrent = false;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _expandController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<BusMainViewModel>();
    final userModel = vm.userModel;

    // 버스 색상을 기본 테마로 사용
    final busColor = userModel != null ? BusColor().setColor(userModel.routeTypeCd) : colorScheme.primary;

    return switch (vm.state) {
      BusMainLoading() => _buildLoadingState(colorScheme, busColor),
      BusMainNotOperating() => _buildNoBusOperatingState(colorScheme, busColor, userModel!),
      BusMainError(:final message) => _buildErrorState(
          colorScheme,
          busColor,
          message,
          routeName: userModel?.routeName,
          onRetry: userModel != null ? vm.refresh : null,
        ),
      BusMainSuccess(:final arrival) => _buildMainContent(colorScheme, busColor, vm, arrival, userModel!),
    };
  }

  Widget _buildMainContent(ColorScheme colorScheme, Color busColor, BusMainViewModel vm, BusArrivalModel item, UserSaveModel userModel) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // BusMainScreen에서 뒤로가기 시 BusListScreen으로 이동
          context.goNamed(BusListScreen.routeName);
        }
      },
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: appBackgroundDecoration(colorScheme),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () => vm.refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildHeader(colorScheme, item, busColor, userModel),
                        const SizedBox(height: 32),
                        // 확장 가능한 버스 정보 섹션
                        AnimatedBuilder(
                          animation: _expandAnimation,
                          builder: (context, child) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _isExpanded
                                  ? _buildExpandedTimelineView(colorScheme, item, vm, busColor)
                                  : _buildCompactBusInfoSection(colorScheme, item, vm, busColor),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildRefreshHint(colorScheme),
                        const SizedBox(height: 100), // 추가 여백으로 스크롤 여유 공간 확보
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, Color busColor) {
    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration(colorScheme),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: busColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    size: 48,
                    color: busColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '버스 정보를 불러오는 중...',
                style: context.textStyle.bodyLarge.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoBusOperatingState(ColorScheme colorScheme, Color busColor, UserSaveModel userModel) {
    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration(colorScheme),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.goNamed(BusListScreen.routeName),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userModel.routeName.toString(),
                            style: context.textStyle.headlineLarge.copyWith(
                              color: busColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 메인 컨텐츠
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_bus_filled,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '현재 정류장으로 오고있는 버스가 없습니다',
                        style: context.textStyle.headlineSmall.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '버스가 아직 차고지에서 출발하지 않았거나\n운행이 종료되었을 수 있습니다',
                        style: context.textStyle.bodyLarge.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // 새로고침 버튼
                      SizedBox(
                        width: 200,
                        child: FilledButton.icon(
                          onPressed: () => context.read<BusMainViewModel>().refresh(),
                          icon: const Icon(Icons.refresh, size: 20),
                          label: Text(
                            '새로고침',
                            style: context.textStyle.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    ColorScheme colorScheme,
    Color busColor,
    String message, {
    String? routeName,
    Future<void> Function()? onRetry,
  }) {
    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration(colorScheme),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.goNamed(BusListScreen.routeName),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (routeName != null)
                      Expanded(
                        child: Text(
                          routeName,
                          style: context.textStyle.headlineLarge.copyWith(
                            color: busColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 메인 컨텐츠
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_off,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '버스 정보를 불러오지 못했습니다',
                        style: context.textStyle.headlineSmall.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: context.textStyle.bodyLarge.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (onRetry != null)
                        SizedBox(
                          width: 200,
                          child: FilledButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh, size: 20),
                            label: Text(
                              '다시 시도',
                              style: context.textStyle.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: busColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, item, Color busColor, UserSaveModel userModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Connection Status (더 작게)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: item.flag == "PASS" ? Colors.green : Colors.red, // 연결됨일 때 고정 연두색
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.flag == "PASS" ? "실시간 연결됨" : "연결 끊김",
                style: context.textStyle.caption.copyWith(
                  color: item.flag == "PASS" ? Colors.green : Colors.red, // 연결됨일 때 고정 연두색
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Route Number (배경과 함께, 조금 더 크게)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
            decoration: BoxDecoration(
              color: busColor.withValues(alpha: 0.15), // 조금 더 진한 배경
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: busColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              userModel.routeName,
              style: context.textStyle.headlineLarge.copyWith(
                color: busColor,
                fontWeight: FontWeight.w800,
                fontSize: 32,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBusInfoSection(ColorScheme colorScheme, item, BusMainViewModel vm, Color busColor) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Second Bus
            _buildBusInfo(
              context,
              "2번째 버스",
              "${item.stationNm2} - ${item.locationNo2}정거장 전",
              "${(vm.remainingSeconds2 ~/ 60).toString().padLeft(2, '0')}분 ${(vm.remainingSeconds2 % 60).toString().padLeft(2, '0')}초",
              colorScheme.onSurface.withValues(alpha: 0.6),
              Icons.directions_bus_outlined,
              false,
            ),
            const SizedBox(height: 20),
            // Route Line
            Container(
              height: 2,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            // First Bus (Next)
            _buildBusInfo(
              context,
              "다음 버스",
              "${item.stationNm1} - ${item.locationNo1}정거장 전",
              "${(vm.remainingSeconds1 ~/ 60).toString().padLeft(2, '0')}분 ${(vm.remainingSeconds1 % 60).toString().padLeft(2, '0')}초",
              busColor,
              // 버스 색상 사용
              Icons.directions_bus,
              true,
            ),
            const SizedBox(height: 20),
            // 확장 힌트 (더 크고 명확하게)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '전체 노선 보기',
                    style: context.textStyle.titleMedium.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedTimelineView(ColorScheme colorScheme, BusArrivalModel item, BusMainViewModel vm, Color busColor) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 헤더: 축소 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '전체 노선',
                  style: context.textStyle.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_up,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            // 타임라인 리스트
            Expanded(
              child: _buildStationTimeline(colorScheme, vm, busColor, item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationTimeline(ColorScheme colorScheme, BusMainViewModel vm, Color busColor, BusArrivalModel item) {
    return switch (vm.timelineState) {
      BusTimelineLoading() => _buildTimelineNotice(
          colorScheme,
          busColor,
          '전체 노선 정보를 불러오는 중...',
          showProgress: true,
        ),
      BusTimelineError(:final message) => _buildTimelineNotice(colorScheme, busColor, message),
      BusTimelineSuccess(:final stations, :final currentIndex) =>
        _buildTimelineList(colorScheme, busColor, item, stations, currentIndex),
    };
  }

  Widget _buildTimelineNotice(
    ColorScheme colorScheme,
    Color busColor,
    String message, {
    bool showProgress = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: busColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bus,
              size: 32,
              color: busColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showProgress) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineList(
    ColorScheme colorScheme,
    Color busColor,
    BusArrivalModel item,
    List<BusRouteStationModel> stations,
    int currentIndex,
  ) {
    _scrollTimelineToCurrent(currentIndex);

    // 도착 정보의 "몇 정거장 전"으로 각 버스가 서 있는 정류장 인덱스를 계산
    final int bus1Index = _busStationIndex(item.locationNo1, currentIndex);
    final int bus2Index = _busStationIndex(item.locationNo2, currentIndex);

    return ListView.builder(
      controller: _timelineScrollController,
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final isLast = index == stations.length - 1;

        return _buildTimelineStationItem(
          stations[index].stationName,
          index: index,
          isCurrentStation: index == currentIndex,
          isDestination: isLast,
          isLast: isLast,
          hasBus1: index == bus1Index,
          hasBus2: index == bus2Index,
          colorScheme: colorScheme,
          busColor: busColor,
        );
      },
    );
  }

  /// 버스가 서 있는 정류장의 인덱스. 계산할 수 없으면 -1
  int _busStationIndex(String locationNo, int currentIndex) {
    final location = int.tryParse(locationNo) ?? 0;
    if (location <= 0 || currentIndex < 0) return -1;

    final index = currentIndex - location;
    return index >= 0 ? index : -1;
  }

  /// 타임라인을 펼칠 때마다 한 번씩 탑승 정류장 위치로 스크롤.
  /// 카운트다운 때문에 1초마다 리빌드되므로 매 빌드 스크롤은 막아야 한다
  void _scrollTimelineToCurrent(int currentIndex) {
    if (_timelineScrolledToCurrent || currentIndex <= 0) return;
    _timelineScrolledToCurrent = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_timelineScrollController.hasClients) return;
      final offset = (currentIndex * _timelineItemHeight) - 120;
      _timelineScrollController.jumpTo(
        offset.clamp(0.0, _timelineScrollController.position.maxScrollExtent),
      );
    });
  }

  Widget _buildRefreshHint(ColorScheme colorScheme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Text(
              '새로고침',
              style: context.textStyle.caption.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStationItem(
    String stationName, {
    required int index,
    required bool isCurrentStation,
    required bool isDestination,
    required bool isLast,
    required bool hasBus1,
    required bool hasBus2,
    required ColorScheme colorScheme,
    required Color busColor,
  }) {
    // 현재 정류장·버스 위치만 노선 색 포인트, 나머지는 무채색
    Color getStationColor() {
      if (isCurrentStation) return busColor;
      if (isDestination) return colorScheme.onSurface.withValues(alpha: 0.75);
      return colorScheme.onSurface.withValues(alpha: 0.45);
    }

    // 버스가 있는 정류장의 배경색
    Color getBackgroundColor() {
      if (hasBus1 || hasBus2) {
        return busColor.withValues(alpha: 0.08);
      }
      return Colors.transparent;
    }

    return Container(
      height: _timelineItemHeight,
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 타임라인 영역
          SizedBox(
            width: 50,
            child: Stack(
              children: [
                // 타임라인 선
                CustomPaint(
                  painter: TimelinePainter(
                    isFirst: index == 0,
                    isLast: isLast,
                    color: colorScheme.outline,
                  ),
                  size: const Size(50, 60),
                ),
                // 정류장 원형 아이콘 (중앙)
                Center(
                  child: Container(
                    width: isCurrentStation || hasBus1 || hasBus2 ? 20 : 16,
                    height: isCurrentStation || hasBus1 || hasBus2 ? 20 : 16,
                    decoration: BoxDecoration(
                      color: hasBus1 || hasBus2
                          ? busColor
                          : (isCurrentStation || isDestination ? getStationColor() : colorScheme.surface),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasBus1 || hasBus2 ? busColor : getStationColor(),
                        width: isCurrentStation ? 3 : 2,
                      ),
                      boxShadow: isCurrentStation
                          ? [
                              BoxShadow(
                                color: getStationColor().withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: _getStationIcon(isCurrentStation, isDestination, hasBus1, hasBus2, busColor),
                  ),
                ),
              ],
            ),
          ),
          // 정류장 정보
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stationName,
                    style: context.textStyle.bodyMedium.copyWith(
                      color: getStationColor(),
                      fontWeight: isCurrentStation || isDestination ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isCurrentStation)
                    Text(
                      '현재 위치',
                      style: context.textStyle.caption.copyWith(
                        color: busColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _getStationIcon(bool isCurrentStation, bool isDestination, bool hasBus1, bool hasBus2, Color busColor) {
    // 현재 위치가 최우선
    if (isCurrentStation) {
      return const Icon(
        Icons.location_on,
        color: Colors.white,
        size: 12,
      );
    }

    // 종점 아이콘
    if (isDestination) {
      return const Icon(
        Icons.flag,
        color: Colors.white,
        size: 10,
      );
    }

    // 1번째 버스 아이콘 - 크게
    if (hasBus1) {
      return const Icon(
        Icons.directions_bus,
        color: Colors.white,
        size: 14,
      );
    }

    // 2번째 버스 아이콘 - 크게
    if (hasBus2) {
      return const Icon(
        Icons.directions_bus,
        color: Colors.white,
        size: 14,
      );
    }

    return null;
  }

  Widget _buildBusInfo(
    BuildContext context,
    String title,
    String location,
    String time,
    Color color,
    IconData icon,
    bool isNext,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNext ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isNext ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyle.titleMedium.copyWith(
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: context.textStyle.bodyMedium.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isNext ? color : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$time 후 도착",
                    style: context.textStyle.labelMedium.copyWith(
                      color: isNext ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter for timeline line
class TimelinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;

  TimelinePainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 2;

    final centerX = size.width / 2;

    // 위쪽 선 (첫 번째가 아닌 경우)
    if (!isFirst) {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, size.height / 2),
        paint,
      );
    }

    // 아래쪽 선 (마지막이 아닌 경우)
    if (!isLast) {
      canvas.drawLine(
        Offset(centerX, size.height / 2),
        Offset(centerX, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
