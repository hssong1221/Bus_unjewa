import 'package:bus_51/enums/bus_enums.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/service/dio_singleton.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class StorageService {
  final Dio _dio = DioSingleton.getInstance();
  final GetStorage box = GetStorage();

  //delete
  void deleteUserData() {
    box.remove("user_save_data");
  }

  //save
  /*Future<void> _saveUserModel(UserSaveModel order) async {
    await box.write('user_save_data', order.toMap());
  }*/

  Future<void> _saveUserModelList(List<UserSaveModel> users) async {
    final userListMap = users.map((user) => user.toMap()).toList();
    await box.write('user_save_data', userListMap);
  }

  // load
 /* UserSaveModel? loadUserModel() {
    final map = box.read('user_save_data');
    if (map != null) {
      return UserSaveModel.fromMap(Map<String, dynamic>.from(map));
    }
    return null;
  }*/

  List<UserSaveModel> loadUserModelList() {
    final list = box.read('user_save_data');
    debugPrint(list.toString());

    if (list != null && list is List) {
      return list
          .map((item) => UserSaveModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  // 중복이 없을 때만 추가
  Future<void> addUserSaveModel(UserSaveModel newUser) async {
    final list = loadUserModelList();

    // 중복 체크: 정류장, 노선, 순서, 버스타입이 모두 동일한 경우
    final exists = list.any((user) =>
    user.stationId == newUser.stationId &&
        user.routeId == newUser.routeId &&
        user.staOrder == newUser.staOrder &&
        user.busType == newUser.busType
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

  // 특정 인덱스의 버스 타입 변경
  Future<void> updateBusType(int index, BusType newBusType) async {
    final list = loadUserModelList();
    
    if (index >= 0 && index < list.length) {
      // 기존 데이터를 복사하고 busType만 변경
      final updatedUser = list[index].copyWith(busType: newBusType);
      list[index] = updatedUser;
      await _saveUserModelList(list);
    }
  }
}
