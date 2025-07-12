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

    // 중복 체크: 모든 필드가 동일한 경우
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
}
