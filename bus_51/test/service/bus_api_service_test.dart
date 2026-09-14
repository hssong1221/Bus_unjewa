import 'dart:typed_data';

import 'package:bus_51/service/bus_api_service.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 어떤 요청이든 정해진 본문을 돌려주는 어댑터. 실제 공공 API 가 보내는 모양을 그대로 흉내 낸다
class CannedAdapter implements HttpClientAdapter {
  CannedAdapter(this.body, {this.contentType = Headers.jsonContentType});

  final String body;
  final String contentType;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(body, 200, headers: {
        Headers.contentTypeHeader: [contentType],
      });

  @override
  void close({bool force = false}) {}
}

BusApiService serviceWith(String body, {String contentType = Headers.jsonContentType}) =>
    BusApiService(dio: Dio()..httpClientAdapter = CannedAdapter(body, contentType: contentType));

// 실제 응답에서 가져온 본문들
const _ok = '{"response":{"comMsgHeader":"","msgHeader":{"queryTime":"2026-09-14 13:30:37.287","resultCode":0,"resultMessage":"정상적으로 처리되었습니다."},'
    '"msgBody":{"busArrivalList":[{"flag":"PASS","locationNo1":1,"plateNo1":"경기71바1091","predictTime1":1,"predictTimeSec1":"64","routeId":208000017,"stationId":226000060,"staOrder":3}],'
    '"busArrivalItem":{"flag":"PASS","locationNo1":1,"plateNo1":"경기71바1091","predictTime1":1,"predictTimeSec1":"64","routeId":208000017,"stationId":226000060,"staOrder":3},'
    '"busStationAroundList":{"stationId":226000060,"stationName":"수원역","x":"127.0","y":"37.2","distance":"10"}}}}';
const _noResult = '{"response":{"comMsgHeader":"","msgHeader":{"queryTime":"2026-09-14 13:30:00.158","resultCode":4,"resultMessage":"결과가 존재하지 않습니다."}}}';
const _missingParam = '{"response":{"comMsgHeader":"","msgHeader":{"queryTime":"2026-09-14 13:30:37.162","resultCode":2,"resultMessage":"필수 요청 Parameter 가 존재하지 않습니다."}}}';
const _badKey = '{"OpenAPI_ServiceResponse":{"cmmMsgHeader":{"errMsg":"SERVICE_KEY_IS_NOT_REGISTERED_ERROR","returnAuthMsg":"등록되지 않은 서비스키","returnReasonCode":"30"}}}';
const _quota = '{"OpenAPI_ServiceResponse":{"cmmMsgHeader":{"errMsg":"LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR","returnAuthMsg":"서비스 요청제한횟수 초과에러","returnReasonCode":"22"}}}';
const _xml = '<OpenAPI_ServiceResponse><cmmMsgHeader><errMsg>SERVICE ERROR</errMsg><returnReasonCode>01</returnReasonCode></cmmMsgHeader></OpenAPI_ServiceResponse>';

void main() {
  group('hasResult', () {
    final service = BusApiService(dio: Dio());

    test('정상(0)이면 true, 결과 없음(4)이면 false', () {
      expect(service.hasResult({'response': {'msgHeader': {'resultCode': 0}}}), isTrue);
      expect(service.hasResult({'response': {'msgHeader': {'resultCode': '0'}}}), isTrue);
      expect(service.hasResult({'response': {'msgHeader': {'resultCode': 4}}}), isFalse);
    });

    test('그 외 결과 코드는 사용자 문구와 함께 던지고 원문 코드·메시지는 error 에 남긴다', () {
      expect(
        () => service.hasResult({'response': {'msgHeader': {'resultCode': 2, 'resultMessage': '필수 요청 Parameter 가 존재하지 않습니다.'}}}),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', BusApiService.serviceErrorMessage)
            .having((e) => e.error, 'error', 'resultCode 2: 필수 요청 Parameter 가 존재하지 않습니다.')),
      );
    });

    test('msgHeader 가 없거나 본문이 Map 이 아니어도 TypeError 가 아니라 ApiException', () {
      expect(() => service.hasResult({'response': {}}), throwsA(isA<ApiException>()));
      expect(() => service.hasResult({}), throwsA(isA<ApiException>()));
      expect(() => service.hasResult(null), throwsA(isA<ApiException>()));
      expect(() => service.hasResult(_xml), throwsA(isA<ApiException>()));
    });

    test('포털 게이트웨이 오류는 ApiException 이고, 요청 한도 초과(22)는 전용 문구다', () {
      expect(
        () => service.hasResult({'OpenAPI_ServiceResponse': {'cmmMsgHeader': {'returnReasonCode': '30', 'returnAuthMsg': '등록되지 않은 서비스키'}}}),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', BusApiService.serviceErrorMessage)
            .having((e) => e.error, 'error', 'gateway 30: 등록되지 않은 서비스키')),
      );
      expect(
        () => service.hasResult({'OpenAPI_ServiceResponse': {'cmmMsgHeader': {'returnReasonCode': '22', 'returnAuthMsg': '서비스 요청제한횟수 초과에러'}}}),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', BusApiService.quotaExceededMessage)),
      );
    });
  });

  group('도착 정보 단건 (getBusArrivalTimeList)', () {
    Future<dynamic> call(String body, {String contentType = Headers.jsonContentType}) =>
        serviceWith(body, contentType: contentType).getBusArrivalTimeList(stationId: '226000060', routeId: '208000017', staOrder: '3');

    test('정상이면 모델을 돌려준다', () async {
      final model = await call(_ok);
      expect(model?.predictTimeSec1, '64');
      expect(model?.plateNo1, '경기71바1091');
    });

    test('결과 없음(4)이면 null (운행 없음)', () async {
      expect(await call(_noResult), isNull);
    });

    test('파라미터 오류(2)는 운행 없음이 아니라 ApiException', () {
      expect(call(_missingParam), throwsA(isA<ApiException>().having((e) => e.message, 'message', BusApiService.serviceErrorMessage)));
    });

    test('잘못된 인증키·요청 한도 초과(게이트웨이 JSON)는 ApiException', () {
      expect(call(_badKey), throwsA(isA<ApiException>()));
      expect(call(_quota), throwsA(isA<ApiException>().having((e) => e.message, 'message', BusApiService.quotaExceededMessage)));
    });

    test('본문이 XML 로 오면 ApiException (TypeError 로 새지 않는다)', () {
      expect(call(_xml, contentType: 'text/xml'), throwsA(isA<ApiException>()));
    });
  });

  group('정류장 단위 도착 목록 (getBusArrivalList)', () {
    Future<dynamic> call(String body) => serviceWith(body).getBusArrivalList(stationId: '226000060');

    test('정상이면 목록, 결과 없음(4)이면 빈 목록', () async {
      expect((await call(_ok)).length, 1);
      expect(await call(_noResult), isEmpty);
    });

    test('파라미터 오류(2)는 빈 목록이 아니라 ApiException', () {
      expect(call(_missingParam), throwsA(isA<ApiException>()));
    });
  });

  group('주변 정류장 (getBusStationList)', () {
    Future<dynamic> call(String body) => serviceWith(body).getBusStationList(x: '127.0', y: '37.2');

    test('정상이면 목록, 결과 없음(4)이면 빈 목록', () async {
      expect((await call(_ok)).length, 1);
      expect(await call(_noResult), isEmpty);
    });

    test('그 외 오류 코드는 "주변 정류장 없음"이 아니라 ApiException', () {
      expect(call(_missingParam), throwsA(isA<ApiException>()));
      expect(call(_badKey), throwsA(isA<ApiException>()));
    });
  });
}
