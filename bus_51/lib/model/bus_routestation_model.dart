// --------------------------------------------------
// 버스 노선 정류장 Model (UI용 데이터 구조)
// --------------------------------------------------
class BusRouteStationModel {
  final String centerYn;
  final int districtCd;
  final String mobileNo;
  final String regionName;
  final int stationId;
  final String stationName;
  final double x;
  final double y;
  final String adminName;
  final int stationSeq;
  final int turnSeq;
  final String turnYn;

  const BusRouteStationModel({
    required this.centerYn,
    required this.districtCd,
    required this.mobileNo,
    required this.regionName,
    required this.stationId,
    required this.stationName,
    required this.x,
    required this.y,
    required this.adminName,
    required this.stationSeq,
    required this.turnSeq,
    required this.turnYn,
  });

  @override
  String toString() {
    return 'BusRouteStationModel(centerYn: $centerYn, districtCd: $districtCd, mobileNo: $mobileNo, regionName: $regionName, stationId: $stationId, stationName: $stationName, x: $x, y: $y, adminName: $adminName, stationSeq: $stationSeq, turnSeq: $turnSeq, turnYn: $turnYn)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusRouteStationModel &&
        other.centerYn == centerYn &&
        other.districtCd == districtCd &&
        other.mobileNo == mobileNo &&
        other.regionName == regionName &&
        other.stationId == stationId &&
        other.stationName == stationName &&
        other.x == x &&
        other.y == y &&
        other.adminName == adminName &&
        other.stationSeq == stationSeq &&
        other.turnSeq == turnSeq &&
        other.turnYn == turnYn;
  }

  @override
  int get hashCode {
    return Object.hash(centerYn, districtCd, mobileNo, regionName, stationId, stationName, x, y, adminName, stationSeq, turnSeq, turnYn);
  }
}
