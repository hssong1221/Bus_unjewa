import 'package:dio/dio.dart';

class DioSingleton {
  static Dio? _instance;

  static Dio getInstance() {
    _instance ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),   // 연결 타임아웃: 5초
        // 공공데이터포털 API가 종종 수 초 이상 걸려서 응답 대기는 넉넉하게
        receiveTimeout: const Duration(seconds: 15),  // 응답 타임아웃: 15초
        sendTimeout: const Duration(seconds: 5),      // 전송 타임아웃: 5초
      ),
    );
    return _instance!;
  }
}
