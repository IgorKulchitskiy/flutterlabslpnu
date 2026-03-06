import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 40),
            SizedBox(height: 12),
            Text('Igor', style: TextStyle(fontSize: 18)),
            Text('Student'),
          ],
        ),
      ),
    );
  }
}
