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
    final target = BusTrackingTarget.decode(json);
    _target = target;
    _tracker = BusTracker(
      routeName: target.routeName,
      plateNo: target.plateNo,
      remainingSeconds: target.remainingSeconds,
    );

    // 시스템이 서비스를 죽였다 되살린 경우 저장된 남은 시간이 오래됐으므로 바로 한 번 보정한다
    if (starter == TaskStarter.system) await _poll();
    await _updateOngoingNotification();
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
      // 운행 차량이 없으면(null) 차량번호가 "" 로 들어가 "차량 변경"으로 끝난다
      tracker.applyArrival(
        plateNo: arrival?.plateNo1 ?? '',
        remainingSeconds: arrival == null ? 0 : arrivalSeconds(sec: arrival.predictTimeSec1, min: arrival.predictTime1),
      );
      if (tracker.isFinished) await _finish();
    } catch (_) {
      // 네트워크·API 오류는 무시하고 카운트다운을 이어간다
      tracker.applyPollFailure();
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
    await FlutterForegroundTask.removeData(key: BusTrackingTarget.storageKey);
    FlutterForegroundTask.sendDataToMain(FlutterForegroundBusTrackingService.finishedMessage);
    await FlutterForegroundTask.stopService();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // _finish 를 거치지 않고 내려가는 경우(앱에서 끔, 시스템 제한 시간 초과)에도 상태를 정리한다
    if (_tracker == null) return;
    _tracker = null;
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
