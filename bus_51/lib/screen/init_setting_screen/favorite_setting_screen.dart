import 'package:bus_51/enums/bus_enums.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// --------------------------------------------------
class FavoriteSettingView extends StatefulWidget {
  const FavoriteSettingView({super.key});

  @override
  State<FavoriteSettingView> createState() => _FavoriteSettingViewState();
}

class _FavoriteSettingViewState extends State<FavoriteSettingView> with TickerProviderStateMixin {
  // Animation constants
  static const Duration _fadeDuration = Duration(milliseconds: 800);
  static const Duration _slideDuration = Duration(milliseconds: 600);

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // 선택된 버스 타입 (기본값: none)
  BusType _selectedBusType = BusType.none;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _initializeRouteData();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(duration: _fadeDuration, vsync: this);
    _slideController = AnimationController(duration: _slideDuration, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeRouteData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BusProvider>().getRouteStationList();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final readBusProvider = context.read<BusProvider>();
    final watchBusProvider = context.watch<BusProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.secondary.withValues(alpha: 0.04),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // 헤더는 고정
                  _buildHeader(colorScheme),
                  // 나머지는 스크롤 가능
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          _buildRouteInfoCard(colorScheme, watchBusProvider),
                          const SizedBox(height: 24),
                          _buildBottomSection(colorScheme, readBusProvider),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          Text(
            '설정 완료',
            style: context.textStyle.headlineMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '선택하신 노선 정보를 확인해주세요',
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard(ColorScheme colorScheme, watchBusProvider) {
    final busColor = BusColor().setColor(watchBusProvider.selectedRouteModel?.routeTypeCd ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: busColor.withValues(alpha: 0.3)), // 버스 색으로 테두리
        boxShadow: [
          BoxShadow(
            color: busColor.withValues(alpha: 0.1), // 버스 색으로 그림자
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Route Number
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: busColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: busColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              watchBusProvider.selectedRouteModel?.routeName ?? "버스 노선",
              style: context.textStyle.headlineMedium.copyWith(
                color: busColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Direction Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: busColor.withValues(alpha: 0.1), // 버스 색 테마 적용
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: busColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_forward, color: busColor, size: 20), // 버스 색으로 아이콘
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${watchBusProvider.selectedRouteModel?.routeDestName ?? "목적지"} 방면',
                    style: context.textStyle.labelLarge.copyWith(
                      color: busColor, // 버스 색으로 텍스트
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stations List
          _buildStationsList(colorScheme, watchBusProvider, busColor), // 버스 색 전달
        ],
      ),
    );
  }

  Widget _buildBottomSection(ColorScheme colorScheme, readBusProvider) {
    final watchBusProvider = context.watch<BusProvider>();
    final busColor = BusColor().setColor(watchBusProvider.selectedRouteModel?.routeTypeCd ?? 0);
    
    return Column(
      children: [
        // 버스 타입 선택
        _buildBusTypeSelector(colorScheme),
        const SizedBox(height: 24),
        // 확인 메시지
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.route_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                '정류장 순서가 맞나요?',
                style: context.textStyle.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 저장 버튼
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () => _saveRouteData(readBusProvider),
            icon: const Icon(
              Icons.check_rounded,
              size: 20,
            ),
            label: Text(
              '저장하고 시작하기',
              style: context.textStyle.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: FilledButton.styleFrom(
              elevation: 3,
              shadowColor: colorScheme.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveRouteData(readBusProvider) async {
    String routeName = readBusProvider.selectedRouteModel!.routeName;
    int stationId = readBusProvider.curStationModel!.stationId;
    int routeId = readBusProvider.selectedRouteModel!.routeId;
    int staOrder = readBusProvider.curStationModel!.stationSeq;
    int routeTypeCd = readBusProvider.selectedRouteModel!.routeTypeCd;

    debugPrint("$routeName $stationId $routeId $staOrder $routeTypeCd");

    final order = UserSaveModel(
      routeName: routeName,
      stationId: stationId,
      routeId: routeId,
      staOrder: staOrder,
      routeTypeCd: routeTypeCd,
      busType: _selectedBusType,
    );

    await readBusProvider.saveUserDataList(order);
    await context.pushNamed(BusListScreen.routeName);
  }

  Widget _buildBusTypeSelector(ColorScheme colorScheme) {
    final watchBusProvider = context.watch<BusProvider>();
    final busColor = BusColor().setColor(watchBusProvider.selectedRouteModel?.routeTypeCd ?? 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: busColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '이 버스는 언제 이용하시나요?',
                style: context.textStyle.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 평시
              Expanded(
                child: _buildTypeButton(
                  title: '평시',
                  subtitle: '일반',
                  icon: Icons.directions_bus_rounded,
                  type: BusType.none,
                  colorScheme: colorScheme,
                  busColor: busColor,
                ),
              ),
              const SizedBox(width: 12),
              // 출근
              Expanded(
                child: _buildTypeButton(
                  title: '출근',
                  subtitle: '집 → 회사',
                  icon: Icons.business_center_rounded,
                  type: BusType.work,
                  colorScheme: colorScheme,
                  busColor: busColor,
                ),
              ),
              const SizedBox(width: 12),
              // 퇴근
              Expanded(
                child: _buildTypeButton(
                  title: '퇴근',
                  subtitle: '회사 → 집',
                  icon: Icons.home_rounded,
                  type: BusType.home,
                  colorScheme: colorScheme,
                  busColor: busColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required BusType type,
    required ColorScheme colorScheme,
    required Color busColor,
  }) {
    final isSelected = _selectedBusType == type;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedBusType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? busColor.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? busColor
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? busColor.withValues(alpha: 0.2)
                      : colorScheme.onSurface.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected 
                      ? busColor 
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: context.textStyle.labelMedium.copyWith(
                  color: isSelected 
                      ? busColor 
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: context.textStyle.bodySmall.copyWith(
                  color: isSelected 
                      ? busColor.withValues(alpha: 0.8)
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationsList(ColorScheme colorScheme, watchBusProvider, Color busColor) {
    var routeStations = watchBusProvider.busRouteStationModel;
    var currentStationId = watchBusProvider.selectedStationModel?.stationId;

    if (routeStations?.isEmpty ?? true) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bus,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                '정류장 정보를 불러오는 중...',
                style: context.textStyle.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 현재 정류장의 인덱스 찾기
    int currentStationIndex = routeStations!.indexWhere(
      (station) => station.stationId == currentStationId,
    );

    // 현재 정류장부터 종점까지만 표시
    List<dynamic> displayStations = currentStationIndex >= 0 ? routeStations.sublist(currentStationIndex) : routeStations;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        itemCount: displayStations.length,
        separatorBuilder: (context, index) => Container(),
        itemBuilder: (context, index) {
          var station = displayStations[index];
          bool isCurrentStation = index == 0; // 첫 번째가 현재 위치
          bool isDestination = index == displayStations.length - 1;
          bool isLast = index == displayStations.length - 1;

          return _buildTimelineStationRow(
            station.stationName,
            isCurrentStation: isCurrentStation,
            isDestination: isDestination,
            isLast: isLast,
            colorScheme: colorScheme,
            busColor: busColor,
          );
        },
      ),
    );
  }

  Widget _buildTimelineStationRow(
    String stationName, {
    required bool isCurrentStation,
    required bool isDestination,
    required bool isLast,
    required ColorScheme colorScheme,
    required Color busColor,
  }) {
    Color getStationColor() {
      if (isCurrentStation) return busColor;
      if (isDestination) return busColor.withValues(alpha: 0.8);
      return busColor.withValues(alpha: 0.6);
    }

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          // 타임라인 영역 (고정 너비)
          SizedBox(
            width: 40,
            height: 44,
            child: CustomPaint(
              painter: TimelinePainter(
                isFirst: isCurrentStation,
                isLast: isLast,
                color: busColor,
              ),
              child: Center(
                child: Container(
                  width: isCurrentStation ? 16 : (isDestination ? 14 : 10),
                  height: isCurrentStation ? 16 : (isDestination ? 14 : 10),
                  decoration: BoxDecoration(
                    color: isCurrentStation || isDestination ? getStationColor() : colorScheme.surface,
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
                  child: isDestination
                      ? const Icon(
                          Icons.flag,
                          color: Colors.white,
                          size: 8,
                        )
                      : null,
                ),
              ),
            ),
          ),
          // 정류장 정보 (수직 중앙 정렬)
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.only(left: 12),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      stationName,
                      style: context.textStyle.bodyMedium.copyWith(
                        color: getStationColor(),
                        fontWeight: isCurrentStation || isDestination ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 상태 태그
                  if (isCurrentStation)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: busColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '현재 위치',
                        style: context.textStyle.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (isDestination && !isCurrentStation)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: busColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '종점',
                        style: context.textStyle.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
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
