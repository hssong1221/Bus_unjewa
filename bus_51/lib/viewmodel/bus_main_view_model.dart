import 'dart:async';

import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/tracking/bus_tracking_service.dart';
import 'package:bus_51/tracking/bus_tracking_target.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/utils/arrival_time.dart';
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
// 전체 노선 타임라인(확장 영역) UI 상태
// --------------------------------------------------
sealed class BusTimelineState {
  const BusTimelineState();
}

/// 경유 정류장 목록 불러오는 중
class BusTimelineLoading extends BusTimelineState {
  const BusTimelineLoading();
}

/// 조회 성공
class BusTimelineSuccess extends BusTimelineState {
  const BusTimelineSuccess({
    required this.stations,
    required this.currentIndex,
  });

  /// 노선이 경유하는 전체 정류장 (stationSeq 순)
  final List<BusRouteStationModel> stations;

  /// 유저가 탑승하는 정류장의 인덱스. 찾지 못하면 -1
  final int currentIndex;
}

/// 조회 실패 (네트워크/API 오류, 정류장 정보 없음)
class BusTimelineError extends BusTimelineState {
  const BusTimelineError(this.message);

  final String message;
}

// --------------------------------------------------
// 도착 알림 버튼을 눌렀을 때의 결과. 화면은 이 값으로 토스트·다이얼로그를 고른다
// --------------------------------------------------
enum AlarmToggleResult {
  /// 추적을 시작했다
  enabled,

  /// 추적을 껐다
  disabled,

  /// 알림을 받을 수 없어 시작하지 못했다 → 공통 권한 다이얼로그
  needsPermission,

  /// 서비스가 뜨지 못했거나 켤 수 있는 상태가 아니다
  failed,
}

// --------------------------------------------------
// 메인 화면 ViewModel
// 도착 정보 조회, 60초 주기 자동 갱신, 도착 카운트다운,
// 전체 노선 타임라인 조회, 도착 알림 켜기/끄기를 담당한다
// --------------------------------------------------
class BusMainViewModel extends ChangeNotifier {
  BusMainViewModel(
    this._arrivalRepository,
    this._routeStationRepository,
    this._tracking, {
    required List<UserSaveModel> savedBuses,
    required int index,
  }) : userModel = (index >= 0 && index < savedBuses.length) ? savedBuses[index] : null;

  final BusArrivalRepository _arrivalRepository;
  final BusRouteStationRepository _routeStationRepository;
  final BusTrackingService _tracking;

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

