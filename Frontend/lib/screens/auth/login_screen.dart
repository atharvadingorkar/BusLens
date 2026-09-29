import 'package:flutter/material.dart';

import 'package:buslens/services/api_service.dart';
import 'package:buslens/screens/passenger/passenger_home_screen.dart';
import 'package:buslens/screens/operator/operator_dashboard_screen.dart';
import 'package:buslens/screens/admin/admin_dashboard_screen.dart';
import 'package:buslens/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'Passenger';

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  bool isLoading = false;

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.login(
        email,
        password,
        selectedRole,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (result['success'] == true) {
        if (selectedRole == 'Passenger') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PassengerHomeScreen(
                userId: (result['user_id'] as num).toInt(),
                fullName: result['full_name'] ?? 'Passenger',
                email: result['email'] ?? '',
              ),
            ),
          );
        } else if (selectedRole == 'Operator') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OperatorDashboardScreen(
                operatorId: result['user_id'],
              ),
            ),
          );
        } else if (selectedRole == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const AdminDashboardScreen(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'Invalid email, password or role',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to connect to server. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BusLens Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Select Role',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Passenger',
                  child: Text('Passenger'),
                ),
                DropdownMenuItem(
                  value: 'Operator',
                  child: Text('Operator'),
                ),
                DropdownMenuItem(
                  value: 'Admin',
                  child: Text('Admin'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : handleLogin,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('Register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}