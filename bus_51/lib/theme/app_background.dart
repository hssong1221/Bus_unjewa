import 'package:flutter/material.dart';

// --------------------------------------------------
// 앱 공통 무채색 배경
// 색상 규칙: 배경/카드는 무채색, 앱 초록(primary)은 버튼·선택 상태 등
// 인터랙션에만, 버스 노선 색은 노선번호 배지·도착 강조 같은 포인트에만 쓴다
// --------------------------------------------------
BoxDecoration appBackgroundDecoration(ColorScheme colorScheme) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.surfaceContainerLow,
        colorScheme.surface,
      ],
    ),
  );
}
