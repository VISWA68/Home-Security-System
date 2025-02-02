import 'dart:io';
import 'package:flutter/material.dart';
import 'package:security_app/model/user_model.dart';
import 'package:security_app/database/database_helper.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<RegisteredUser> _users = [];
  
  List<RegisteredUser> get users => _users;

  Future<void> loadUsers() async {
    _users = await _databaseHelper.getUsers();
    notifyListeners();
  }

  Future<void> addUser(String name, File image) async {
    final user = RegisteredUser(name: name, image: image);
    await _databaseHelper.insertUser(user);
    await loadUsers(); 
  }

  Future<void> deleteUser(int id) async {
    await _databaseHelper.deleteUser(id);
    await loadUsers(); 
  }
}
