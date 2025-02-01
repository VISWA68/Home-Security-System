import 'dart:io';

class RegisteredUser {
  final String name;
  final File image;

  RegisteredUser({required this.name, required this.image});
}

class UserRegistry {
  static final List<RegisteredUser> users = [];
}