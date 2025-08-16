import 'package:freezed_annotation/freezed_annotation.dart';

part 'busroute_entity.freezed.dart';

// --------------------------------------------------
// 버스 노선 Entity
// --------------------------------------------------
// NOTE: 향후 Entity-Mapper-Model 구조를 단순화할 때
//       이 Entity를 UI에서 직접 사용 가능
//       (Model과 Mapper 제거 고려)
// --------------------------------------------------
@Freezed(fromJson: false)
sealed class BusRouteEntity with _$BusRouteEntity {
  const factory BusRouteEntity({
    required String regionName,
    required int routeDestId,
    required String routeDestName,
    required int routeId,
    required String routeName,
    required int routeTypeCd,
    required String routeTypeName,
    required int staOrder,
  }) = _BusRouteEntity;

  factory BusRouteEntity.fromJson(Map<String, dynamic> json) {
    return BusRouteEntity(
      regionName: json['regionName'],
      routeDestId: json['routeDestId'],
      routeDestName: json['routeDestName'],
      routeId: json['routeId'],
      routeName: json['routeName'].toString(), // 명시적 변환
      routeTypeCd: json['routeTypeCd'],
      routeTypeName: json['routeTypeName'],
      staOrder: json['staOrder'],
    );
  }
}
