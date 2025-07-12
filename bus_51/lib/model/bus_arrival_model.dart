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

  BusArrivalModel({
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
}