  /// 최초 진입(그리고 백그라운드에서 복귀): 60초 주기 자동 갱신을 걸고 도착 정보를 조회하며,
  /// 도착 알림 버튼 상태를 서비스 실행 여부와 맞춘다
  Future<void> init() async {
    if (userModel == null) {
      _state = const BusMainError('저장된 버스 정보를 찾을 수 없습니다');
      notifyListeners();
      return;
    }
    // 타이머를 먼저 걸어야 응답을 기다리는 사이 pause() 가 불려도 타이머가 살아남지 않는다
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _fetchArrival());
    _trackingFinished ??= _tracking.onFinished.listen((_) => _onTrackingFinished());
    await Future.wait([_fetchArrival(), _syncAlarmState()]);
  }

  /// 앱이 백그라운드로 가면 자동 갱신·카운트다운 정지 (보지 않는 화면에 API 를 쓰지 않는다)
  void pause() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// 다시 보일 때 바로 조회하고 자동 갱신 재개
  Future<void> resume() => init();

  /// 수동 새로고침 (당겨서 새로고침, 재시도 버튼)
  Future<void> refresh() => _fetchArrival();

  Future<void> _fetchArrival() async {
    final user = userModel;
    if (user == null) return;

    try {
      final arrival = await _arrivalRepository.getArrival(
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
          arrivalSeconds(sec: arrival.predictTimeSec1, min: arrival.predictTime1),
          arrivalSeconds(sec: arrival.predictTimeSec2, min: arrival.predictTime2),
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

  // ----- 도착 알림 -----

  bool _alarmEnabled = false;
  bool get alarmEnabled => _alarmEnabled;

  StreamSubscription<void>? _trackingFinished;

  /// 남은 시간이 1분 미만이면 울릴 시점(10·5·3·1분 전)이 없으므로 켤 수 없다.
  /// 이미 켜진 알림은 남은 시간과 상관없이 끌 수 있다
  bool get canToggleAlarm => _alarmEnabled || _remainingSeconds1 >= 60;

  /// 도착 알림을 켜거나 끈다.
  /// 켤 때: 알림 권한 확인 → 지금 보는 버스(차량번호·남은 초)로 서비스 시작
  Future<AlarmToggleResult> toggleAlarm() async {
    if (_alarmEnabled) {
      await _tracking.stop();
      _alarmEnabled = false;
      notifyListeners();
      return AlarmToggleResult.disabled;
    }

    final user = userModel;
    final state = _state;
    if (user == null || state is! BusMainSuccess || !canToggleAlarm) return AlarmToggleResult.failed;

    if (!await _tracking.ensureNotificationsAllowed()) return AlarmToggleResult.needsPermission;

    final started = await _tracking.start(BusTrackingTarget(
      stationId: user.stationId,
      routeId: user.routeId,
      staOrder: user.staOrder,
      routeName: user.routeName,
      plateNo: state.arrival.plateNo1,
      remainingSeconds: _remainingSeconds1,
    ));
    if (!started) return AlarmToggleResult.failed;

    _alarmEnabled = true;
    notifyListeners();
    return AlarmToggleResult.enabled;
  }

  /// 권한 다이얼로그의 "설정 열기"
  Future<void> openNotificationSettings() => _tracking.openNotificationSettings();

  /// 화면에 들어오거나 복귀할 때: 서비스가 이 버스를 추적 중이면 켜진 상태로 그린다
  /// (앱이 꺼진 사이 서비스가 스스로 끝났으면 여기서 꺼진 상태가 된다)
  Future<void> _syncAlarmState() async {
    final user = userModel;
    if (user == null) return;

    final target = await _tracking.currentTarget();
    final enabled = target != null &&
        target.isSameBus(stationId: user.stationId, routeId: user.routeId, staOrder: user.staOrder);
    if (enabled == _alarmEnabled) return;
    _alarmEnabled = enabled;
    notifyListeners();
  }

  /// 앱이 떠 있는 동안 서비스가 스스로 끝났다 (도착·차량 변경·90분·알림의 "끄기")
  void _onTrackingFinished() {
    if (!_alarmEnabled) return;
    _alarmEnabled = false;
    notifyListeners();
  }

  // ----- 전체 노선 타임라인 -----

  BusTimelineState _timelineState = const BusTimelineLoading();
  BusTimelineState get timelineState => _timelineState;

  bool _isLoadingTimeline = false;

  /// 전체 노선 보기를 펼칠 때 호출.
  /// 노선의 정류장 목록은 바뀌지 않으므로 한 번 성공하면 다시 조회하지 않는다
  Future<void> loadTimeline() async {
    final user = userModel;
    if (user == null || _isLoadingTimeline || _timelineState is BusTimelineSuccess) return;

    _isLoadingTimeline = true;
    _timelineState = const BusTimelineLoading();
    notifyListeners();

    try {
      final stations = await _routeStationRepository.getStationsOnRoute(
        routeId: user.routeId.toString(),
      );

      if (stations.isEmpty) {
        _timelineState = const BusTimelineError('노선 정류장 정보가 없습니다');
      } else {
        _timelineState = BusTimelineSuccess(
          stations: stations,
          // 저장된 staOrder 는 탑승 정류장의 stationSeq 와 같은 값이다
          currentIndex: stations.indexWhere((s) => s.stationSeq == user.staOrder.toString()),
        );
      }
    } on ApiException catch (e) {
      _timelineState = BusTimelineError(e.message ?? e.error ?? '노선 정보를 불러오지 못했습니다');
    } catch (e) {
      // 공공 API 응답 형태가 일정하지 않아 파싱 오류 가능성이 있음
      _timelineState = const BusTimelineError('노선 정보를 불러오지 못했습니다');
    }

    _isLoadingTimeline = false;
    notifyListeners();
  }

  @override
  void dispose() {
    pause();
    _trackingFinished?.cancel();
    super.dispose();
  }
}
