import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_save_model.freezed.dart';
part 'user_save_model.g.dart';

@freezed
sealed class UserSaveModel with _$UserSaveModel {
  const factory UserSaveModel({
    required String routeName,
    required int stationId,
    required int routeId,
    required int staOrder,
    required int routeTypeCd,
    /// 탑승 정류장 이름 (리스트 카드 표기용)
    required String stationName,
    /// 노선 종점 이름 — 같은 노선 양방향을 구분하는 기준 (리스트 카드 "→ ○○ 방면")
    required String routeDestName,
  }) = _UserSaveModel;

  factory UserSaveModel.fromJson(Map<String, dynamic> json) =>
      _$UserSaveModelFromJson(json);

  // 기존 toMap/fromMap 호환성을 위한 메서드들
  factory UserSaveModel.fromMap(Map<String, dynamic> map) =>
      UserSaveModel.fromJson(map);
}

extension UserSaveModelExtension on UserSaveModel {
  Map<String, dynamic> toMap() => toJson();
}