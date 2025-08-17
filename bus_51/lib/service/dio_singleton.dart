import 'package:dio/dio.dart';

class DioSingleton {
  static Dio? _instance;

  static Dio getInstance() {
    _instance ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),  // 연결 타임아웃: 5초
        receiveTimeout: const Duration(seconds: 5),  // 응답 타임아웃: 5초
        sendTimeout: const Duration(seconds: 5),     // 전송 타임아웃: 5초
      ),
    );
    return _instance!;
  }
}
