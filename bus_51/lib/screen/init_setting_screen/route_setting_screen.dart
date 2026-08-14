import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/repository/bus_route_repository.dart';
import 'package:bus_51/theme/app_background.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/viewmodel/route_setting_view_model.dart';
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

class _RouteSettingBodyState extends State<_RouteSettingBody> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
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
    final vm = context.watch<RouteSettingViewModel>();
    final stationName = context.watch<InitProvider>().selectedStationModel?.stationName;

    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration(colorScheme),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
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
                  '버스 노선 선택',
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
      itemBuilder: (context, index) {
        var item = routes[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0.0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildRouteItem(item, colorScheme, readInitProvider),
        );
      },
    );
  }

  Widget _buildRouteItem(BusRouteModel item, ColorScheme colorScheme, readInitProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            readInitProvider.setSelectedRouteModel(item);
            readInitProvider.nextAccountView();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 노선번호 + 버스종류
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 노선번호
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: BusColor().setColor(item.routeTypeCd).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: BusColor().setColor(item.routeTypeCd).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.routeName,
                          style: context.textStyle.headlineSmall.copyWith(
                            color: BusColor().setColor(item.routeTypeCd),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 버스종류
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          item.routeTypeName,
                          style: context.textStyle.caption.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 목적지 방향
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.routeDestName,
                          style: context.textStyle.subtitle.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
