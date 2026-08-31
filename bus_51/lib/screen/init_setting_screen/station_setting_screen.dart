import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/repository/bus_station_repository.dart';
import 'package:bus_51/theme/app_background.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/viewmodel/station_setting_view_model.dart';
import 'package:bus_51/widget/bus_pulse_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// 지도에서 정류장을 직접 찾아 선택하는 화면
// 초기 카메라는 현재 위치, "이 지역에서 검색" 버튼으로 지도 중심 주변을 재검색
// --------------------------------------------------
class StationSettingView extends StatelessWidget {
  const StationSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StationSettingViewModel(GetIt.I<BusStationRepository>())..init(),
      child: const _StationMapView(),
    );
  }
}

class _StationMapView extends StatefulWidget {
  const _StationMapView();

  @override
  State<_StationMapView> createState() => _StationMapViewState();
}

class _StationMapViewState extends State<_StationMapView> {
  NaverMapController? _mapController;
  NOverlayImage? _markerIcon;
  NOverlayImage? _selectedMarkerIcon;
  bool _isMapReady = false;

  // 마지막으로 지도에 그린 정류장 리스트 (VM 리스트와 identical 비교로 갱신 감지)
  List<BusStationModel> _renderedStations = const [];

  // 검색이 연달아 실행됐을 때 이전 마커 동기화 루프를 중단시키기 위한 세대 번호
  int _markerSyncGeneration = 0;

  // 지도에 올라가 있는 마커들 (선택 하이라이트 갱신용)
  final Map<String, NMarker> _markersById = {};
  String? _highlightedStationId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<StationSettingViewModel>();
    final initialPosition = vm.initialPosition;

