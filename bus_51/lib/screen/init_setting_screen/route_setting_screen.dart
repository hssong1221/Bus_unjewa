import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/repository/bus_route_repository.dart';
import 'package:bus_51/theme/app_background.dart';
import 'package:bus_51/theme/app_tokens.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/viewmodel/route_setting_view_model.dart';
import 'package:bus_51/widget/app_card.dart';
import 'package:bus_51/widget/bus_pulse_loading.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// 선택한 정류장을 경유하는 버스 노선을 골라 다음 단계로 진행하는 화면
// --------------------------------------------------
class RouteSettingView extends StatelessWidget {
  const RouteSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RouteSettingViewModel(
        GetIt.I<BusRouteRepository>(),
        stationId: context.read<InitProvider>().selectedStationModel?.stationId,
      )..init(),
      child: const _RouteSettingBody(),
    );
  }
}

class _RouteSettingBody extends StatefulWidget {
  const _RouteSettingBody();

  @override
  State<_RouteSettingBody> createState() => _RouteSettingBodyState();
}

class _RouteSettingBodyState extends State<_RouteSettingBody> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<RouteSettingViewModel>();
    final stationName = context.watch<InitProvider>().selectedStationModel?.stationName;

    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration(colorScheme),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(colorScheme, stationName),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: switch (vm.state) {
                    RouteSettingLoading() => _buildLoadingState(colorScheme),
                    RouteSettingEmpty() => _buildEmptyState(colorScheme),
                    RouteSettingError(:final message) => _buildErrorState(colorScheme, vm, message),
                    RouteSettingSuccess(:final routes) => _buildRoutesList(routes),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, String? stationName) {
    return Container(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 0.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '노선 선택',
                  style: context.textStyle.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stationName != null ? "'$stationName' 정류장을 지나는 노선이에요" : '이용하실 버스 노선을 선택해주세요',
                  style: context.textStyle.bodyLarge.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: BusPulseLoading.primary(
        size: 40,
        text: '버스 노선을 불러오는 중...',
        textStyle: context.textStyle.bodyMedium.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '이 정류장을 지나는 버스 노선이 없습니다',
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '이전 단계에서 다른 정류장을 선택해 주세요',
            style: context.textStyle.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, RouteSettingViewModel vm, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '노선 정보를 불러오지 못했습니다',
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: context.textStyle.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => vm.retry(),
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList(List<BusRouteModel> routes) {
    final colorScheme = Theme.of(context).colorScheme;
    final readInitProvider = context.read<InitProvider>();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: routes.length,
      itemBuilder: (context, index) => _buildRouteItem(routes[index], colorScheme, readInitProvider),
    );
  }

  // 한 줄 행: [노선번호 배지] 종점 방면 / 버스종류 ›
  Widget _buildRouteItem(BusRouteModel item, ColorScheme colorScheme, InitProvider readInitProvider) {
    final busColor = BusColor().setColor(item.routeTypeCd);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () {
        readInitProvider.setSelectedRouteModel(item);
        readInitProvider.nextAccountView();
      },
      child: Row(
        children: [
          // 노선번호 배지 (노선색은 여기만)
          Container(
            constraints: const BoxConstraints(minWidth: 72),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: busColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.inner),
              border: Border.all(color: busColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              item.routeName,
              style: context.textStyle.titleLarge.copyWith(
                color: busColor,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.routeDestName} 방면',
                  style: context.textStyle.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.routeTypeName,
                  style: context.textStyle.caption.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
