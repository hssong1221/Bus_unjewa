import 'package:bus_51/entity/bus_arrival_entity.dart';
import 'package:bus_51/entity/bus_routestation_entity.dart';
import 'package:bus_51/entity/busroute_entity.dart';
import 'package:bus_51/entity/busstation_entity.dart';
import 'package:bus_51/mapper/bus_arrival_mapper.dart';
import 'package:bus_51/mapper/bus_routestation_mapper.dart';
import 'package:bus_51/mapper/busroute_mapper.dart';
import 'package:bus_51/mapper/busstation_mapper.dart';
import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/service/dio_singleton.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/utils/contants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class BusApiService {
  /// 테스트에서는 가짜 어댑터를 붙인 Dio 를 넣는다
  BusApiService({Dio? dio}) : _dio = dio ?? DioSingleton.getInstance();

  final Dio _dio;

  // TODO: 서버 정상화 후 제거 필요 - 임시 공공데이터 API 직접 호출용
  final String serviceKey = "WmieO1vfcMEfgrDc60v7veixKyQjCbrPc0KzbaNiQ8XsXa5hnl8t2MuYSdVejeKgO4+xLVLV54GABvOBnndYIw==";
  final String format = "json";

  /// 결과 코드가 0·4 가 아닐 때, 응답 모양이 이상할 때 사용자에게 보여줄 문구
  static const serviceErrorMessage = '버스 정보 서비스에 문제가 있습니다. 잠시 후 다시 시도해 주세요';

  /// 공공데이터포털 일일 요청 한도(게이트웨이 코드 22)를 넘었을 때
  static const quotaExceededMessage = '오늘 버스 정보 요청 한도를 넘었습니다. 잠시 후 다시 시도해 주세요';

  /// 공공 API 응답의 결과 코드를 확인한다.
  /// - true: 정상(0). msgBody 를 읽으면 된다
  /// - false: 결과 없음(4). 호출한 쪽은 "없음"으로 처리한다
  /// - 그 외 코드(파라미터 오류·시스템 에러·요청 제한 등)와 포털 게이트웨이 오류(인증키·트래픽 초과)는
  ///   [ApiException] — 이걸 "운행 없음"으로 보여주면 안 된다
  ///
  /// 실제 응답 예:
  /// - `{"response":{"msgHeader":{"resultCode":4,"resultMessage":"결과가 존재하지 않습니다."}}}`
  /// - `{"response":{"msgHeader":{"resultCode":2,"resultMessage":"필수 요청 Parameter 가 존재하지 않습니다."}}}`
  /// - 게이트웨이: `{"OpenAPI_ServiceResponse":{"cmmMsgHeader":{"returnReasonCode":"30","returnAuthMsg":"등록되지 않은 서비스키"}}}`
  ///   (format=json 이어도 XML 로 올 때가 있어 본문이 String 이면 역시 오류로 본다)
  bool hasResult(dynamic data) {
    if (data is! Map) {
      throw ApiException(error: 'unexpected body (${data.runtimeType}): $data', message: serviceErrorMessage);
    }

    final gateway = data["OpenAPI_ServiceResponse"];
    if (gateway is Map) {
      final header = gateway["cmmMsgHeader"];
      final code = header is Map ? header["returnReasonCode"]?.toString() : null;
      final reason = header is Map ? header["returnAuthMsg"] : null;
      throw ApiException(
        error: 'gateway $code: $reason',
        message: code == "22" ? quotaExceededMessage : serviceErrorMessage,
      );
    }

    final body = data["response"];
    final header = body is Map ? body["msgHeader"] : null;
    final code = header is Map ? header["resultCode"]?.toString() : null;
    if (code == "0") return true;
    if (code == "4") return false;
    throw ApiException(
      error: 'resultCode $code: ${header is Map ? header["resultMessage"] : null}',
      message: serviceErrorMessage,
    );
  }

  List<dynamic> makeListForm(dynamic raw) {
    List<dynamic> resultList;
    if(raw is List){
      resultList = raw;
    } else if(raw is Map){
      resultList = [raw];
    } else {
      resultList = [];
    }
    return resultList;
  }

  /// 내 주변 500미터 버스 정류장 상세
  Future<List<BusStationModel>> getBusStationList({required String x, required String y}) async {
    // 자체 서버 연결 (서버 복구 시 다시 사용)
    // final apiPath = "${AppConstants.apiBaseUrl}/getBusStationAroundListv2";
    final apiPath = "${AppConstants.apiBaseUrlStation}/getBusStationAroundListv2";

    try {
      final response = await _dio.get(
        apiPath,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          // 자체 서버용 파라미터 (서버 복구 시 다시 사용)
          // "lon" : x,
          // "lat" : y,
          "x" : x,
          "y" : y,
          "serviceKey": serviceKey,
          "format": format,
        },
      );

      if (response.statusCode == 200) {
        if (!hasResult(response.data)) return [];

        // 주변에 정류장이 없으면 msgBody가 null로 내려옴
        final msgBody = response.data["response"]["msgBody"];
        if (msgBody == null || msgBody["busStationAroundList"] == null) {
          return [];
        }

        List<dynamic> resultList = makeListForm(msgBody["busStationAroundList"]);
        var entitiesList = resultList.map((json) => BusStationEntity.fromJson(json)).toList();
        var modelList = BusStationMapper.fromEntityList(entitiesList);
        return modelList;
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 버스 정류장을 지나가는 노선
  Future<List<BusRouteModel>> getBusRouteList({required String stationId}) async {
    // 자체 서버 연결 (서버 복구 시 다시 사용)
    // final apiPath = "${AppConstants.apiBaseUrl}/getBusStationViaRouteListv2";
    final apiPath = "${AppConstants.apiBaseUrlStation}/getBusStationViaRouteListv2";

    try {
      final response = await _dio.get(
        apiPath,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          "stationId": stationId,
          "serviceKey": serviceKey,
          "format": format,
        },
      );

      if (response.statusCode == 200) {
        if (!hasResult(response.data)) return [];

        // 경유 노선이 없는 정류장이면 msgBody가 null로 내려옴
        final msgBody = response.data["response"]["msgBody"];
        if (msgBody == null || msgBody["busRouteList"] == null) {
          return [];
        }

        List<dynamic> resultList = makeListForm(msgBody["busRouteList"]);
        var entitiesList = resultList.map((json) => BusRouteEntity.fromJson(json)).toList();
        var modelList = BusRouteMapper.fromEntityList(entitiesList);
        return modelList;
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 버스 노선이 지나가는 정류장 리스트
  Future<List<BusRouteStationModel>> getBusRouteStationList({required String routeId}) async {
    // 자체 서버 연결 (서버 복구 시 다시 사용)
    // final apiPath = "${AppConstants.apiBaseUrl}/getBusRouteStationListv2";
    final apiPath = "${AppConstants.apiBaseUrlRoute}/getBusRouteStationListv2";

    try {
      final response = await _dio.get(
        apiPath,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          "routeId": routeId,
          "serviceKey": serviceKey,
          "format": format,
        },
      );

      if (response.statusCode == 200) {
        if (!hasResult(response.data)) return [];

        // 정류장 정보가 없으면 msgBody가 null로 내려옴
        final msgBody = response.data["response"]["msgBody"];
        if (msgBody == null || msgBody["busRouteStationList"] == null) {
          return [];
        }

        List<dynamic> resultList = makeListForm(msgBody["busRouteStationList"]);
        var entitiesList = resultList.map((json) => BusRouteStationEntity.fromJson(json)).toList();
        var modelList = BusRouteStationMapper.fromEntityList(entitiesList);
        return modelList;
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // 유저가 선택한 정류장과 노선에 맞는 버스 도착정보 가져오기
  Future<BusArrivalModel?> getBusArrivalTimeList({required String stationId, required String routeId, required String staOrder}) async {
    // 자체 서버 연결 (서버 복구 시 다시 사용)
    // final apiPath = "${AppConstants.apiBaseUrl}/getBusArrivalItemv2";
    final apiPath = "${AppConstants.apiBaseUrlArrival}/getBusArrivalItemv2";

    try {
      final response = await _dio.get(
        apiPath,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          "stationId": stationId,
          "routeId": routeId,
          "staOrder": staOrder,
          "serviceKey": serviceKey,
          "format": format,
        },
      );

      if (response.statusCode == 200) {
        // 결과 없음(4)은 운행 없음, 그 외 오류 코드는 hasResult 가 던진다
        if (!hasResult(response.data)) {
          debugPrint("버스 운행 정보가 없습니다: ${response.data["response"]["msgHeader"]["resultMessage"]}");
          return null;
        }

        // msgBody가 null이거나 busArrivalItem이 없는 경우 처리
        final msgBody = response.data["response"]["msgBody"];
        if (msgBody == null || msgBody["busArrivalItem"] == null) {
          debugPrint("버스 도착 정보가 없습니다");
          return null;
        }

        List<dynamic> resultList = makeListForm(msgBody["busArrivalItem"]);
        if (resultList.isEmpty) {
          debugPrint("버스 도착 정보 리스트가 비어있습니다");
          return null;
        }

        var entitiesList = resultList.map((json) => BusArrivalEntity.fromJson(json)).toList();
        // 버스 도착정보는 항상 한개임
        var model = BusArrivalMapper.fromEntity(entitiesList[0]);
        return model;
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // 정류장에 오는 전체 노선의 버스 도착정보 가져오기 (노선별 한 항목, 응답 필드는 getBusArrivalItemv2 와 같다)
  // 리스트 화면처럼 같은 정류장의 노선이 여럿일 때 노선마다 부르지 않고 이걸 한 번만 부른다
  Future<List<BusArrivalModel>> getBusArrivalList({required String stationId}) async {
    final apiPath = "${AppConstants.apiBaseUrlArrival}/getBusArrivalListv2";

    try {
      final response = await _dio.get(
        apiPath,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          "stationId": stationId,
          "serviceKey": serviceKey,
          "format": format,
        },
      );

      if (response.statusCode == 200) {
        // 결과 없음(4)은 운행 없음, 그 외 오류 코드는 hasResult 가 던진다
        if (!hasResult(response.data)) {
          debugPrint("정류장 버스 운행 정보가 없습니다: ${response.data["response"]["msgHeader"]["resultMessage"]}");
          return [];
        }

        final msgBody = response.data["response"]["msgBody"];
        if (msgBody == null || msgBody["busArrivalList"] == null) {
          return [];
        }

        List<dynamic> resultList = makeListForm(msgBody["busArrivalList"]);
        var entitiesList = resultList.map((json) => BusArrivalEntity.fromJson(json)).toList();
        return BusArrivalMapper.fromEntityList(entitiesList);
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }



  // 테스트
  Future<void> testConnect({required String itemId, required String q}) async {
    final path = "${AppConstants.apiBaseUrl}/items/$itemId";
    try {
      final response = await _dio.get(
        path,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          "q": q,
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

}
