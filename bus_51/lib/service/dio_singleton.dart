import 'package:dio/dio.dart';

class DioSingleton {
  static Dio? _instance;

  static Dio getInstance() {
    _instance ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
    );
    return _instance!;
  }
}
