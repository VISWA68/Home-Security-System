import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:security_app/provider/user_provider.dart';
import 'package:security_app/services/api_services.dart';
import 'package:security_app/services/authentication_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class AddFace extends StatefulWidget {
  @override
  _AddFaceState createState() => _AddFaceState();
}

class _AddFaceState extends State<AddFace> {
  File? _image;
  File? _thumbnail;
  final ImagePicker _picker = ImagePicker();
  final AuthenticationService _authService = AuthenticationService();
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    bool authenticated = await _authService.authenticateWithBiometrics(context);
    if (!authenticated) {
      _authService.showAuthenticationError(context);
      return;
    }

    final XFile? pickedFile =
        await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      final thumbnail = await _generateThumbnail(pickedFile.path);
      setState(() {
        _image = File(pickedFile.path);
        _thumbnail = thumbnail;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No video selected.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureImage() async {
    bool authenticated = await _authService.authenticateWithBiometrics(context);
    if (!authenticated) {
      _authService.showAuthenticationError(context);
      return;
    }

    final XFile? pickedFile =
        await _picker.pickVideo(source: ImageSource.camera);

    if (pickedFile != null) {
      final thumbnail = await _generateThumbnail(pickedFile.path);
      setState(() {
        _image = File(pickedFile.path);
        _thumbnail = thumbnail;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No image selected.'),
          backgroundColor: Colors.red,
        ),
      );
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
            decoration: InputDecoration(hintText: 'Enter Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty && _image != null) {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          Center(child: CircularProgressIndicator()),
                    );

                    bool authenticated =
                        await _authService.authenticateWithBiometrics(context);
                    if (!authenticated) {
                      Navigator.pop(context);
                      _authService.showAuthenticationError(context);
                      return;
                    }

                    var res = await _apiService.registerFace(
                      _image!.path,
                      _nameController.text,
                    );

                    Navigator.pop(context);

                    if (res == "success") {
                      context.read<UserProvider>().addUser(
                            _nameController.text,
                            _thumbnail!,
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Face registered successfully!')),
                      );
                    } else if (res == "warning") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('User already exists. Face data updated.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Failed to register face. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('An error occurred: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<File?> _generateThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );

      return thumbnailPath != null ? File(thumbnailPath) : null;
    } catch (e) {
      print("Error generating thumbnail: $e");
      return null;
    }
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
                  icon: Icon(Icons.file_copy_outlined,
                      size: 30, color: Colors.white),
                  onPressed: _captureImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.elliptical(12, 12)),
                    ),
                  ),
                  label: Text(
                    'Capture Video',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.file_copy_outlined,
                      size: 30, color: Colors.white),
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.elliptical(12, 12)),
                    ),
                  ),
                  label: Text(
                    'Upload Video',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _thumbnail != null
                  ? Container(
                      height: 200,
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Placeholder(
                      fallbackHeight: 200, fallbackWidth: double.infinity),
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
                        color: Colors.white, fontWeight: FontWeight.bold),
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
