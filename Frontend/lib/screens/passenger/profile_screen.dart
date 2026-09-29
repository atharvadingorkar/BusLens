import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final int userId;
  final String fullName;
  final String email;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.fullName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(
                Icons.person,
                size: 50,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Name'),
                subtitle: Text(fullName),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(email),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('User ID'),
                subtitle: Text(userId.toString()),
              ),
            ),

            const Card(
              child: ListTile(
                leading: Icon(Icons.confirmation_number),
                title: Text('Total Tickets'),
                subtitle: Text('5'),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}