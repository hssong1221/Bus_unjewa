import 'package:freezed_annotation/freezed_annotation.dart';

part 'bus_arrival_entity.freezed.dart';
part 'bus_arrival_entity.g.dart';

@freezed
sealed class BusArrivalEntity with _$BusArrivalEntity {
  const factory BusArrivalEntity({
    required String crowded1,
    required String crowded2,
    required String flag,
    required String locationNo1,
    required String locationNo2,
    required String lowPlate1,
    required String lowPlate2,
    required String plateNo1,
    required String plateNo2,
    required String predictTime1,
    required String predictTime2,
    required String remainSeatCnt1,
    required String remainSeatCnt2,
    required int routeDestId,
    required String routeDestName,
    required int routeId,
    required String routeName,
    required int routeTypeCd,
    required int staOrder,
    required int stationId,
    required String stationNm1,
    required String stationNm2,
    required String taglessCd1,
    required String taglessCd2,
    required int turnSeq,
    required String vehId1,
    required String vehId2,
    @Default(0) int? predictTimeSec1,
    @Default(0) int? predictTimeSec2,
  }) = _BusArrivalEntity;

  factory BusArrivalEntity.fromJson(Map<String, dynamic> json) =>
      _$BusArrivalEntityFromJson(json);
}
