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
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class BusApiService {
  final Dio _dio = DioSingleton.getInstance();

  /*final String serviceKey = "";
  final String format = "json";*/

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
    //final path = "${AppConstants.apiBaseUrl_Station}/getBusStationAroundListv2";
    final path = "${AppConstants.apiBaseUrl}/getBusStationAroundListv2";

    try {
      final response = await _dio.get(
        path,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          "lon" : x,
          "lat" : y,
        }
        /*queryParameters: {
          "serviceKey": serviceKey,
          "x": 1,
          "y": y,
          "format": format,
        },*/
      );

      if (response.statusCode == 200) {
        List<dynamic> resultList = makeListForm(response.data["response"]["msgBody"]["busStationAroundList"]);
        var entitiesList = resultList.map((json) => BusStationEntity.fromJson(json)).toList();
        var modelList = BusStationMapper.fromEntityList(entitiesList);
        return modelList;
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(error: e.response?.statusMessage ?? 'Unknown error', message: e.response!.data["message"], statusCode: e.response!.statusCode);
      } else {
        throw ApiException(error: e.message);
      }
    }
  }

  /// 버스 정류장을 지나가는 노선
  Future<List<BusRouteModel>> getBusRouteList({required String stationId}) async {
    //final path = "${AppConstants.apiBaseUrl_Station}/getBusStationViaRouteListv2";
    final path = "${AppConstants.apiBaseUrl}/getBusStationViaRouteListv2";

    try {
      final response = await _dio.get(
        path,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          "stationId": stationId,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> resultList = makeListForm(response.data["response"]["msgBody"]["busRouteList"]);
        var entitiesList = resultList.map((json) => BusRouteEntity.fromJson(json)).toList();
        var modelList = BusRouteMapper.fromEntityList(entitiesList);
        return modelList;
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(error: e.response?.statusMessage ?? 'Unknown error', message: e.response!.data["message"], statusCode: e.response!.statusCode);
      } else {
        throw ApiException(error: e.message);
      }
    }
  }

  /// 버스 노선이 지나가는 정류장 리스트
  Future<List<BusRouteStationModel>> getBusRouteStationList({required String routeId}) async {
    //final path = "${AppConstants.apiBaseUrl_Route}/getBusRouteStationListv2";
    final path = "${AppConstants.apiBaseUrl}/getBusRouteStationListv2";
    try {
      final response = await _dio.get(
        path,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          "routeId": routeId,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> resultList = makeListForm(response.data["response"]["msgBody"]["busRouteStationList"]);
        var entitiesList = resultList.map((json) => BusRouteStationEntity.fromJson(json)).toList();
        var modelList = BusRouteStationMapper.fromEntityList(entitiesList);
        return modelList;
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(error: e.response?.statusMessage ?? 'Unknown error', message: e.response!.data["message"], statusCode: e.response!.statusCode);
      } else {
        throw ApiException(error: e.message);
      }
    }
  }

  // 유저가 선택한 정류장과 노선에 맞는 버스 도착정보 가져오기
  Future<BusArrivalModel> getBusArrivalTimeList({required String stationId, required String routeId, required String staOrder}) async {
    //final path = "${AppConstants.apiBaseUrl_Arrival}/getBusArrivalItemv2";
    final path = "${AppConstants.apiBaseUrl}/getBusArrivalItemv2";
    try {
      final response = await _dio.get(
        path,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
        queryParameters: {
          "stationId": stationId,
          "routeId": routeId,
          "staOrder": staOrder,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> resultList = makeListForm(response.data["response"]["msgBody"]["busArrivalItem"]);
        var entitiesList = resultList.map((json) => BusArrivalEntity.fromJson(json)).toList();
        // 버스 도착정보는 항상 한개임
        var model = BusArrivalMapper.fromEntity(entitiesList[0]);
        return model;
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(error: e.response?.statusMessage ?? 'Unknown error', message: e.response!.data["message"], statusCode: e.response!.statusCode);
      } else {
        throw ApiException(error: e.message);
      }
    }
  }



  // 테스트
  Future<void> testConnect({required String item_id, required String q}) async {
    final path = "${AppConstants.apiBaseUrl}/items/$item_id";
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

      if (response.statusCode == 200) {
        var result = response.data;
      } else {
        throw ApiException(error: response.data["error"], message: response.data["message"], statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(error: e.response?.statusMessage ?? 'Unknown error', message: e.response!.data["message"], statusCode: e.response!.statusCode);
      } else {
        throw ApiException(error: e.message);
      }
    }
  }

  //xml 사용해서 만든 옛날 버전
  Future<Map<String, String>> getBusData() async {
    final parameter = {
      'serviceKey': "",
      'stationId': "",
      'routeId': "",
      'staOrder': "",
    };

    final uri = Uri.https('apis.data.go.kr', '/6410000/busarrivalservice/getBusArrivalItem', parameter);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final xmlDoc = xml.XmlDocument.parse(response.body);

      debugPrint(xmlDoc.toString());

      // busArrivalItem 요소 찾기
      final busArrivalItem = xmlDoc.findAllElements('busArrivalItem').first;

      Map<String, String> dataMap = {};

      for (var item in busArrivalItem.children) {
        if (item is xml.XmlElement) {
          dataMap[item.name.local] = item.innerText;
          debugPrint(item.innerText);
        }
      }
      return dataMap;
    } else {
      throw Exception('Failed to load data');
    }
  }
}
