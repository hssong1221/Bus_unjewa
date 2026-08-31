import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/app_background.dart';
import 'package:bus_51/theme/app_tokens.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/viewmodel/favorite_setting_view_model.dart';
import 'package:bus_51/widget/app_card.dart';
import 'package:bus_51/widget/bus_pulse_loading.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// 온보딩 마지막 단계: 선택한 노선/정류장을 확인하고 저장하는 화면
// --------------------------------------------------
class FavoriteSettingView extends StatelessWidget {
  const FavoriteSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoriteSettingViewModel(
        GetIt.I<BusRouteStationRepository>(),
        GetIt.I<StorageService>(),
        route: context.read<InitProvider>().selectedRouteModel,
      )..init(),
      child: const _FavoriteSettingBody(),
    );
  }
}

class _FavoriteSettingBody extends StatefulWidget {
  const _FavoriteSettingBody();

  @override
  State<_FavoriteSettingBody> createState() => _FavoriteSettingBodyState();
}

class _FavoriteSettingBodyState extends State<_FavoriteSettingBody> {
  // 타임라인 박스 높이 (4줄 정도 보이고 나머지는 스크롤)
  static const double _timelineHeight = 176;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<FavoriteSettingViewModel>();
    final busColor = vm.route != null ? BusColor().setColor(vm.route!.routeTypeCd) : colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration(colorScheme),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더는 고정
              _buildHeader(colorScheme),
              // 나머지는 스크롤 가능
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRouteInfoCard(colorScheme, vm, busColor),
                      const SizedBox(height: 24),
                      _buildSaveButton(vm),
                      const SizedBox(height: 24),
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          Text(
            '노선 확인',
            style: context.textStyle.headlineMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '선택한 노선을 확인하고 저장해 주세요',
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard(ColorScheme colorScheme, FavoriteSettingViewModel vm, Color busColor) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Route Number
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: busColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.inner),
              border: Border.all(color: busColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              vm.route?.routeName ?? "버스 노선",
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
              color: busColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: busColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_forward, color: busColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${vm.route?.routeDestName ?? "목적지"} 방면',
                    style: context.textStyle.labelLarge.copyWith(
                      color: busColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stations Timeline (상태별 분기)
          switch (vm.state) {
            FavoriteSettingLoading() => _buildStationsLoading(colorScheme),
            FavoriteSettingError(:final message) => _buildStationsError(colorScheme, vm, message),
            FavoriteSettingReady(:final timelineStations) => _buildStationsTimeline(colorScheme, timelineStations, busColor),
          },
        ],
      ),
    );
  }

  Widget _buildStationsLoading(ColorScheme colorScheme) {
    return SizedBox(
      height: 140,
      child: Center(
        child: BusPulseLoading.primary(
          size: 32,
          text: '정류장 정보를 불러오는 중...',
          textStyle: context.textStyle.bodyMedium.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildStationsError(ColorScheme colorScheme, FavoriteSettingViewModel vm, String message) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 32,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.textStyle.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => vm.retry(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  // 탑승 정류장부터 종점까지, 4줄 높이 안에서 스크롤
  Widget _buildStationsTimeline(ColorScheme colorScheme, List<BusRouteStationModel> stations, Color busColor) {
    return Container(
      width: double.infinity,
      height: _timelineHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          return _buildTimelineStationRow(
            stations[index].stationName,
            isCurrentStation: index == 0,
            isDestination: index == stations.length - 1,
            isLast: index == stations.length - 1,
            colorScheme: colorScheme,
            busColor: busColor,
          );
        },
      ),
    );
  }

  Widget _buildSaveButton(FavoriteSettingViewModel vm) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: vm.canSave ? _onSave : null,
        icon: vm.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(
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
      ),
    );
  }

  Future<void> _onSave() async {
    final saved = await context.read<FavoriteSettingViewModel>().save();
    if (saved && mounted) {
      // push가 아니라 go로 이동해 온보딩 스택이 남지 않게 한다
      context.goNamed(BusListScreen.routeName);
    }
  }

  Widget _buildTimelineStationRow(
    String stationName, {
    required bool isCurrentStation,
    required bool isDestination,
    required bool isLast,
    required ColorScheme colorScheme,
    required Color busColor,
  }) {
    // 탑승 정류장만 노선 색 포인트, 나머지는 무채색
    Color getStationColor() {
      if (isCurrentStation) return busColor;
      if (isDestination) return colorScheme.onSurface.withValues(alpha: 0.8);
      return colorScheme.onSurface.withValues(alpha: 0.5);
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
                color: colorScheme.outline,
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
                        '탑승 정류장',
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
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
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
