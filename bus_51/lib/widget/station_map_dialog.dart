import 'dart:async';

import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/widget/bus_pulse_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

// --------------------------------------------------
// Station Map Dialog
// --------------------------------------------------
class StationMapDialog extends StatefulWidget {
  final BusStationModel station;
  
  const StationMapDialog({
    super.key,
    required this.station,
  });

  @override
  State<StationMapDialog> createState() => _StationMapDialogState();
}

class _StationMapDialogState extends State<StationMapDialog> 
    with TickerProviderStateMixin {
  
  // Animation constants
  static const Duration _fadeDuration = Duration(milliseconds: 600);
  static const Duration _scaleDuration = Duration(milliseconds: 400);
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Map controller
  NaverMapController? _mapController;
  NMarker? _stationMarker;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(duration: _fadeDuration, vsync: this);
    _scaleController = AnimationController(duration: _scaleDuration, vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog.fullscreen(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.secondary.withValues(alpha: 0.03),
                colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              _buildAppBar(colorScheme),
              Expanded(child: _buildMapContent(colorScheme)),
              _buildActionButtons(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.station.stationName,
            style: context.textStyle.headlineSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMapContent(ColorScheme colorScheme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              NaverMap(
                onMapReady: _onMapReady,
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: NLatLng(widget.station.y, widget.station.x),
                    zoom: 18,
                  ),
                  mapType: NMapType.basic,
                  activeLayerGroups: [NLayerGroup.building, NLayerGroup.transit],
                ),
              ),
              if (!_isMapReady)
                Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: BusPulseLoading.primary(
                      size: 40,
                      text: '지도를 불러오는 중...',
                      textStyle: context.textStyle.bodyMedium.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(
                  Icons.close,
                  size: 20,
                ),
                label: Text(
                  '취소',
                  style: context.textStyle.labelLarge,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: colorScheme.outline,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: colorScheme.onPrimary,
                ),
                label: Text(
                  '이 정류장 선택',
                  style: context.textStyle.labelLarge.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimary,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapReady(NaverMapController controller) async {
    _mapController = controller;
    
    // 정류장 마커 생성
    _stationMarker = NMarker(
      id: 'station_${widget.station.stationId}',
      position: NLatLng(widget.station.y, widget.station.x),
    );
    
    // 마커 스타일 설정 - 단순하고 깔끔한 원형 마커
    final colorScheme = Theme.of(context).colorScheme;
    final markerIcon = await NOverlayImage.fromWidget(
      widget: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.all(6),
          child: Icon(
            Icons.location_on,
            color: colorScheme.primary,
            size: 16,
          ),
        ),
      ),
      size: const Size(36, 36),
      context: context,
    );
    
    _stationMarker!.setIcon(markerIcon);
    _stationMarker!.setCaption(NOverlayCaption(
      text: widget.station.stationName,
      color: colorScheme.onSurface,
      haloColor: Colors.white,
      textSize: 12,
    ));
    
    // 지도에 마커 추가
    await controller.addOverlay(_stationMarker!);
    
    setState(() {
      _isMapReady = true;
    });
  }
}