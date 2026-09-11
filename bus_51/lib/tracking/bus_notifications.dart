import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --------------------------------------------------
// 도착 알림에 쓰는 안드로이드 알림 채널 두 개
// - 추적(고정) 채널: 무음. flutter_foreground_task 가 서비스를 켤 때 이 id 로 만든다
// - 알람 채널: 소리·진동. flutter_local_notifications 로 앱 시작 시 미리 만들고,
//   서비스 isolate 가 도착 10·5·3·1분 전에 여기로 알람을 띄운다
// 채널을 미리 만들어 두는 이유: 사용자가 설정에서 알람만 끌 수 있고, 그 상태를 켜기 전에 확인해야 한다
// --------------------------------------------------

const String kTrackingChannelId = 'bus_tracking';
const String kTrackingChannelName = '도착 알림 추적';
const String kTrackingChannelDescription = '도착 알림을 켜 둔 동안 남은 시간을 보여줍니다';

const String kArrivalAlarmChannelId = 'bus_arrival_alarm';
const String kArrivalAlarmChannelName = '도착 알람';
const String kArrivalAlarmChannelDescription = '버스 도착 10·5·3·1분 전에 울립니다';

// --------------------------------------------------
// 알림 id 두 개. 반드시 달라야 한다.
// flutter_foreground_task 는 serviceId 를 고정 알림의 알림 id 로 그대로 쓴다 (startForeground(serviceId, ...)).
// 알람이 같은 id 를 쓰면 알람이 고정 알림을 덮어쓰고, 같은 초에 이어지는 고정 알림 갱신이 알람을 다시 덮어
// 안드로이드가 막 시작한 소리·진동을 끊어 버린다 → "알람이 왔는데 소리도 진동도 없다"
// --------------------------------------------------

/// 포그라운드 서비스 id = 고정 알림의 알림 id
const int kTrackingServiceId = 51;

/// 알람 알림 id. 알람끼리는 항상 같은 id 라 새 알람이 이전 알람을 덮는다 (알림 영역에 한 장만 남는다)
const int kArrivalAlarmNotificationId = 5151;

/// 안드로이드 알림 작은 아이콘. 서비스 isolate 에서도 초기화 없이 쓸 수 있게 알람마다 직접 준다
const String _kNotificationIcon = '@mipmap/ic_launcher';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

AndroidFlutterLocalNotificationsPlugin? get _android =>
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

/// 앱 시작 시(그리고 서비스 isolate 시작 시) 한 번. 플러그인 초기화 + 알람 채널 생성. 여러 번 불러도 된다
Future<void> initBusNotifications() async {
  await _plugin.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings(_kNotificationIcon)),
  );
  await _android?.createNotificationChannel(
    const AndroidNotificationChannel(
      kArrivalAlarmChannelId,
      kArrivalAlarmChannelName,
      description: kArrivalAlarmChannelDescription,
      // 기기 기본 알림음 + 기본 진동, 헤드업으로 뜬다. 채널 설정은 한 번 만들어지면 앱이 바꿀 수 없다
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),
  );
}

/// 지금 이 앱이 알람을 띄울 수 있는가. 없으면 false → 화면이 공통 권한 다이얼로그를 띄운다.
///
/// 안드로이드 버전별 흐름 (기획 문서 4절). 플러그인이 버전을 가려 주므로 여기서는 분기하지 않는다:
/// - 13 이상: 알림이 런타임 권한. 아직 안 물어봤거나 한 번 거부했으면 시스템 팝업이 뜨고,
///   두 번 거부했으면 팝업 없이 false 가 온다 → "설정 열기"가 유일한 경로
/// - 8 ~ 12: 런타임 권한이 없어 팝업 없이 "앱 알림이 켜져 있는가"만 돌아온다
/// - 공통: 알람 채널만 꺼 둔 경우도 알람을 못 띄우므로 false
Future<bool> ensureArrivalAlarmAllowed() async {
  final android = _android;
  if (android == null) return true;

  var enabled = await android.areNotificationsEnabled() ?? true;
  if (!enabled) {
    enabled = await android.requestNotificationsPermission() ?? false;
  }
  if (!enabled) return false;

  final channels = await android.getNotificationChannels() ?? const <AndroidNotificationChannel>[];
  for (final channel in channels) {
    if (channel.id == kArrivalAlarmChannelId && channel.importance == Importance.none) return false;
  }
  return true;
}

/// 알람 한 번 (서비스 isolate 에서 부른다). 제목 한 줄만 쓴다: "51번 버스가 5분 후에 도착해요"
Future<void> showArrivalAlarm(String title) {
  return _plugin.show(
    id: kArrivalAlarmNotificationId,
    title: title,
    body: null,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        kArrivalAlarmChannelId,
        kArrivalAlarmChannelName,
        channelDescription: kArrivalAlarmChannelDescription,
        icon: _kNotificationIcon,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}
