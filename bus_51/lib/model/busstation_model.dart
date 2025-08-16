// --------------------------------------------------
// 버스 정류장 Model (UI용 데이터 구조)
// --------------------------------------------------
class BusStationModel {
  final String mobileNo;
  final String regionName;
  final int stationId;
  final String stationName;
  final int distance;
  final double x;
  final double y;

  const BusStationModel({
    required this.mobileNo,
    required this.regionName,
    required this.stationId,
    required this.stationName,
    required this.distance,
    required this.x,
    required this.y,
  });

  @override
  String toString() {
    return 'BusStationModel(mobileNo: $mobileNo, regionName: $regionName, stationId: $stationId, stationName: $stationName, distance: $distance, x: $x, y: $y)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusStationModel &&
        other.mobileNo == mobileNo &&
        other.regionName == regionName &&
        other.stationId == stationId &&
        other.stationName == stationName &&
        other.distance == distance &&
        other.x == x &&
        other.y == y;
  }

  @override
  int get hashCode {
    return Object.hash(mobileNo, regionName, stationId, stationName, distance, x, y);
  }
}
