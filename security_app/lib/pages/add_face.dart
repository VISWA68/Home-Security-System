import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:security_app/provider/user_provider.dart';
import 'package:security_app/services/authentication_service.dart'; 
class AddFace extends StatefulWidget {
  @override
  _ImagePickerPageState createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<AddFace> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final AuthenticationService _authService = AuthenticationService();

  Future<void> _pickImage(ImageSource source) async {
    bool authenticated = await _authService.authenticateWithBiometrics(context);
    if (!authenticated) {
      _authService.showAuthenticationError(context);
      return;
    }

    // If authenticated, proceed with image picking
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showNameInputDialog() {
    final TextEditingController _nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Name'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty && _image != null) {
                  bool authenticated =
                      await _authService.authenticateWithBiometrics(context);
                  if (!authenticated) {
                    _authService.showAuthenticationError(context);
                    return;
                  }

                  context.read<UserProvider>().addUser(
                        _nameController.text,
                        _image!,
                      );
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 250.0;
    const double buttonHeight = 50.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Register Face',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.camera_alt,
                    size: 30,
                    color: Colors.white,
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.elliptical(12, 12)),
                    ),
                  ),
                  label: Text(
                    'Capture with camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.file_copy_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.elliptical(12, 12)),
                    ),
                  ),
                  label: Text(
                    'Upload from files',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _image != null
                  ? Image.file(
                      _image!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Placeholder(
                      fallbackHeight: 200,
                      fallbackWidth: double.infinity,
                    ),
              SizedBox(height: 20),
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _image != null ? _showNameInputDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.elliptical(12, 12)),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
