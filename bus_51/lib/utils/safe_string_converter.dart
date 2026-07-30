import 'package:freezed_annotation/freezed_annotation.dart';

// --------------------------------------------------
// 공공데이터 API 응답의 타입 혼재(int, double, String 등) 대응용 컨버터
// 어떤 스칼라 타입이 와도 안전하게 String으로 변환한다
// --------------------------------------------------
class SafeStringConverter implements JsonConverter<String, dynamic> {
  const SafeStringConverter();

  @override
  String fromJson(dynamic json) => json?.toString() ?? '';

  @override
  dynamic toJson(String object) => object;
}
