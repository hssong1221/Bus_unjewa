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
// --------------------------------------------------
class RouteSettingViewModel extends ChangeNotifier {
  RouteSettingViewModel(
    this._repository, {
    required this.stationId,
  });

  final BusRouteRepository _repository;

  /// 이전 단계에서 선택한 정류장 id. null이면 잘못된 진입
  final String? stationId;

  RouteSettingState _state = const RouteSettingLoading();
  RouteSettingState get state => _state;

  Future<void> init() => _fetchRoutes();

  /// 실패 후 다시 시도
  Future<void> retry() async {
    _state = const RouteSettingLoading();
    notifyListeners();
    await _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    final id = stationId;
    if (id == null) {
      _state = const RouteSettingError('선택된 정류장 정보가 없습니다');
      notifyListeners();
      return;
    }

    try {
      final routes = await _repository.getRoutesThroughStation(stationId: id);
      _state = routes.isEmpty ? const RouteSettingEmpty() : RouteSettingSuccess(routes);
    } on ApiException catch (e) {
      _state = RouteSettingError(e.message ?? e.error ?? '노선 정보를 불러오지 못했습니다');
    } catch (e) {
      // 공공 API 응답 형태가 일정하지 않아 파싱 오류 가능성이 있음
      _state = const RouteSettingError('노선 정보를 불러오지 못했습니다');
    }
    notifyListeners();
  }
}
