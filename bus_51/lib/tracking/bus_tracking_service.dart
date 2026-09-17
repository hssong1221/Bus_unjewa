import 'dart:async';

import 'package:bus_51/tracking/bus_notifications.dart';
import 'package:bus_51/tracking/bus_tracker.dart';
import 'package:bus_51/tracking/bus_tracking_target.dart';
import 'package:bus_51/tracking/bus_tracking_task_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// --------------------------------------------------
// 도착 알림 추적 파사드 (UI 쪽)
// 뷰모델은 이 인터페이스만 보고, 플러그인 호출은 구현체에 모아 둔다. 테스트에서는 fake 로 바꾼다
// --------------------------------------------------
abstract class BusTrackingService {
  /// 알림을 띄울 수 있는 상태로 만든다. 필요하면 시스템 권한 팝업을 띄운다.
  /// false 면 사용자가 설정에서 직접 켜야 한다 → 공통 권한 다이얼로그
  Future<bool> ensureNotificationsAllowed();

  /// 이 앱의 알림 설정 화면을 연다 (권한 다이얼로그의 "설정 열기")
  Future<void> openNotificationSettings();

  /// 추적 시작. 이미 다른 버스를 추적 중이면 그 서비스의 추적 대상만 이 버스로 갈아끼운다 (동시 추적 1건).
  /// 교체는 여기서 처리하므로 뷰모델은 stop() 을 먼저 부르지 않는다. 서비스가 뜨지 못하면 false
  Future<bool> start(BusTrackingTarget target);

  /// 추적 중지 (앱의 버튼으로 끌 때)
  Future<void> stop();

  /// 지금 추적 중인 대상. 서비스가 돌고 있지 않으면 null
  Future<BusTrackingTarget?> currentTarget();

  /// 서비스가 스스로 끝났을 때(도착·차량 변경·90분·알림의 "끄기") 앱이 떠 있으면 여기로 알려 준다
  Stream<void> get onFinished;
}

// --------------------------------------------------
// flutter_foreground_task 구현체
// --------------------------------------------------
class FlutterForegroundBusTrackingService implements BusTrackingService {
  FlutterForegroundBusTrackingService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: kTrackingChannelId,
        channelName: kTrackingChannelName,
        channelDescription: kTrackingChannelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // 남은 시간 갱신 때마다 알림이 다시 울리지 않도록
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        // 1초마다 onRepeatEvent → BusTracker.tick()
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  /// 서비스 → 앱: 추적이 끝났다
  static const String finishedMessage = 'bus_tracking_finished';

  /// 고정 알림의 "끄기" 버튼 id
  static const String stopButtonId = 'stop';

  final StreamController<void> _finished = StreamController<void>.broadcast();

  @override
  Stream<void> get onFinished => _finished.stream;

  void _onTaskData(Object data) {
    if (data == finishedMessage) _finished.add(null);
  }

  @override
  Future<bool> ensureNotificationsAllowed() => ensureArrivalAlarmAllowed();

  /// MainActivity.kt 가 받는다. 이 앱의 알림 설정 화면(Settings.ACTION_APP_NOTIFICATION_SETTINGS)을 연다
  static const MethodChannel _settingsChannel = MethodChannel('bus_51/settings');

  @override
  Future<void> openNotificationSettings() => _settingsChannel.invokeMethod<void>('openNotificationSettings');

  @override
  Future<bool> start(BusTrackingTarget target) async {
    final json = target.encode();
    await FlutterForegroundTask.saveData(key: BusTrackingTarget.storageKey, value: json);

    // 이미 돌고 있으면 서비스를 내리고 다시 올리지 않는다. 돌고 있는 서비스에 새 대상 문자열을 보내 갈아끼운다
    // (TaskHandler.onReceiveData). stopService() 는 서비스 플래그가 내려가면 바로 돌아오지만 이전 isolate 의
    // onDestroy 는 그 뒤에 늦게 실행된다. 그래서 stop → saveData → startService 로 하면 늦은 onDestroy 가
    // 방금 저장한 새 대상을 지우고 "끝났다" 메시지까지 보내, 새 서비스는 대상을 못 찾아 바로 내려가고 버튼은 꺼진다
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask(json);
      return true;
    }

    final firstTitle = BusTracker(
      routeName: target.routeName,
      plateNo: target.plateNo,
      remainingSeconds: target.remainingSeconds,
    ).ongoingTitle;

    final result = await FlutterForegroundTask.startService(
      // 고정 알림의 알림 id 로도 쓰인다. 알람 알림 id 와 겹치면 안 된다 (bus_notifications.dart)
      serviceId: kTrackingServiceId,
      serviceTypes: [ForegroundServiceTypes.dataSync],
      notificationTitle: firstTitle,
      notificationText: '',
      // 상태바 단색 버스 아이콘. 이름은 AndroidManifest 의 meta-data 와 같아야 한다
      notificationIcon: const NotificationIcon(metaDataName: 'com.threeCS.bus_51.service.TRACKING_ICON'),
      notificationButtons: const [NotificationButton(id: stopButtonId, text: '끄기')],
      callback: startBusTrackingCallback,
    );

    if (result is ServiceRequestFailure) {
      await FlutterForegroundTask.removeData(key: BusTrackingTarget.storageKey);
      return false;
    }
    return true;
  }

  @override
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    await FlutterForegroundTask.removeData(key: BusTrackingTarget.storageKey);
  }

  @override
  Future<BusTrackingTarget?> currentTarget() async {
    if (!await FlutterForegroundTask.isRunningService) {
      // 서비스가 시스템에 의해 죽었거나 앱이 꺼진 사이 끝났으면 남은 저장값은 지운다
      await FlutterForegroundTask.removeData(key: BusTrackingTarget.storageKey);
      return null;
    }
    final json = await FlutterForegroundTask.getData<String>(key: BusTrackingTarget.storageKey);
    return json == null ? null : BusTrackingTarget.decode(json);
  }
}
