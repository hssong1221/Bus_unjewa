import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/widget/bus_pulse_loading.dart';
import 'package:bus_51/widget/station_map_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// --------------------------------------------------
class StationSettingView extends StatefulWidget {
  const StationSettingView({super.key});

  @override
  State<StationSettingView> createState() => _StationSettingViewState();
}

class _StationSettingViewState extends State<StationSettingView>
    with TickerProviderStateMixin {
  // Animation constants
  static const Duration _fadeDuration = Duration(milliseconds: 800);
  static const Duration _listDuration = Duration(milliseconds: 1200);
  
  late AnimationController _fadeController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeStations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(duration: _fadeDuration, vsync: this);
    _listController = AnimationController(duration: _listDuration, vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeOutCubic),
    );
  }

  void _initializeStations() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fadeController.forward();
      await context.read<BusProvider>().getGPSData();
      await context.read<BusProvider>().getBusStationList();
      _listController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final readBusProvider = context.read<BusProvider>();
    final watchBusProvider = context.watch<BusProvider>();
    final readInitProvider = context.read<InitProvider>();

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
          child: Column(
            children: [
              _buildHeader(colorScheme, watchBusProvider),
              _buildStationList(colorScheme, watchBusProvider, readBusProvider, readInitProvider),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, watchBusProvider) {
    return Container(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 0.0, bottom: 16.0),
      child: Column(
        children: [
          // Title Bar
          Row(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "정류장 선택",
                    style: context.textStyle.headlineMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _fadeAnimation,
                child: OutlinedButton.icon(
                  onPressed: () => _refreshStations(watchBusProvider),
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    "위치 재검색",
                    style: context.textStyle.labelMedium.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status Card
          FadeTransition(
            opacity: _fadeAnimation,
            child: Card.filled(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      watchBusProvider.busStationModel == null
                          ? Icons.location_searching_rounded
                          : Icons.location_on_rounded,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      watchBusProvider.busStationModel == null
                          ? '현재 위치 500m 반경 내\n버스 정류장을 검색중입니다'
                          : '자주 이용하는 정류장을 선택해 주세요',
                      style: context.textStyle.subtitleBoldMd.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationList(ColorScheme colorScheme, watchBusProvider, readBusProvider, readInitProvider) {
    var busStationModel = watchBusProvider.busStationModel;
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            // List Header
            FadeTransition(
              opacity: _fadeAnimation,
              child: Card.filled(
                margin: const EdgeInsets.only(bottom: 4),
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_list_bulleted,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          "정류장 목록",
                          style: context.textStyle.labelLarge.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "거리순",
                          style: context.textStyle.caption.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // List Content
            Expanded(
              child: Card.outlined(
                margin: EdgeInsets.zero,
                elevation: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: busStationModel == null
                      ? _buildLoadingState(colorScheme)
                      : _buildStationListView(busStationModel, colorScheme, readBusProvider, readInitProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: BusPulseLoading.primary(
          size: 40,
          text: "정류장을 찾고 있습니다...",
          textStyle: context.textStyle.bodyMedium.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildStationListView(busStationModel, ColorScheme colorScheme, readBusProvider, readInitProvider) {
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          itemCount: busStationModel.length,
          itemBuilder: (context, index) {
            var item = busStationModel[index];
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _listAnimation.value)),
              child: Opacity(
                opacity: _listAnimation.value,
                child: Card.outlined(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final shouldSelect = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => StationMapDialog(station: item),
                      );
                      
                      if (shouldSelect == true) {
                        readBusProvider.setSelectedStationModel(item);
                        readInitProvider.nextAccountView();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Station Info (확장)
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                Text(
                                  item.stationName,
                                  style: context.textStyle.subtitle.copyWith(color: colorScheme.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "ID: ${item.mobileNo}",
                                  style: context.textStyle.caption.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Distance Info
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on_outlined, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  "${item.distance}m",
                                  style: context.textStyle.labelMedium.copyWith(color: colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _refreshStations(watchBusProvider) async {
    watchBusProvider.busStationModel = null;
    _listController.reset();
    await context.read<BusProvider>().getGPSData();
    await context.read<BusProvider>().getBusStationList();
    _listController.forward();
  }

}
