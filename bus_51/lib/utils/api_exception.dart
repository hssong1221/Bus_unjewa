import 'package:dio/dio.dart';

class ApiException implements Exception {
  /// 개발자용 원문 (Dio 메시지 등). 화면에 보여주지 않는다
  final String? error;

  /// 사용자에게 보여줄 문구
  final String? message;
  final int? statusCode;

  ApiException({this.error, this.message, this.statusCode});

  /// Dio 오류를 종류별 한국어 문구로 바꾼다. 원문은 error 에 남겨 로그용으로만 쓴다.
  /// 응답 본문은 건드리지 않는다 — 공공데이터포털은 오류를 XML/HTML 로 주기도 해서 Map 이라고 가정할 수 없다
  factory ApiException.fromDio(DioException e) {
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        '응답이 늦어 시간이 초과됐습니다. 잠시 후 다시 시도해 주세요',
      DioExceptionType.connectionError => '인터넷 연결을 확인해 주세요',
      DioExceptionType.badResponse => '버스 정보 서버에 문제가 있습니다. 잠시 후 다시 시도해 주세요',
      // 취소·인증서·알 수 없음 등 나머지 전부
      _ => '버스 정보를 불러오지 못했습니다',
    };
    return ApiException(error: e.message, message: message, statusCode: e.response?.statusCode);
  }

  @override
  String toString() {
    return 'ApiException: $error, $message (Status code: $statusCode)';
  }
}
