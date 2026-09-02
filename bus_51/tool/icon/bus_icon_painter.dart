// 앱 아이콘 도형 (시안 B1). 런처 아이콘과 스토어 그래픽이 함께 쓴다.
import 'package:flutter/material.dart';

const iconTeal = Color(0xFF009775); // colorScheme.primary
const iconMint = Color(0xFFB2DFDB); // colorScheme.primaryContainer
const iconRoof = Color(0xFF007A5F); // 지붕띠 (primary 보다 한 단계 진하게)
const iconTire = Color(0xFF00201C); // colorScheme.onPrimaryContainer

/// 민트 바탕, 오른쪽을 향한 청록 버스 측면 + 왼쪽 속도선.
/// 1024×1024 좌표계. 도형은 adaptive icon 안전 영역(중앙 66%) 안에 둔다.
void drawBusIcon(Canvas c, {required bool withBackground}) {
  final paint = Paint();
  if (withBackground) {
    c.drawRect(const Rect.fromLTWH(0, 0, 1024, 1024), paint..color = iconMint);
  }

  void rr(double x, double y, double w, double h, double r, Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      paint..color = color,
    );
  }

  void circle(double x, double y, double r, Color color) {
    c.drawCircle(Offset(x, y), r, paint..color = color);
  }

  // 속도선
  rr(182, 432, 104, 30, 15, iconTeal);
  rr(222, 500, 64, 30, 15, iconTeal);
  rr(182, 568, 104, 30, 15, iconTeal);

  // 버스 (원점 322,372)
  c.save();
  c.translate(322, 372);

  final body = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, 520, 264),
    const Radius.circular(64),
  );
  c.save();
  c.clipRRect(body);
  c.drawRRect(body, paint..color = iconTeal);
  c.drawRect(const Rect.fromLTWH(0, 0, 520, 52), paint..color = iconRoof); // 지붕띠
  rr(48, 76, 96, 96, 22, iconMint);
  rr(164, 76, 96, 96, 22, iconMint);
  rr(280, 76, 96, 96, 22, iconMint);
  rr(400, 76, 92, 96, 22, iconMint); // 앞유리
  circle(486, 214, 16, iconMint); // 헤드라이트
  c.restore();

  circle(112, 268, 56, iconTire);
  circle(112, 268, 22, iconMint);
  circle(408, 268, 56, iconTire);
  circle(408, 268, 22, iconMint);

  c.restore();
}
