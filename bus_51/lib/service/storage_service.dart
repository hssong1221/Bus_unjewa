import 'dart:convert';

import 'package:bus_51/model/user_save_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService(this._prefs);

  /// 캐시 기반이라 읽기는 동기, 쓰기는 캐시 즉시 반영 후 비동기 영속화
  final SharedPreferencesWithCache _prefs;

  static const String _userSaveKey = 'user_save_data';

  //delete
  void deleteUserData() {
    _prefs.remove(_userSaveKey);
  }

  //save
  Future<void> _saveUserModelList(List<UserSaveModel> users) async {
    final userListJson = jsonEncode(users.map((user) => user.toMap()).toList());
    await _prefs.setString(_userSaveKey, userListJson);
  }

  // load
  List<UserSaveModel> loadUserModelList() {
    final jsonString = _prefs.getString(_userSaveKey);
    debugPrint(jsonString);

    if (jsonString == null) return [];

    try {
      final list = jsonDecode(jsonString);
      if (list is List) {
        return list
            .map((item) => UserSaveModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {
      // 필드 구성이 다른 구버전 저장 데이터(stationName/routeDestName 없음)는
      // 마이그레이션하지 않고 버린다 (배포 전 결정)
    }
    return [];
  }

  // 중복이 없을 때만 추가
  Future<void> addUserSaveModel(UserSaveModel newUser) async {
    final list = loadUserModelList();

    // 중복 체크: 정류장, 노선, 순서가 모두 동일한 경우
    final exists = list.any((user) =>
    user.stationId == newUser.stationId &&
        user.routeId == newUser.routeId &&
        user.staOrder == newUser.staOrder
    );

    if (!exists) {
      list.add(newUser);
      await _saveUserModelList(list);
    }
    // 이미 있으면 아무것도 하지 않음
  }

  // 선택한 인덱스들 삭제
  Future<void> removeItems(List<int> indices) async {
    final list = loadUserModelList();

    // 인덱스를 역순으로 정렬해서 삭제 (높은 인덱스부터 삭제해야 인덱스 꼬임 방지)
    final sortedIndices = indices.toList()..sort((a, b) => b.compareTo(a));

    for (int index in sortedIndices) {
      if (index >= 0 && index < list.length) {
        list.removeAt(index);
      }
    }

    await _saveUserModelList(list);
  }
}
