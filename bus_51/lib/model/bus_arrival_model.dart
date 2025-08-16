// --------------------------------------------------
// 버스 도착 정보 Model (UI용 데이터 구조)
// --------------------------------------------------
class BusArrivalModel {
  final String predictTime1; // 예상 시간 분 단위
  final String predictTime2;
  final int? predictTimeSec1; // 예상 시간 초 단위
  final int? predictTimeSec2;
  final String locationNo1; // 몇 정거장 전
  final String locationNo2;
  final String stationNm1; // 현재 있는 곳
  final String stationNm2;
  final String flag;
  final String routeDestName;
  final int routeId;
  final int stationId;

  const BusArrivalModel({
    required this.predictTime1,
    required this.predictTime2,
    this.predictTimeSec1,
    this.predictTimeSec2,
    required this.locationNo1,
    required this.locationNo2,
    required this.stationNm1,
    required this.stationNm2,
    required this.flag,
    required this.routeDestName,
    required this.routeId,
    required this.stationId,
  });

  @override
  String toString() {
    return 'BusArrivalModel(predictTime1: $predictTime1, predictTime2: $predictTime2, predictTimeSec1: $predictTimeSec1, predictTimeSec2: $predictTimeSec2, locationNo1: $locationNo1, locationNo2: $locationNo2, stationNm1: $stationNm1, stationNm2: $stationNm2, flag: $flag, routeDestName: $routeDestName, routeId: $routeId, stationId: $stationId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusArrivalModel &&
        other.predictTime1 == predictTime1 &&
        other.predictTime2 == predictTime2 &&
        other.predictTimeSec1 == predictTimeSec1 &&
        other.predictTimeSec2 == predictTimeSec2 &&
        other.locationNo1 == locationNo1 &&
        other.locationNo2 == locationNo2 &&
        other.stationNm1 == stationNm1 &&
        other.stationNm2 == stationNm2 &&
        other.flag == flag &&
        other.routeDestName == routeDestName &&
        other.routeId == routeId &&
        other.stationId == stationId;
  }

  @override
  int get hashCode {
    return Object.hash(predictTime1, predictTime2, predictTimeSec1, predictTimeSec2, locationNo1, locationNo2, stationNm1, stationNm2, flag, routeDestName, routeId, stationId);
  }
}