    _syncMarkers(vm);
    _syncSelectionHighlight(vm);

    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration(colorScheme),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(colorScheme),
              Expanded(
                child: initialPosition == null
                    ? _buildLocatingState(colorScheme)
                    : _buildMapArea(colorScheme, vm, initialPosition),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 0.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "정류장 선택",
            style: context.textStyle.headlineMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // 안내는 부제 한 줄로 — 지도 면적을 최대한 확보한다
          Text(
            '지도를 움직여 정류장을 찾고 마커를 눌러 주세요',
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLocatingState(ColorScheme colorScheme) {
    return Center(
      child: BusPulseLoading.primary(
        size: 40,
        text: "현재 위치를 확인하고 있습니다...",
        textStyle: context.textStyle.bodyMedium.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildMapArea(ColorScheme colorScheme, StationSettingViewModel vm, MapPoint initialPosition) {
    final notice = vm.noticeMessage ?? (vm.usedFallbackPosition ? '위치 권한이 없어 기본 위치를 표시합니다' : null);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: NLatLng(initialPosition.lat, initialPosition.lng),
                    // 검색 반경 500m에 맞는 축척
                    zoom: 16,
                  ),
                  mapType: NMapType.basic,
                  activeLayerGroups: const [NLayerGroup.building, NLayerGroup.transit],
                  locationButtonEnable: true,
                ),
                onMapReady: _onMapReady,
                onMapTapped: (point, latLng) => context.read<StationSettingViewModel>().clearSelection(),
              ),
            ),
            if (!_isMapReady)
              Positioned.fill(
                child: Container(
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
              ),
            // 상단 중앙: 이 지역에서 검색 버튼
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(child: _buildSearchButton(colorScheme, vm)),
            ),
            // 안내 칩 (검색 실패/빈 결과/기본 위치)
            if (notice != null)
              Positioned(
                top: 64,
                left: 0,
                right: 0,
                child: Center(child: _buildNoticeChip(colorScheme, notice)),
              ),
            // 하단: 선택한 정류장 확인 카드
            if (vm.selectedStation != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _buildSelectionCard(colorScheme, vm.selectedStation!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton(ColorScheme colorScheme, StationSettingViewModel vm) {
    return FilledButton.icon(
      onPressed: vm.isSearching ? null : _searchThisArea,
      icon: vm.isSearching
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.refresh_rounded, size: 18),
      label: Text(
        vm.isSearching ? '검색 중...' : '이 지역에서 검색',
        style: context.textStyle.labelLarge.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: FilledButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildNoticeChip(ColorScheme colorScheme, String notice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        notice,
        style: context.textStyle.caption.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
    );
  }

  Widget _buildSelectionCard(ColorScheme colorScheme, BusStationModel station) {
    return Card(
      elevation: 4,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.stationName,
                        style: context.textStyle.subtitle.copyWith(color: colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "ID: ${station.mobileNo}",
                        style: context.textStyle.caption.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _confirmStation(station),
                icon: const Icon(Icons.check_circle, size: 20),
                label: Text(
                  '이 정류장 선택',
                  style: context.textStyle.labelLarge.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapReady(NaverMapController controller) {
    _mapController = controller;
    final vm = context.read<StationSettingViewModel>();
    // 현위치 오버레이 표시 (카메라는 따라가지 않음). 위치 권한이 없으면 생략
    if (!vm.usedFallbackPosition) {
      controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
    }
    setState(() {
      _isMapReady = true;
    });
    _syncMarkers(vm);
  }

  // "이 지역에서 검색": 지도 중심 좌표 기준으로 재검색
  Future<void> _searchThisArea() async {
    final controller = _mapController;
    if (controller == null) return;
    final vm = context.read<StationSettingViewModel>();
    final cameraPosition = await controller.getCameraPosition();
    await vm.searchAround((
      lat: cameraPosition.target.latitude,
      lng: cameraPosition.target.longitude,
    ));
  }

  // VM의 정류장 리스트가 바뀌면 지도 마커를 다시 그린다
  Future<void> _syncMarkers(StationSettingViewModel vm) async {
    final controller = _mapController;
    if (controller == null || identical(_renderedStations, vm.stations)) return;
    final stations = vm.stations;
    _renderedStations = stations;
    final generation = ++_markerSyncGeneration;
    final colorScheme = Theme.of(context).colorScheme;

    if (_markerIcon == null || _selectedMarkerIcon == null) {
      final normalIconFuture = _buildMarkerIcon(colorScheme, selected: false);
      final selectedIconFuture = _buildMarkerIcon(colorScheme, selected: true);
      _markerIcon = await normalIconFuture;
      _selectedMarkerIcon = await selectedIconFuture;
    }

    // 아이콘 생성 사이에 새 검색이 끝났으면 이 루프는 중단 (최신 세대가 다시 그림)
    if (generation != _markerSyncGeneration) return;

    // 위치 오버레이(현위치 파란 점)는 남기고 마커만 지운다
    await controller.clearOverlays(type: NOverlayType.marker);
    _markersById.clear();
    _highlightedStationId = null;

    for (final station in stations) {
      if (generation != _markerSyncGeneration) return;

      final lat = double.tryParse(station.y);
      final lng = double.tryParse(station.x);
      if (lat == null || lng == null) continue;

      final marker = NMarker(
        id: 'station_${station.stationId}',
        position: NLatLng(lat, lng),
      );
      marker.setIcon(_markerIcon!);
      marker.setCaption(NOverlayCaption(
        text: _captionText(station.stationName),
        color: colorScheme.onSurface,
        haloColor: Colors.white,
        textSize: 12,
      ));
      marker.setOnTapListener((_) => vm.selectStation(station));
      _markersById[station.stationId] = marker;
      await controller.addOverlay(marker);
    }
  }

  Future<NOverlayImage> _buildMarkerIcon(ColorScheme colorScheme, {required bool selected}) {
    final size = selected ? 44.0 : 36.0;
    return NOverlayImage.fromWidget(
      widget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: selected
            ? const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 22,
              )
            : Container(
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
      size: Size(size, size),
      context: context,
    );
  }

  // 선택된 정류장의 마커를 강조 아이콘으로 교체한다
  void _syncSelectionHighlight(StationSettingViewModel vm) {
    final selectedId = vm.selectedStation?.stationId;
    if (selectedId == _highlightedStationId) return;
    if (_markerIcon == null || _selectedMarkerIcon == null) return;

    _markersById[_highlightedStationId]?.setIcon(_markerIcon!);
    final selectedMarker = _markersById[selectedId];
    selectedMarker?.setIcon(_selectedMarkerIcon!);
    _highlightedStationId = selectedMarker != null ? selectedId : null;
  }

  // 긴 정류장 이름은 캡션에서 말줄임 (전체 이름은 선택 카드에 표시됨)
  String _captionText(String name) {
    const maxLength = 10;
    return name.length > maxLength ? '${name.substring(0, maxLength)}…' : name;
  }

  void _confirmStation(BusStationModel station) {
    context.read<InitProvider>()
      ..setSelectedStationModel(station)
      ..nextAccountView();
  }
}
