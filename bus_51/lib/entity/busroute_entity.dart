import 'package:freezed_annotation/freezed_annotation.dart';

part 'busroute_entity.freezed.dart';
part 'busroute_entity.g.dart';

// --------------------------------------------------
// 버스 노선 Entity
// --------------------------------------------------
// NOTE: 향후 Entity-Mapper-Model 구조를 단순화할 때
//       이 Entity를 UI에서 직접 사용 가능
//       (Model과 Mapper 제거 고려)
// --------------------------------------------------
@Freezed()
sealed class BusRouteEntity with _$BusRouteEntity {
  const factory BusRouteEntity({
    required String regionName,
    required String routeDestId,
    required String routeDestName,
    required String routeId,
    required String routeName,
    required String routeTypeCd,
    required String routeTypeName,
    required String staOrder,
  }) = _BusRouteEntity;

  factory BusRouteEntity.fromJson(Map<String, dynamic> json) => _$BusRouteEntityFromJson(json);
}
