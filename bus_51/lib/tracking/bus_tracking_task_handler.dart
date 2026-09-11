import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/service/bus_api_service.dart';
import 'package:bus_51/tracking/bus_notifications.dart';
import 'package:bus_51/tracking/bus_tracker.dart';
import 'package:bus_51/tracking/bus_tracking_service.dart';
import 'package:bus_51/tracking/bus_tracking_target.dart';
import 'package:bus_51/utils/arrival_time.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// --------------------------------------------------
// 포그라운드 서비스 isolate 진입점
// 앱과 다른 isolate 라 GetIt·Provider 가 없다. 여기서 API 서비스·Repository 를 직접 만들어
// 기존 파싱 코드를 그대로 쓴다. 판정은 전부 BusTracker 에 맡기고 이 파일은 얇게 유지한다
// --------------------------------------------------

@pragma('vm:entry-point')
void startBusTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(BusTrackingTaskHandler());
}

class BusTrackingTaskHandler extends TaskHandler {
  BusTracker? _tracker;
  BusTrackingTarget? _target;

  /// 내가 추적 중인 대상의 저장 문자열 원본. 저장소의 값과 비교해 "아직 내 것인가"를 판단한다
  String? _targetJson;

  late final BusArrivalRepository _repository;

  /// 마지막으로 알림에 쓴 제목. 같으면 갱신하지 않는다 (분이 바뀔 때만 갱신)
  String? _lastTitle;

  /// 조회 요청이 나가 있는 동안 또 나가지 않도록
  bool _polling = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _repository = BusArrivalRepository(BusApiService());
    await initBusNotifications();

    final json = await FlutterForegroundTask.getData<String>(key: BusTrackingTarget.storageKey);
    if (json == null) {
      await FlutterForegroundTask.stopService();
      return;
    }
    _applyTarget(json);

    // 시스템이 서비스를 죽였다 되살린 경우 저장된 남은 시간이 오래됐으므로 바로 한 번 보정한다
    if (starter == TaskStarter.system) await _poll();
    await _updateOngoingNotification();
  }

  /// 앱 → 서비스: 다른 버스에서 알림을 켰다. 서비스는 그대로 두고 추적 대상만 갈아끼운다 (동시 추적 1건).
  /// 새 대상은 화면이 방금 받은 차량번호·남은 초를 들고 오므로 바로 조회하지 않고 다음 주기를 기다린다
  @override
  void onReceiveData(Object data) {
    if (data is! String) return;
    _applyTarget(data);
    _updateOngoingNotification();
  }

  /// 저장 문자열로 추적 대상·tracker 를 새로 만든다. 알림 제목도 새로 그리도록 마지막 제목 기억을 지운다
  void _applyTarget(String json) {
    final target = BusTrackingTarget.decode(json);
    _targetJson = json;
    _target = target;
    _tracker = BusTracker(
      routeName: target.routeName,
      plateNo: target.plateNo,
      remainingSeconds: target.remainingSeconds,
    );
    _lastTitle = null;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final tracker = _tracker;
    if (tracker == null) return;

    final alarmMinutes = tracker.tick();
    if (alarmMinutes != null) showArrivalAlarm(tracker.alarmTitle(alarmMinutes));

    if (tracker.isFinished) {
      _finish();
      return;
    }
    _updateOngoingNotification();
    if (tracker.isPollDue && !_polling) _poll();
  }

  Future<void> _poll() async {
    final tracker = _tracker;
    final target = _target;
    if (tracker == null || target == null) return;

    _polling = true;
    try {
      final arrival = await _repository.getArrival(
        stationId: target.stationId.toString(),
        routeId: target.routeId.toString(),
        staOrder: target.staOrder.toString(),
      );
      // 응답을 기다리는 사이 다른 버스로 교체됐으면 이 결과는 이전 버스 것이라 버린다
      if (_tracker != tracker) return;

      // 운행 차량이 없으면(null) 차량번호가 "" 로 들어가 "차량 변경"으로 끝난다
      tracker.applyArrival(
        plateNo: arrival?.plateNo1 ?? '',
        remainingSeconds: arrival == null ? 0 : arrivalSeconds(sec: arrival.predictTimeSec1, min: arrival.predictTime1),
      );
      if (tracker.isFinished) await _finish();
    } catch (_) {
      // 네트워크·API 오류는 무시하고 카운트다운을 이어간다
      if (_tracker == tracker) tracker.applyPollFailure();
    } finally {
      _polling = false;
    }
  }

  Future<void> _updateOngoingNotification() async {
    final tracker = _tracker;
    if (tracker == null) return;

    final title = tracker.ongoingTitle;
    if (title == _lastTitle) return;
    _lastTitle = title;
    await FlutterForegroundTask.updateService(notificationTitle: title, notificationText: '');
  }

  /// 추적 종료: 저장값을 지우고, 앱이 떠 있으면 알려 주고, 서비스를 내린다
  Future<void> _finish() async {
    if (_tracker == null) return;
    _tracker = null;
    await _releaseTarget();
    await FlutterForegroundTask.stopService();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // _finish 를 거치지 않고 내려가는 경우(앱에서 끔, 시스템 제한 시간 초과)에도 상태를 정리한다
    if (_tracker == null) return;
    _tracker = null;
    await _releaseTarget();
  }

  /// 저장된 추적 대상이 아직 내 것이면 지우고 앱에 "끝났다"고 알린다.
  /// 앱이 그새 다른 버스를 저장했거나(교체) 직접 지웠으면(앱에서 끔) 남의 것이므로 건드리지 않는다.
  /// 이 확인이 없으면 늦게 실행되는 onDestroy 가 새 추적의 저장값을 지우고 버튼까지 꺼 버린다
  Future<void> _releaseTarget() async {
    final stored = await FlutterForegroundTask.getData<String>(key: BusTrackingTarget.storageKey);
    if (stored != _targetJson) return;
    await FlutterForegroundTask.removeData(key: BusTrackingTarget.storageKey);
    FlutterForegroundTask.sendDataToMain(FlutterForegroundBusTrackingService.finishedMessage);
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == FlutterForegroundBusTrackingService.stopButtonId) _finish();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
