import 'dart:io';
import 'package:flutter/material.dart';
import 'package:security_app/model/user_model.dart';

class UserProvider extends ChangeNotifier {
  final List<RegisteredUser> _users = [];

  List<RegisteredUser> get users => _users;

  void addUser(String name, File image) {
    _users.add(RegisteredUser(name: name, image: image));
    notifyListeners();
  }

  void deleteUser(int index) {
    _users.removeAt(index);
    notifyListeners();
  }
}