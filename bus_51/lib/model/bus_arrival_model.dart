import 'package:freezed_annotation/freezed_annotation.dart';

part 'bus_arrival_model.freezed.dart';
part 'bus_arrival_model.g.dart';

@freezed
sealed class BusArrivalModel with _$BusArrivalModel {
  const factory BusArrivalModel({
    required String predictTime1, // 예상 시간 분 단위
    required String predictTime2,
    int? predictTimeSec1, // 예상 시간 초 단위
    int? predictTimeSec2,
    required String locationNo1, // 몇 정거장 전
    required String locationNo2,
    required String stationNm1, // 현재 있는 곳
    required String stationNm2,
    required String flag,
    required String routeDestName,
    required int routeId,
    required int stationId,
  }) = _BusArrivalModel;

  factory BusArrivalModel.fromJson(Map<String, dynamic> json) =>
      _$BusArrivalModelFromJson(json);
}
