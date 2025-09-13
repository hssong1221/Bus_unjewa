import 'package:freezed_annotation/freezed_annotation.dart';

part 'bus_arrival_entity.freezed.dart';
part 'bus_arrival_entity.g.dart';

// --------------------------------------------------
// 버스 도착 정보 Entity
// --------------------------------------------------
// NOTE: 향후 Entity-Mapper-Model 구조를 단순화할 때
//       이 Entity를 UI에서 직접 사용 가능
//       (Model과 Mapper 제거 고려)
// --------------------------------------------------
@Freezed()
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
    required String routeDestId,
    required String routeDestName,
    required String routeId,
    required String routeName,
    required String routeTypeCd,
    required String staOrder,
    required String stationId,
    required String stationNm1,
    required String stationNm2,
    required String taglessCd1,
    required String taglessCd2,
    required String turnSeq,
    required String vehId1,
    required String vehId2,
    @Default('0') String? predictTimeSec1,
    @Default('0') String? predictTimeSec2,
  }) = _BusArrivalEntity;

  factory BusArrivalEntity.fromJson(Map<String, dynamic> json) => _$BusArrivalEntityFromJson(json);
}
