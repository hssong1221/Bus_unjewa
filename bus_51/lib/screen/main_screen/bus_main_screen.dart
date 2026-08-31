import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/app_background.dart';
import 'package:bus_51/theme/app_tokens.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/viewmodel/bus_main_view_model.dart';
import 'package:bus_51/widget/app_card.dart';
import 'package:bus_51/widget/bus_pulse_loading.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// Screen
// --------------------------------------------------
class BusMainScreen extends StatelessWidget {
  const BusMainScreen({super.key, required this.userDataIdx});

  static const String routeName = "main";
  static const String routeURL = "/main";

  /// 저장 노선 리스트에서의 인덱스 (라우터 쿼리 파라미터로 전달)
  final int userDataIdx;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusMainViewModel(
        GetIt.I<BusArrivalRepository>(),
        GetIt.I<BusRouteStationRepository>(),
        savedBuses: GetIt.I<StorageService>().loadUserModelList(),
        index: userDataIdx,
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

class _BusMainViewState extends State<BusMainView> {
  // 확장 상태 관리
  bool _isExpanded = false;

  // 전체 노선 타임라인
  static const double _timelineItemHeight = 60;
  final ScrollController _timelineScrollController = ScrollController();
  bool _timelineScrolledToCurrent = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      // 확장할 때 전체 노선 정류장 로드 (최초 1회)
      context.read<BusMainViewModel>().loadTimeline();
    } else {
      // 다시 펼칠 때 탑승 정류장 위치로 스크롤되도록 되돌린다
      _timelineScrolledToCurrent = false;
    }
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
  }

  /// 남은 초 → MM:SS (60분 이상이면 분이 세 자리로 늘어남)
  static String _mmss(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void _goBackToList() => context.goNamed(BusListScreen.routeName);

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
            child: RefreshIndicator(
              onRefresh: () => vm.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(colorScheme, item),
                      const SizedBox(height: AppSpacing.sm),
                      _buildRouteTitle(colorScheme, busColor, userModel),
                      const SizedBox(height: AppSpacing.xl),
                      // 진입 애니메이션 없음 — 히어로 ↔ 전체 노선 확장 전환만 유지
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isExpanded
                            ? _buildExpandedTimelineView(colorScheme, item, vm, busColor)
                            : _buildHeroSection(colorScheme, item, vm, busColor),
                      ),
                      const SizedBox(height: AppSpacing.xl),
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
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, Color busColor) {
    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration(colorScheme),
        child: Center(
          child: BusPulseLoading(
            size: 48,
            color: busColor,
            text: '버스 정보를 불러오는 중...',
            textStyle: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
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
              _buildSimpleHeader(colorScheme, busColor, userModel.routeName),
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
                        '오고 있는 버스가 없어요',
                        style: context.textStyle.headlineSmall.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '아직 차고지에서 출발하지 않았거나\n운행이 종료됐을 수 있어요',
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
              _buildSimpleHeader(colorScheme, busColor, routeName),
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
                            // 버튼은 primary (노선색은 포인트에만)
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

  // 상단바: 뒤로가기 + 실시간 연결 상태
  Widget _buildTopBar(ColorScheme colorScheme, BusArrivalModel item) {
    final isLive = item.flag == "PASS";
    // 연결 상태 색은 고정 green/red 대신 primary/error
    final statusColor = isLive ? colorScheme.primary : colorScheme.error;

    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _goBackToList,
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: colorScheme.onSurface),
        ),
        const Spacer(),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          isLive ? '실시간' : '연결 끊김',
          style: context.textStyle.caption.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // 운행 없음 / 에러 화면 공용 상단바: 뒤로가기 + 노선번호 배지
  Widget _buildSimpleHeader(ColorScheme colorScheme, Color busColor, String? routeName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBackToList,
            icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          ),
          if (routeName != null) _buildRoutePill(busColor, routeName, large: false),
        ],
      ),
    );
  }

  // 노선번호 배지 + "정류장 · 종점 방면" 부제
  Widget _buildRouteTitle(ColorScheme colorScheme, Color busColor, UserSaveModel userModel) {
    return Column(
      children: [
        _buildRoutePill(busColor, userModel.routeName, large: true),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${userModel.stationName} 정류장 · ${userModel.routeDestName} 방면',
          style: context.textStyle.bodySmall.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // 노선색은 이 배지와 카운트다운, 타임라인의 버스 위치·탑승 정류장에만 쓴다
  Widget _buildRoutePill(Color busColor, String routeName, {required bool large}) {
    return Container(
      padding: large
          ? const EdgeInsets.symmetric(vertical: 8, horizontal: 18)
          : const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: busColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(large ? AppRadius.card : AppRadius.inner),
        border: Border.all(color: busColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        routeName,
        style: (large ? context.textStyle.headlineMedium : context.textStyle.titleMedium).copyWith(
          color: busColor,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  // 히어로: 다음 버스 카운트다운이 화면의 주인공, 그다음 버스는 하단 한 줄
  Widget _buildHeroSection(ColorScheme colorScheme, BusArrivalModel item, BusMainViewModel vm, Color busColor) {
    return Column(
      key: const ValueKey('hero'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  children: [
                    Text(
                      '다음 버스',
                      style: context.textStyle.caption.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _mmss(vm.remainingSeconds1),
                      style: context.textStyle.headlineLarge.copyWith(
                        color: busColor,
                        fontSize: 74,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -3,
                        height: 1.05,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.locationNo1}정거장 전 · ${item.stationNm1}',
                      style: context.textStyle.bodyMedium.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      '그다음',
                      style: context.textStyle.caption.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // 차량이 한 대만 운행 중이면 두 번째 버스 필드가 "" 로 온다
                    if (item.hasBus2) ...[
                      Text(
                        _mmss(vm.remainingSeconds2),
                        style: context.textStyle.titleMedium.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          '${item.locationNo2}정거장 전 · ${item.stationNm2}',
                          style: context.textStyle.caption.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      Text(
                        '버스 정보 없음',
                        style: context.textStyle.caption.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 52,
          child: FilledButton.tonalIcon(
            onPressed: _toggleExpanded,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
            label: const Text('전체 노선 보기'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHigh,
              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedTimelineView(ColorScheme colorScheme, BusArrivalModel item, BusMainViewModel vm, Color busColor) {
    return AppCard(
      key: const ValueKey('timeline'),
      onTap: _toggleExpanded,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          children: [
            // 헤더: 확장 중에도 카운트다운은 우측에 계속 보인다
            Row(
              children: [
                Text(
                  '전체 노선',
                  style: context.textStyle.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  _mmss(vm.remainingSeconds1),
                  style: context.textStyle.titleMedium.copyWith(
                    color: busColor,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.keyboard_arrow_up,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: AppSpacing.md),
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
    return Text(
      '아래로 당겨서 새로고침 · 60초마다 자동 갱신',
      textAlign: TextAlign.center,
      style: context.textStyle.caption.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.45),
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
