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
    @Default('') String crowded1,
    @Default('') String crowded2,
    @Default('') String flag,
    @Default('') String locationNo1,
    @Default('') String locationNo2,
    @Default('') String lowPlate1,
    @Default('') String lowPlate2,
    @Default('') String plateNo1,
    @Default('') String plateNo2,
    @Default('') String predictTime1,
    @Default('') String predictTime2,
    @Default('') String remainSeatCnt1,
    @Default('') String remainSeatCnt2,
    @Default('') String routeDestId,
    @Default('') String routeDestName,
    @Default('') String routeId,
    @Default('') String routeName,
    @Default('') String routeTypeCd,
    @Default('') String staOrder,
    @Default('') String stationId,
    @Default('') String stationNm1,
    @Default('') String stationNm2,
    @Default('') String taglessCd1,
    @Default('') String taglessCd2,
    @Default('') String turnSeq,
    @Default('') String vehId1,
    @Default('') String vehId2,
    @Default('') String predictTimeSec1,
    @Default('') String predictTimeSec2,
  }) = _BusArrivalEntity;

  factory BusArrivalEntity.fromJson(Map<String, dynamic> json) => _$BusArrivalEntityFromJson(json);
}
