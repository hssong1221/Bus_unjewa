import 'package:bus_51/utils/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final options = RequestOptions(path: '/busarrivalservice/v2/getBusArrivalItemv2');

  DioException dioError(DioExceptionType type, {Response<dynamic>? response}) => DioException(
        requestOptions: options,
        type: type,
        response: response,
        message: 'The connection errored: Failed host lookup',
      );

  group('ApiException.fromDio', () {
    test('통신 두절은 인터넷 연결 안내가 되고 원문은 error 에만 남는다', () {
      final e = ApiException.fromDio(dioError(DioExceptionType.connectionError));

      expect(e.message, '인터넷 연결을 확인해 주세요');
      expect(e.error, 'The connection errored: Failed host lookup');
      expect(e.statusCode, isNull);
    });

    test('연결·전송·응답 타임아웃은 모두 시간 초과 안내가 된다', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(ApiException.fromDio(dioError(type)).message, '응답이 늦어 시간이 초과됐습니다. 잠시 후 다시 시도해 주세요');
      }
    });

    test('HTTP 오류 응답은 본문이 XML 이어도 던지지 않고 서버 문제 안내와 상태 코드를 준다', () {
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: 500,
        data: '<OpenAPI_ServiceResponse><cmmMsgHeader><returnReasonCode>22</returnReasonCode></cmmMsgHeader></OpenAPI_ServiceResponse>',
      );

      final e = ApiException.fromDio(dioError(DioExceptionType.badResponse, response: response));

      expect(e.message, '버스 정보 서버에 문제가 있습니다. 잠시 후 다시 시도해 주세요');
      expect(e.statusCode, 500);
    });

    test('그 외(취소·인증서·알 수 없음)는 기본 문구다', () {
      for (final type in [
        DioExceptionType.cancel,
        DioExceptionType.badCertificate,
        DioExceptionType.unknown,
      ]) {
        expect(ApiException.fromDio(dioError(type)).message, '버스 정보를 불러오지 못했습니다');
      }
    });

    test('사용자 문구에는 Dio 영문 원문이 섞이지 않는다', () {
      for (final type in DioExceptionType.values) {
        final message = ApiException.fromDio(dioError(type)).message!;
        expect(message, isNot(contains('connection')));
        expect(message, isNot(contains('Dio')));
      }
    });
  });
}
