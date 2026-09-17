// --------------------------------------------------
// 도착 남은 시간 표기 규칙 (리스트 카드 · 메인 히어로 공용)
// 공공 API 예측은 1분 단위 오차가 있어 2분 미만은 숫자 대신 "잠시 후 도착"으로 보여준다
// --------------------------------------------------

/// 이 값(초) 미만이면 "잠시 후 도착"
const int kArrivingSoonSeconds = 120;

const String kArrivingSoonLabel = '잠시 후 도착';

bool isArrivingSoon(int seconds) => seconds < kArrivingSoonSeconds;

/// 남은 초 → MM:SS (60분 이상이면 분이 세 자리로 늘어남)
String formatMmss(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

/// 2분 미만이면 "잠시 후 도착", 아니면 MM:SS
String formatArrival(int seconds) => isArrivingSoon(seconds) ? kArrivingSoonLabel : formatMmss(seconds);

/// API 응답의 초 단위 필드가 비어 오는 경우가 있어 분 단위로 폴백한다
int arrivalSeconds({required String sec, required String min}) {
  return int.tryParse(sec) ?? ((int.tryParse(min) ?? 0) * 60);
}
