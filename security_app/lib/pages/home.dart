import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_app/pages/add_face.dart';
import 'package:security_app/pages/display.dart';
import 'package:security_app/provider/detection_provider.dart';
import 'package:security_app/provider/user_provider.dart';
import 'package:security_app/services/api_services.dart';
import 'package:security_app/services/authentication_service.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthenticationService _authService = AuthenticationService();
  ApiService _apiService = ApiService();
  int _currentIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetectionDisplay(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Home Security',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Security System',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<DetectionProvider>(
                  builder: (context, detectionProvider, child) {
                    return Switch(
                      value: detectionProvider.isDetecting,
                      onChanged: (value) {
                        if (value) {
                          detectionProvider.startDetection();
                        } else {
                          detectionProvider.stopDetection();
                        }
                      },
                      activeColor: const Color.fromARGB(255, 55, 118, 229),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Registered Faces',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return (userProvider.users.isEmpty)
                            ? Text(
                                "No users added",
                                style: TextStyle(color: Colors.red),
                              )
                            : Row(
                                children: List.generate(
                                  userProvider.users.length,
                                  (index) {
                                    final user = userProvider.users[index];
                                    return InkWell(
                                      onLongPress: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Delete User'),
                                            content: Text(
                                                'Do you want to delete ${user.name}?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  try {
                                                    bool authenticated =
                                                        await _authService
                                                            .authenticateWithBiometrics(
                                                                context);

                                                    if (!authenticated) {
                                                      _authService
                                                          .showAuthenticationError(
                                                              context);
                                                      return;
                                                    }

                                                    // Add loading indicator
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (BuildContext
                                                          context) {
                                                        return Center(
                                                            child:
                                                                CircularProgressIndicator());
                                                      },
                                                    );

                                                    bool res = await _apiService
                                                        .deleteFace(user.name);

                                                    // Print for debugging
                                                    print(
                                                        'Delete Response: $res');

                                                    // Remove loading indicator
                                                    Navigator.pop(context);

                                                    if (res) {
                                                      // Success case
                                                      userProvider
                                                          .deleteUser(user.id!);
                                                      Navigator.pop(
                                                          context); // Close the delete confirmation dialog
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Successfully deleted user')),
                                                      );
                                                    } else {
                                                      // Failure case
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Failed to delete face'),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    // Remove loading indicator if it's showing
                                                    Navigator.pop(context);
                                                    print(
                                                        'Error in delete operation: $e'); // Add debug print
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'An error occurred: ${e.toString()}'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 40,
                                              backgroundImage:
                                                  FileImage(user.image),
                                            ),
                                            Text(user.name),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                      },
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFace(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.elliptical(12, 12)))),
                  child: Text(
                    'Add Face',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text('Unauthorized Face Detected'),
                subtitle: Text('Front Door Camera'),
                trailing: Text('2 mins ago'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('System Armed'),
                subtitle: Text('Main Control'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 10),
                    SizedBox(width: 5),
                    Text('10 mins ago'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
