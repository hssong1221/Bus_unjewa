import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get_it/get_it.dart';

class FNMapPage extends StatefulWidget {
  const FNMapPage({
    Key? key,
  }) : super(key: key);

  @override
  State<FNMapPage> createState() => _FNMapPageState();
}

class _FNMapPageState extends State<FNMapPage> {
  late NaverMapController mapController;
  final _onCameraChangeStreamController = StreamController<NCameraUpdateReason>.broadcast();
  final _mapKey = UniqueKey();

  /* ----- Events ----- */

  void onMapReady(NaverMapController controller) {
    mapController = controller;
    GetIt.I.registerSingleton(controller);
  }

  void onMapTapped(NPoint point, NLatLng latLng) async {
    // ...
  }

  void onSymbolTapped(NSymbolInfo symbolInfo) {
    // ...
  }

  void onCameraChange(NCameraUpdateReason reason, bool isGesture) {
    // ...
    _onCameraChangeStreamController.sink.add(reason);
  }

  void onCameraIdle() {
    // ...
  }

  void onSelectedIndoorChanged(NSelectedIndoor? selectedIndoor) {
    // ...
  }

  NOverlayImage? clusterIcon;

  @override
  void initState() {
    GetIt.I.registerLazySingleton<Stream<NCameraUpdateReason>>(() => _onCameraChangeStreamController.stream);
    //GetIt.I.registerLazySingleton(() => nOverlayInfoOverlayPortalController);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // 고정된 이미지라면, NOverlayImage.fromAsset 혹은 NOverlayImage.fromFile 을 사용하는 것이 좋습니다.
      // fromWidget은 비용이 비싸기 때문에, 되도록 사용하지 않되, 사용할 경우 미리 생성해둔 하나의 객체를 사용하는 것이 좋습니다.
      // 예제에서는, 패키지의 용량을 줄이기 위해 이렇게 생성합니다.
      NOverlayImage.fromWidget(widget: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)), size: const Size(40, 40), context: context).then((value) {
        clusterIcon = value;
      });
    });
  }

  /* ----- UI Size ----- */
  double drawerHeight = 0;
  double? initMainDrawerHeight;

  //final nOverlayInfoOverlayPortalController = NInfoOverlayPortalController();
  //DrawerMoveController? drawerController;
  final drawerKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox.expand(
      child: Stack(children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 150),
          left: 0,
          right: 0,
          top: 0,
          bottom: drawerHeight - _drawerHandleHeight,
          child: NaverMap(
            key: _mapKey,
            clusterOptions: NaverMapClusteringOptions(
                mergeStrategy: const NClusterMergeStrategy(
                  willMergedScreenDistance: {
                    NaverMapClusteringOptions.defaultClusteringZoomRange: 35,
                  },
                ),
                clusterMarkerBuilder: (info, clusterMarker) {
                  print("[flutter] clusterMarkerBuilder: $info");
                  if (clusterIcon != null) clusterMarker.setIcon(clusterIcon!);
                  clusterMarker.setIsFlat(true);
                  clusterMarker.setCaption(NOverlayCaption(text: info.size.toString(), color: Colors.white, haloColor: Colors.blueAccent));
                }),
            onMapReady: onMapReady,
            onMapTapped: onMapTapped,
            onSymbolTapped: onSymbolTapped,
            onCameraChange: onCameraChange,
            onCameraIdle: onCameraIdle,
            onSelectedIndoorChanged: onSelectedIndoorChanged,
          ),
        ),
      ]),
    ));
  }

  static const _drawerHandleHeight = 20.0;
}
