import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/repository/bus_route_repository.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:flutter/foundation.dart';

// --------------------------------------------------
// 노선 선택 화면 UI 상태
// UI는 이 sealed class 를 switch 해서 화면을 분기한다
// --------------------------------------------------
sealed class RouteSettingState {
  const RouteSettingState();
}

/// 노선 목록 불러오는 중
class RouteSettingLoading extends RouteSettingState {
  const RouteSettingLoading();
}

/// 노선 목록 조회 성공
class RouteSettingSuccess extends RouteSettingState {
  const RouteSettingSuccess(this.routes);

  final List<BusRouteModel> routes;
}

/// 이 정류장을 경유하는 노선 없음
class RouteSettingEmpty extends RouteSettingState {
  const RouteSettingEmpty();
}

/// 조회 실패 (네트워크/API 오류, 정류장 정보 없음)
class RouteSettingError extends RouteSettingState {
  const RouteSettingError(this.message);

  final String message;
}

// --------------------------------------------------
// 노선 선택 화면 ViewModel
// 온보딩 전체와 수명이 같다 (InitSettingScreen 에서 제공). 화면 위젯은 뒤로 갔다 오면
// 새로 만들어지지만 이 객체는 남아 있으므로, 같은 정류장이면 받아둔 노선을 그대로 보여준다
// --------------------------------------------------
class RouteSettingViewModel extends ChangeNotifier {
  RouteSettingViewModel(this._repository);

  final BusRouteRepository _repository;

  /// 지금 [state] 가 어느 정류장 기준인지. 아직 한 번도 조회하지 않았으면 null
  String? _stationId;

  RouteSettingState _state = const RouteSettingLoading();
  RouteSettingState get state => _state;

  /// 화면에 들어올 때마다 호출. 같은 정류장을 이미 받아뒀으면(조회 진행 중 포함) 다시 부르지 않고,
  /// 정류장이 바뀌었거나 지난 조회가 실패했으면 새로 받는다.
  ///
  /// 화면이 그려지기 직전(initState)에 불리므로 여기서는 notifyListeners 를 하지 않는다.
  /// 곧 이어지는 build 가 바뀐 상태를 읽고, 응답이 오면 그때 알린다
  Future<void> load({required String? stationId}) {
    if (stationId == null) {
      _stationId = null;
      _state = const RouteSettingError('선택된 정류장 정보가 없습니다');
      return Future.value();
    }
    if (stationId == _stationId && _state is! RouteSettingError) return Future.value();

    _stationId = stationId;
    _state = const RouteSettingLoading();
    return _fetchRoutes(stationId);
  }

  /// 실패 후 다시 시도. 정류장이 없어서 난 에러는 다시 시도할 것이 없다
  Future<void> retry() async {
    final id = _stationId;
    if (id == null) return;
    _state = const RouteSettingLoading();
    notifyListeners();
    await _fetchRoutes(id);
  }

  Future<void> _fetchRoutes(String stationId) async {
    RouteSettingState result;
    try {
      final routes = await _repository.getRoutesThroughStation(stationId: stationId);
      result = routes.isEmpty ? const RouteSettingEmpty() : RouteSettingSuccess(routes);
    } on ApiException catch (e) {
      result = RouteSettingError(e.message ?? e.error ?? '노선 정보를 불러오지 못했습니다');
    } catch (e) {
      // 공공 API 응답 형태가 일정하지 않아 파싱 오류 가능성이 있음
      result = const RouteSettingError('노선 정보를 불러오지 못했습니다');
    }

    // 기다리는 사이 뒤로 가서 다른 정류장을 골랐으면 늦게 온 이 응답은 버린다
    if (stationId != _stationId) return;
    _state = result;
    notifyListeners();
  }
}
