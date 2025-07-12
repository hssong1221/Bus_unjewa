import 'dart:async';
import 'package:flutter/material.dart';

class TimerProvider extends ChangeNotifier {
  int _remainingSeconds1 = 0;
  int _remainingSeconds2 = 0;
  Timer? _timer1;
  Timer? _timer2;

  int get remainingSeconds1 => _remainingSeconds1;
  int get remainingSeconds2 => _remainingSeconds2;

  // API로부터 시간 세팅
  void setTimerFromApi(int seconds1, int seconds2) {
    _remainingSeconds1 = seconds1;
    _remainingSeconds2 = seconds2;

    //notifyListeners();

    startTimer1();
    startTimer2();
  }

  void startTimer1() {
    _timer1?.cancel();
    _timer1 = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds1 > 0) {
        _remainingSeconds1--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void startTimer2() {
    _timer2?.cancel();
    _timer2 = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds2 > 0) {
        _remainingSeconds2--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer1?.cancel();
    _timer2?.cancel();
    debugPrint("auto dispose");
    super.dispose();
  }
}
