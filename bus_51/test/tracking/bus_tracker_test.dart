import 'package:bus_51/tracking/bus_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

const plate = '경기71바1146';

BusTracker make({int remaining = 30 * 60, String routeName = '51'}) =>
    BusTracker(routeName: routeName, plateNo: plate, remainingSeconds: remaining);

/// [seconds]초 동안 tick 하면서 울린 알람(분)을 순서대로 모은다
List<int> run(BusTracker tracker, int seconds) {
  final fired = <int>[];
  for (var i = 0; i < seconds; i++) {
    final minutes = tracker.tick();
    if (minutes != null) fired.add(minutes);
  }
  return fired;
}

void main() {
  group('알람 4회', () {
    test('30분 남았으면 10·5·3·1분 전 정확히 그 초에 한 번씩 울리고 0 이 되면 끝난다', () {
      final t = make(remaining: 1800);
      expect(t.pendingAlarms, {10, 5, 3, 1});

      expect(run(t, 1199), isEmpty); // 10분 1초 남음
      expect(t.tick(), 10); // 10분 0초
      expect(run(t, 299), isEmpty);
      expect(t.tick(), 5);
      expect(run(t, 119), isEmpty);
      expect(t.tick(), 3);
      expect(run(t, 119), isEmpty);
      expect(t.tick(), 1);
      expect(t.pendingAlarms, isEmpty);

      expect(run(t, 59), isEmpty);
      expect(t.isFinished, isFalse);
      expect(t.tick(), isNull); // 0초: 알람 없이 종료
      expect(t.isFinished, isTrue);
      expect(t.endReason, BusTrackingEndReason.arrived);
    });

    test('활성화 시점에 이미 지난 시점은 제외한다: 7분이면 5·3·1분만', () {
      final t = make(remaining: 7 * 60);

      expect(t.pendingAlarms, {5, 3, 1});
      expect(run(t, 7 * 60), [5, 3, 1]);
    });

    test('정확히 10분 남았을 때 켜면 10분 알람은 울리지 않는다', () {
      expect(make(remaining: 600).pendingAlarms, {5, 3, 1});
    });

    test('보정으로 두 시점을 한 번에 지나치면 가까운 것 하나만: 6분 → 2분 30초면 3분 알람만', () {
      final t = make(remaining: 6 * 60);

      t.applyArrival(plateNo: plate, remainingSeconds: 150);

      expect(t.tick(), 3);
      expect(t.pendingAlarms, {1});
      expect(run(t, 88), isEmpty); // 61초
      expect(t.tick(), 1);
    });

    test('보정으로 시간이 다시 늘어나도 이미 울린 알람은 다시 울리지 않는다', () {
      final t = make(remaining: 310);
      expect(run(t, 10), [5]);

      t.applyArrival(plateNo: plate, remainingSeconds: 400);

      expect(run(t, 100), isEmpty); // 400 → 300: 5분을 다시 지나도 조용
      expect(t.pendingAlarms, {3, 1});
    });
  });

  group('종료', () {
    test('조회 결과의 차량번호가 다르면 busChanged (운행 종료로 빈 값이 와도 같다)', () {
      final early = make();
      early.applyArrival(plateNo: '경기71바9999', remainingSeconds: 1000);
      expect(early.endReason, BusTrackingEndReason.busChanged);

      final ended = make();
      ended.applyArrival(plateNo: '', remainingSeconds: 0);
      expect(ended.endReason, BusTrackingEndReason.busChanged);
    });

    test('끝난 뒤에는 tick·보정을 해도 아무것도 바뀌지 않는다', () {
      final t = make(remaining: 300);
      t.applyArrival(plateNo: '다른차', remainingSeconds: 100);

      expect(t.tick(), isNull);
      expect(t.remainingSeconds, 300);
      t.applyArrival(plateNo: plate, remainingSeconds: 50);
      expect(t.remainingSeconds, 300);
      expect(t.endReason, BusTrackingEndReason.busChanged);
      expect(t.isPollDue, isFalse);
    });

    test('90분이 지나면 timeout 으로 끝난다', () {
      final t = make(remaining: 200 * 60);

      expect(run(t, 90 * 60 - 1), isEmpty);
      expect(t.isFinished, isFalse);
      t.tick();
      expect(t.endReason, BusTrackingEndReason.timeout);
    });
  });

  group('조회 주기', () {
    test('10분 초과면 120초, 이하면 60초', () {
      expect(make(remaining: 601).pollIntervalSeconds, 120);
      expect(make(remaining: 600).pollIntervalSeconds, 60);
    });

    test('주기가 차면 isPollDue, 결과를 반영하면 다시 0부터 센다', () {
      final t = make(remaining: 1800);

      run(t, 119);
      expect(t.isPollDue, isFalse);
      t.tick();
      expect(t.isPollDue, isTrue);

      t.applyArrival(plateNo: plate, remainingSeconds: 1700);
      expect(t.isPollDue, isFalse);
      run(t, 120);
      expect(t.isPollDue, isTrue);
    });

    test('조회 실패는 무시하고 카운트다운을 이어가며 다음 주기에 다시 시도한다', () {
      final t = make(remaining: 1800);
      run(t, 120);
      expect(t.isPollDue, isTrue);

      t.applyPollFailure();

      expect(t.isPollDue, isFalse);
      expect(t.remainingSeconds, 1680);
      expect(t.isFinished, isFalse);
      run(t, 120);
      expect(t.isPollDue, isTrue);
    });

    test('30분 추적이면 조회는 20번 안팎이다', () {
      final t = make(remaining: 1800);
      var polls = 0;
      while (!t.isFinished) {
        t.tick();
        if (t.isPollDue) {
          polls++;
          t.applyArrival(plateNo: plate, remainingSeconds: t.remainingSeconds);
        }
      }

      expect(polls, inInclusiveRange(18, 22));
    });
  });

  group('알림 문구', () {
    test('고정 알림은 분 올림, 2분 미만이면 잠시 후 도착', () {
      expect(make(remaining: 300).ongoingTitle, '51번 버스 · 5분 후 도착');
      expect(make(remaining: 299).ongoingTitle, '51번 버스 · 5분 후 도착');
      expect(make(remaining: 240).ongoingTitle, '51번 버스 · 4분 후 도착');
      expect(make(remaining: 120).ongoingTitle, '51번 버스 · 2분 후 도착');
      expect(make(remaining: 119).ongoingTitle, '51번 버스 · 잠시 후 도착');
    });

    test('알람 제목', () {
      expect(make().alarmTitle(5), '51번 버스가 5분 후에 도착해요');
    });

    test('노선 이름이 숫자로 끝날 때만 "번"을 붙인다', () {
      expect(make(routeName: 'M5107').busLabel, 'M5107번 버스');
      expect(make(routeName: '통학1(등교)').busLabel, '통학1(등교) 버스');
    });
  });
}
