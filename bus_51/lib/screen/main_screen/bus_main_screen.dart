import 'dart:async';

import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/provider/timer_provider.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:flutter/material.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TimerProvider(),
        ),
      ],
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
  
  late Timer _timer;
  late List userSaveModel;
  late int idx;
  late UserSaveModel userModel;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _expandController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expandAnimation;
  
  // 확장 상태 관리
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeBusData();
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

  void _initializeBusData() {
    final readProvider = context.read<BusProvider>();
    final readTimerProvider = context.read<TimerProvider>();

    userSaveModel = readProvider.loadUserDataList();
    idx = readProvider.userDataIdx;
    userModel = userSaveModel[idx];

    _fadeController.forward();
    _pulseController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await readProvider.getBusArrivalTimeList(
        stationId: userModel.stationId.toString(),
        routeId: userModel.routeId.toString(),
        staOrder: userModel.staOrder.toString(),
      );

      var item = readProvider.busArrivalModel;
      if (item != null && readProvider.isBusOperating) {
        readTimerProvider.setTimerFromApi(item.predictTimeSec1 ?? 0, item.predictTimeSec2 ?? 0);
        _startTimer(userModel);
      }
    });
  }

  void _startTimer(UserSaveModel userModel) {
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      await context.read<BusProvider>().getBusArrivalTimeList(
            stationId: userModel.stationId.toString(),
            routeId: userModel.routeId.toString(),
            staOrder: userModel.staOrder.toString(),
          );

      var item = context.read<BusProvider>().busArrivalModel;
      var busProvider = context.read<BusProvider>();
      if (item != null && busProvider.isBusOperating) {
        context.read<TimerProvider>().setTimerFromApi(item.predictTimeSec1 ?? 0, item.predictTimeSec2 ?? 0);
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _expandController.forward();
      // 확장할 때 정류장 데이터 로드
      _loadRouteStationData();
    } else {
      _expandController.reverse();
    }
  }

  Future<void> _loadRouteStationData() async {
    try {
      final readProvider = context.read<BusProvider>();
      
      // 현재 사용자가 저장한 route 정보가 설정되어 있는지 확인
      // 설정되어 있지 않다면 현재 userModel의 route 정보를 설정
      if (readProvider.selectedRouteModel == null || 
          readProvider.selectedRouteModel?.routeId != userModel.routeId) {
        
        // userModel의 정보로 BusRouteModel을 생성해서 설정
        final routeModel = BusRouteModel(
          regionName: '', // 지역명은 빈 문자열로 기본값
          routeDestId: 0, // 목적지 ID는 0으로 기본값
          routeDestName: '', // 목적지명은 빈 문자열로 기본값
          routeId: userModel.routeId,
          routeName: userModel.routeName,
          routeTypeCd: userModel.routeTypeCd,
          routeTypeName: '', // 타입명은 빈 문자열로 기본값
          staOrder: userModel.staOrder,
        );
        
        readProvider.setSelectedRouteModel(routeModel);
        debugPrint('Route 정보 설정완료: routeId=${userModel.routeId}, routeName=${userModel.routeName}');
      }
      
      // 해당 노선의 정류장 리스트 가져오기
      await readProvider.getRouteStationList();
    } catch (e) {
      debugPrint('정류장 데이터 로딩 오류: $e');
      // 오류가 발생해도 UI는 계속 작동
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final readProvider = context.read<BusProvider>();
    final watchProvider = context.watch<BusProvider>();
    final readTimerProvider = context.read<TimerProvider>();
    final watchTimerProvider = context.watch<TimerProvider>();
    var item = watchProvider.busArrivalModel;
    
    // 버스 색상을 기본 테마로 사용
    final busColor = BusColor().setColor(userModel.routeTypeCd);

    if (item == null) {
      // 버스 운행 여부 확인
      if (!watchProvider.isBusOperating) {
        return _buildNoBusOperatingState(colorScheme, busColor);
      }
      return _buildLoadingState(colorScheme, busColor);
    }

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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              busColor.withValues(alpha: 0.08), // 버스 색상으로 그라데이션
              busColor.withValues(alpha: 0.02),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                await readProvider.getBusArrivalTimeList(
                  stationId: userModel.stationId.toString(),
                  routeId: userModel.routeId.toString(),
                  staOrder: userModel.staOrder.toString(),
                );

                var updatedItem = readProvider.busArrivalModel;
                if (updatedItem != null && readProvider.isBusOperating) {
                  readTimerProvider.setTimerFromApi(
                    updatedItem.predictTimeSec1 ?? 0,
                    updatedItem.predictTimeSec2 ?? 0
                  );
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildHeader(colorScheme, item, busColor),
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
                                ? _buildExpandedTimelineView(colorScheme, item, watchTimerProvider, readProvider, busColor, userModel)
                                : _buildCompactBusInfoSection(colorScheme, item, watchTimerProvider, readProvider, busColor),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              busColor.withValues(alpha: 0.1),
              colorScheme.surface,
            ],
          ),
        ),
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

  Widget _buildNoBusOperatingState(ColorScheme colorScheme, Color busColor) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              busColor.withValues(alpha: 0.1),
              colorScheme.surface,
            ],
          ),
        ),
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
                          onPressed: () async {
                            final readProvider = context.read<BusProvider>();
                            await readProvider.getBusArrivalTimeList(
                              stationId: userModel.stationId.toString(),
                              routeId: userModel.routeId.toString(),
                              staOrder: userModel.staOrder.toString(),
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 20),
                          label: Text(
                            '새로고침',
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

  Widget _buildHeader(ColorScheme colorScheme, item, Color busColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: busColor.withValues(alpha: 0.3), // 버스 색상으로 테두리
        ),
        boxShadow: [
          BoxShadow(
            color: busColor.withValues(alpha: 0.15), // 버스 색상으로 그림자
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

  Widget _buildCompactBusInfoSection(ColorScheme colorScheme, item, watchTimerProvider, readProvider, Color busColor) {
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
              "${(watchTimerProvider.remainingSeconds2 ~/ 60).toString().padLeft(2, '0')}분 ${(watchTimerProvider.remainingSeconds2 % 60).toString().padLeft(2, '0')}초",
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
              "${(watchTimerProvider.remainingSeconds1 ~/ 60).toString().padLeft(2, '0')}분 ${(watchTimerProvider.remainingSeconds1 % 60).toString().padLeft(2, '0')}초",
              busColor, // 버스 색상 사용
              Icons.directions_bus,
              true,
            ),
            const SizedBox(height: 20),
            // 확장 힌트 (더 크고 명확하게)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: busColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: busColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline,
                    color: busColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '전체 노선 보기',
                    style: context.textStyle.titleMedium.copyWith(
                      color: busColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: busColor,
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

  Widget _buildExpandedTimelineView(ColorScheme colorScheme, item, watchTimerProvider, readProvider, Color busColor, UserSaveModel userModel) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: busColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: busColor.withValues(alpha: 0.15),
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
                    color: busColor,
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
            Divider(color: busColor.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            // 타임라인 리스트
            Expanded(
              child: _buildStationTimeline(colorScheme, readProvider, busColor, item, userModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationTimeline(ColorScheme colorScheme, readProvider, Color busColor, item, UserSaveModel userModel) {
    var routeStations = readProvider.busRouteStationModel;
    var currentStationId = readProvider.selectedStationModel?.stationId;
    
    // 현재 정류장의 인덱스 찾기
    int currentStationIndex = -1;
    if (currentStationId != null && routeStations!.isNotEmpty) {
      currentStationIndex = routeStations.indexWhere(
        (station) => station.stationId == currentStationId,
      );
    } else {
      currentStationIndex = routeStations!.indexWhere(
        (station) => station.stationId == userModel.stationId,
      );
    }

    if (routeStations?.isEmpty ?? true) {
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
              '전체 노선 정보를 불러오는 중...',
              style: context.textStyle.bodyLarge.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: busColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(busColor),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: routeStations.length,
      controller: ScrollController(
        initialScrollOffset: currentStationIndex > 0 ? (currentStationIndex * 60.0) - 120 : 0,
      ),
      itemBuilder: (context, index) {
        var station = routeStations[index];
        bool isDestination = index == routeStations.length - 1;
        bool isLast = index == routeStations.length - 1;
        
        bool isCurrentStation = index == currentStationIndex;
        
        // 실제 버스 위치 계산
        bool hasBus1 = false;
        bool hasBus2 = false;
        
        try {
          int? location1 = int.tryParse(item.locationNo1?.toString() ?? '0');
          int? location2 = int.tryParse(item.locationNo2?.toString() ?? '0');
          
          if (location1 != null && location1 > 0 && currentStationIndex >= 0) {
            int bus1Index = currentStationIndex - location1;
            hasBus1 = index == bus1Index && bus1Index >= 0;
          }
          
          if (location2 != null && location2 > 0 && currentStationIndex >= 0) {
            int bus2Index = currentStationIndex - location2;
            hasBus2 = index == bus2Index && bus2Index >= 0;
          }
        } catch (e) {
          hasBus1 = false;
          hasBus2 = false;
        }

        return _buildTimelineStationItem(
          station.stationName,
          index: index,
          isCurrentStation: isCurrentStation,
          isDestination: isDestination,
          isLast: isLast,
          hasBus1: hasBus1,
          hasBus2: hasBus2,
          colorScheme: colorScheme,
          busColor: busColor,
        );
      },
    );
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
    Color getStationColor() {
      if (isCurrentStation) return busColor;
      if (isDestination) return busColor.withValues(alpha: 0.8);
      return busColor.withValues(alpha: 0.6);
    }

    // 버스가 있는 정류장의 배경색
    Color getBackgroundColor() {
      if (hasBus1 || hasBus2) {
        return busColor.withValues(alpha: 0.08);
      }
      return Colors.transparent;
    }

    return Container(
      height: 60,
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
                    color: busColor,
                  ),
                  size: const Size(50, 60),
                ),
                // 정류장 원형 아이콘 (중앙)
                Center(
                  child: Container(
                    width: isCurrentStation || hasBus1 || hasBus2 ? 20 : 16,
                    height: isCurrentStation || hasBus1 || hasBus2 ? 20 : 16,
                    decoration: BoxDecoration(
                      color: isCurrentStation || isDestination || hasBus1 || hasBus2 ? getStationColor() : colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: getStationColor(),
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
                    color: isNext ? color : colorScheme.surfaceVariant,
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
