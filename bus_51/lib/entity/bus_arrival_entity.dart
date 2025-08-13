import 'package:freezed_annotation/freezed_annotation.dart';

part 'bus_arrival_entity.freezed.dart';
part 'bus_arrival_entity.g.dart';

@Freezed(fromJson: false)
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

  factory BusArrivalEntity.fromJson(Map<String, dynamic> json) {
    return BusArrivalEntity(
      crowded1: json['crowded1'].toString(),
      crowded2: json['crowded2'].toString(),
      flag: json['flag'],
      locationNo1: json['locationNo1'].toString(),
      locationNo2: json['locationNo2'].toString(),
      lowPlate1: json['lowPlate1'].toString(),
      lowPlate2: json['lowPlate2'].toString(),
      plateNo1: json['plateNo1'].toString(),
      plateNo2: json['plateNo2'].toString(),
      predictTime1: json['predictTime1'].toString(),
      predictTime2: json['predictTime2'].toString(),
      remainSeatCnt1: json['remainSeatCnt1'].toString(),
      remainSeatCnt2: json['remainSeatCnt2'].toString(),
      routeDestId: json['routeDestId'],
      routeDestName: json['routeDestName'],
      routeId: json['routeId'],
      routeName: json['routeName'].toString(),
      routeTypeCd: json['routeTypeCd'],
      staOrder: json['staOrder'],
      stationId: json['stationId'],
      stationNm1: json['stationNm1'],
      stationNm2: json['stationNm2'],
      taglessCd1: json['taglessCd1'].toString(),
      taglessCd2: json['taglessCd2'].toString(),
      turnSeq: json['turnSeq'],
      vehId1: json['vehId1'].toString(),
      vehId2: json['vehId2'].toString(),
      predictTimeSec1: json['predictTimeSec1'] ?? 0,
      predictTimeSec2: json['predictTimeSec2'] ?? 0,
    );
  }
}
