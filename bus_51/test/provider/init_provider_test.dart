import 'package:bus_51/provider/init_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InitProvider 최초 온보딩 (startIdx 0)', () {
    test('웰컴(0)에서 시작하고 첫 단계로 판정한다', () {
      final provider = InitProvider();

      expect(provider.curIdx, 0);
      expect(provider.isFirstStep, isTrue);
      expect(provider.stepNumber, 1);
      expect(provider.totalSteps, 4);
    });

    test('첫 단계에서 prev 를 눌러도 0 아래로 내려가지 않는다', () {
      final provider = InitProvider();

      provider.prevAccountView();

      expect(provider.curIdx, 0);
      expect(provider.isFirstStep, isTrue);
    });

    test('next 로 마지막 단계(3)까지 가고 그 이상은 멈춘다', () {
      final provider = InitProvider();

      provider.nextAccountView();
      provider.nextAccountView();
      provider.nextAccountView();
      provider.nextAccountView();

      expect(provider.curIdx, 3);
      expect(provider.stepNumber, 4);
      expect(provider.isFirstStep, isFalse);
    });
  });

  group('InitProvider 노선 추가 플로우 (startIdx 1)', () {
    test('정류장 선택(1)에서 시작하고 진행 표시는 1/3 이다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);

      expect(provider.curIdx, 1);
      expect(provider.isFirstStep, isTrue);
      expect(provider.stepNumber, 1);
      expect(provider.totalSteps, 3);
    });

    test('첫 단계에서 prev 를 눌러도 웰컴(0)으로 돌아가지 않는다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);

      provider.prevAccountView();

      expect(provider.curIdx, 1);
      expect(provider.isFirstStep, isTrue);
    });

    test('next 후 prev 하면 시작 단계로 돌아오고 다시 첫 단계로 판정한다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);

      provider.nextAccountView();
      expect(provider.curIdx, 2);
      expect(provider.isFirstStep, isFalse);
      expect(provider.stepNumber, 2);

      provider.prevAccountView();
      expect(provider.curIdx, 1);
      expect(provider.isFirstStep, isTrue);
    });

    test('마지막 단계는 3/3 으로 표시된다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);

      provider.nextAccountView();
      provider.nextAccountView();

      expect(provider.curIdx, 3);
      expect(provider.stepNumber, 3);
      expect(provider.totalSteps, 3);
    });

    test('단계가 바뀔 때 리스너에게 알린다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);
      var notified = 0;
      provider.addListener(() => notified++);

      provider.nextAccountView();
      provider.prevAccountView();

      expect(notified, 2);
    });
  });
}
