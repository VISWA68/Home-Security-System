import 'package:flutter/material.dart';
import 'package:security_app/model/user_model.dart';
import 'package:security_app/pages/add_face.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
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
                Switch(value: true, onChanged: (value) {}),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Register Faces',
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
                    child: Row(
                      children: UserRegistry.users.map((user) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: FileImage(user.image),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddFace(),
                        ));
                  },
                  child: Text('Add Face'),
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
