import 'dart:math';

import 'package:bus_51/utils/arrival_time.dart';

// --------------------------------------------------
// 도착 알림 추적 판정 로직 (순수 Dart)
// 타이머·플러그인·API 를 모른다. 1초마다 tick(), 조회 결과가 오면 applyArrival() 을 불러 주면
// 언제 알람을 울릴지, 언제 끝낼지, 다음 조회가 언제인지, 알림 문구가 무엇인지를 돌려준다.
// 알람은 조회 시점이 아니라 이 카운트다운 기준으로 울리므로(메인 화면과 같은 방식)
// 조회 주기와 상관없이 정확한 초에 울린다. 조회는 카운트다운을 보정하는 용도다
// --------------------------------------------------

/// 추적이 끝난 이유
enum BusTrackingEndReason {
  /// 카운트다운이 0 이 됐다 (버스 도착)
  arrived,

  /// 조회 결과의 첫 버스 차량번호가 바뀌었다 (예상보다 일찍 지나갔거나 운행 종료)
  busChanged,

  /// 최대 추적 시간(90분)을 넘겼다
  timeout,
}

class BusTracker {
  BusTracker({
    required this.routeName,
    required this.plateNo,
    required int remainingSeconds,
  })  : _remainingSeconds = remainingSeconds,
        // 활성화 시점의 남은 시간보다 크거나 같은 시점은 처음부터 제외한다 (7분이면 5·3·1분만).
        // 정확히 10분 남았을 때 켜자마자 10분 알람이 울리는 것도 막는다
        _pendingAlarms = alarmMinutes.where((m) => m * 60 < remainingSeconds).toSet();

  /// 도착 몇 분 전에 울릴지 (4회)
  static const List<int> alarmMinutes = [10, 5, 3, 1];

  /// 안전장치: 이 시간이 지나면 무조건 끝낸다
  static const int maxTrackingSeconds = 90 * 60;

  /// 이보다 많이 남았으면 조회를 뜸하게 한다
  static const int _slowPollThresholdSeconds = 10 * 60;
  static const int _slowPollIntervalSeconds = 120;
  static const int _fastPollIntervalSeconds = 60;

  final String routeName;

  /// 활성화 때 기억한 첫 버스 차량번호. 조회 결과가 이것과 다르면 그 버스는 이미 지나간 것
  final String plateNo;

  int _remainingSeconds;
  int get remainingSeconds => _remainingSeconds;

  final Set<int> _pendingAlarms;

  /// 아직 울리지 않은 알람 시점(분)
  Set<int> get pendingAlarms => Set.unmodifiable(_pendingAlarms);

  int _elapsedSeconds = 0;
  int _secondsSincePoll = 0;

  BusTrackingEndReason? _endReason;

  /// null 이면 추적 중
  BusTrackingEndReason? get endReason => _endReason;
  bool get isFinished => _endReason != null;

  // ----- 카운트다운 · 알람 -----

  /// 1초가 지났다. 이번 초에 울릴 알람이 있으면 그 시점(분)을 돌려주고 없으면 null.
  /// 남은 시간이 0 이 되거나 90분이 지나면 끝난 것으로 표시한다 (그때는 알람을 울리지 않는다)
  int? tick() {
    if (isFinished) return null;

    _elapsedSeconds++;
    _secondsSincePoll++;
    if (_remainingSeconds > 0) _remainingSeconds--;

    if (_remainingSeconds <= 0) {
      _endReason = BusTrackingEndReason.arrived;
      return null;
    }
    if (_elapsedSeconds >= maxTrackingSeconds) {
      _endReason = BusTrackingEndReason.timeout;
      return null;
    }
    return _takeDueAlarm();
  }

  /// 남은 시간이 이미 지나친 알람 시점 중 가장 가까운 것 하나만 울리고, 지나친 시점은 전부 지운다.
  /// 보정으로 두 시점을 한 번에 지나쳤을 때(6분 → 2분 30초) 3분 알람 하나만 울리게 하는 규칙
  int? _takeDueAlarm() {
    final due = _pendingAlarms.where((m) => _remainingSeconds <= m * 60).toList();
    if (due.isEmpty) return null;
    _pendingAlarms.removeAll(due);
    return due.reduce(min);
  }

  // ----- 조회 -----

  /// 다음 조회까지 주기(초). 10분 초과면 120초, 이하면 60초
  int get pollIntervalSeconds =>
      _remainingSeconds > _slowPollThresholdSeconds ? _slowPollIntervalSeconds : _fastPollIntervalSeconds;

  /// 지금 조회할 때인가. 첫 조회는 시작하고 한 주기 뒤다 (켤 때 화면이 방금 받은 값으로 시작하므로)
  bool get isPollDue => !isFinished && _secondsSincePoll >= pollIntervalSeconds;

  /// 조회 결과 반영. 차량번호가 다르면 끝내고, 같으면 카운트다운만 보정한다.
  /// 이미 울린 알람은 시간이 늘어나도 다시 울리지 않는다 (_pendingAlarms 에 없으므로)
  void applyArrival({required String plateNo, required int remainingSeconds}) {
    _secondsSincePoll = 0;
    if (isFinished) return;

    if (plateNo != this.plateNo) {
      _endReason = BusTrackingEndReason.busChanged;
      return;
    }
    _remainingSeconds = remainingSeconds;
  }

  /// 조회 실패는 무시하고 카운트다운을 이어간다. 다음 주기에 다시 시도한다
  void applyPollFailure() {
    _secondsSincePoll = 0;
  }

  // ----- 알림 문구 -----

  /// "51번 버스". 이름이 숫자로 끝나지 않으면("통학1(등교)") "번"을 붙이지 않는다
  String get busLabel => RegExp(r'\d$').hasMatch(routeName) ? '$routeName번 버스' : '$routeName 버스';

  /// 고정 알림 제목: "51번 버스 · 5분 후 도착". 분은 올림이라 4분 59초도 "5분 후"다.
  /// 2분 미만이면 화면과 같이 "잠시 후 도착"
  String get ongoingTitle {
    if (isArrivingSoon(_remainingSeconds)) return '$busLabel · $kArrivingSoonLabel';
    final minutes = (_remainingSeconds + 59) ~/ 60;
    return '$busLabel · $minutes분 후 도착';
  }

  /// 알람 제목: "51번 버스가 5분 후에 도착해요"
  String alarmTitle(int minutes) => '$busLabel가 $minutes분 후에 도착해요';
}
