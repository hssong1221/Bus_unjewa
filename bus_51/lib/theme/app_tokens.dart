// --------------------------------------------------
// 디자인 토큰
// 화면마다 제각각이던 간격/반경 숫자를 한 곳에 모은다.
// 카드는 AppRadius.card, 카드 안의 요소(버튼·배지·내부 박스)는 AppRadius.inner
// --------------------------------------------------

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  /// 카드, 큰 버튼
  static const double card = 16;

  /// 카드 내부 요소 (작은 버튼, 배지, 내부 박스)
  static const double inner = 12;

  /// 알약형 (태그, 세그먼트)
  static const double pill = 999;
}

/// 플랫 카드 테두리 불투명도 (outline 색 기준)
const double kCardBorderAlpha = 0.2;
