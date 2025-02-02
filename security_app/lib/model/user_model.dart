import 'dart:io';

class RegisteredUser {
  final int? id;
  final String name;
  final File image;

  RegisteredUser({
    this.id,
    required this.name,
    required this.image,
  });
}
