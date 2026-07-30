import 'dart:async';

import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:flutter/foundation.dart';

// --------------------------------------------------
// 메인 화면(도착 정보) UI 상태
// UI는 이 sealed class 를 switch 해서 화면을 분기한다
// --------------------------------------------------
sealed class BusMainState {
  const BusMainState();
}

/// 도착 정보 불러오는 중
class BusMainLoading extends BusMainState {
  const BusMainLoading();
}

/// 도착 정보 조회 성공
class BusMainSuccess extends BusMainState {
  const BusMainSuccess(this.arrival);

  final BusArrivalModel arrival;
}

/// 정류장으로 오고 있는 버스 없음 (미운행/운행종료)
class BusMainNotOperating extends BusMainState {
  const BusMainNotOperating();
}

/// 조회 실패 (네트워크/API 오류, 저장 데이터 없음)
class BusMainError extends BusMainState {
  const BusMainError(this.message);

  final String message;
}

// --------------------------------------------------
// 메인 화면 ViewModel
// 도착 정보 조회, 60초 주기 자동 갱신, 도착 카운트다운을 담당한다
// --------------------------------------------------
class BusMainViewModel extends ChangeNotifier {
  BusMainViewModel(
    this._repository, {
    required List<UserSaveModel> savedBuses,
    required int index,
  }) : userModel = (index >= 0 && index < savedBuses.length) ? savedBuses[index] : null;

  final BusArrivalRepository _repository;

  /// 화면에 표시할 저장된 버스. null 이면 잘못된 진입(저장 데이터 없음)
  final UserSaveModel? userModel;

  BusMainState _state = const BusMainLoading();
  BusMainState get state => _state;

  // 도착 예정 카운트다운 (초)
  int _remainingSeconds1 = 0;
  int _remainingSeconds2 = 0;
  int get remainingSeconds1 => _remainingSeconds1;
  int get remainingSeconds2 => _remainingSeconds2;

  Timer? _refreshTimer;
  Timer? _countdownTimer;

  static const Duration _refreshInterval = Duration(seconds: 60);

  /// 최초 진입: 도착 정보 조회 후 60초 주기 자동 갱신 시작
  Future<void> init() async {
    if (userModel == null) {
      _state = const BusMainError('저장된 버스 정보를 찾을 수 없습니다');
      notifyListeners();
      return;
    }
    await _fetchArrival();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _fetchArrival());
  }

  /// 수동 새로고침 (당겨서 새로고침, 재시도 버튼)
  Future<void> refresh() => _fetchArrival();

  Future<void> _fetchArrival() async {
    final user = userModel;
    if (user == null) return;

    try {
      final arrival = await _repository.getArrival(
        stationId: user.stationId.toString(),
        routeId: user.routeId.toString(),
        staOrder: user.staOrder.toString(),
      );

      if (arrival == null) {
        _state = const BusMainNotOperating();
        _stopCountdown();
      } else {
        _state = BusMainSuccess(arrival);
        _startCountdown(
          int.tryParse(arrival.predictTimeSec1) ?? 0,
          int.tryParse(arrival.predictTimeSec2) ?? 0,
        );
      }
    } on ApiException catch (e) {
      _state = BusMainError(e.message ?? e.error ?? '버스 정보를 불러오지 못했습니다');
      _stopCountdown();
    } catch (e) {
      // 공공 API 응답 형태가 일정하지 않아 파싱 오류 가능성이 있음
      _state = const BusMainError('버스 정보를 불러오지 못했습니다');
      _stopCountdown();
    }
    notifyListeners();
  }

  void _startCountdown(int seconds1, int seconds2) {
    _remainingSeconds1 = seconds1;
    _remainingSeconds2 = seconds2;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds1 > 0) _remainingSeconds1--;
      if (_remainingSeconds2 > 0) _remainingSeconds2--;
      notifyListeners();
      if (_remainingSeconds1 <= 0 && _remainingSeconds2 <= 0) {
        timer.cancel();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _remainingSeconds1 = 0;
    _remainingSeconds2 = 0;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
