import 'package:freezed_annotation/freezed_annotation.dart';

part 'busstation_entity.freezed.dart';
part 'busstation_entity.g.dart';

// --------------------------------------------------
// 버스 정류장 Entity
// --------------------------------------------------
// NOTE: 향후 Entity-Mapper-Model 구조를 단순화할 때
//       이 Entity를 UI에서 직접 사용 가능
//       (Model과 Mapper 제거 고려)
// --------------------------------------------------
@Freezed()
sealed class BusStationEntity with _$BusStationEntity {
  const factory BusStationEntity({
    required String centerYn,
    required String mobileNo,    // 정류소 번호
    required String regionName,
    required String stationId,   // 정류소 id
    required String stationName, // 정류소 이름
    required String x,
    required String y,
    required String distance,
  }) = _BusStationEntity;

  factory BusStationEntity.fromJson(Map<String, dynamic> json) => _$BusStationEntityFromJson(json);
}
