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
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 0.0, bottom: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                            MediaQuery.of(context).padding.top - 
                            MediaQuery.of(context).padding.bottom - 48, // SafeArea + padding
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(colorScheme),
                      _buildRouteInfoCard(colorScheme, watchBusProvider),
                      const SizedBox(height: 32),
                      _buildConfirmationInfo(colorScheme),
                      const Spacer(),
                      _buildSaveButton(colorScheme, readBusProvider),
                      const SizedBox(height: 16),
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Text(
            '설정 완료',
            style: context.textStyle.headlineMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
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
    return Container(
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
          // Route Number
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: BusColor().setColor(watchBusProvider.selectedRouteModel?.routeTypeCd ?? 0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              watchBusProvider.selectedRouteModel?.routeName ?? "버스 노선",
              style: context.textStyle.headlineMedium.copyWith(
                color: BusColor().setColor(watchBusProvider.selectedRouteModel?.routeTypeCd ?? 0),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Route Path
          Column(
            children: [
              // Previous Station
              _buildStationItem(
                context,
                watchBusProvider.prevStationModel?.stationName ?? "이전 정류장",
                colorScheme.onSurface.withValues(alpha: 0.5),
                Icons.radio_button_unchecked,
                false,
              ),
              const SizedBox(height: 16),
              // Current Station (Selected)
              _buildStationItem(
                context,
                watchBusProvider.curStationModel?.stationName ?? "선택한 정류장",
                colorScheme.primary,
                Icons.my_location,
                true,
              ),
              const SizedBox(height: 16),
              // Next Station
              _buildStationItem(
                context,
                watchBusProvider.nextStationModel?.stationName ?? "다음 정류장",
                colorScheme.onSurface.withValues(alpha: 0.5),
                Icons.radio_button_unchecked,
                false,
              ),
              const SizedBox(height: 24),
              // Dots indicating more stations
              Column(
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Destination
              _buildStationItem(
                context,
                watchBusProvider.selectedRouteModel?.routeDestName ?? "최종 목적지",
                colorScheme.secondary,
                Icons.flag,
                false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationInfo(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '방향이 맞으면 저장 버튼을 눌러주세요',
              style: context.textStyle.bodyMedium.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme colorScheme, readBusProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: () => _saveRouteData(readBusProvider),
        icon: const Icon(Icons.bookmark_add),
        label: Text('저장하고 시작하기', style: context.textStyle.buttonText),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
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
    );

    await readBusProvider.saveUserDataList(order);
    await context.pushNamed(BusListScreen.routeName);
  }

  Widget _buildStationItem(BuildContext context, String stationName, Color color, IconData icon, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: isSelected ? 24 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stationName,
              style: context.textStyle.bodyLarge.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
