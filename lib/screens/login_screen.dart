import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mytank/screens/updatePassword_screen.dart';
import 'forgotPassword_screen.dart';
import 'update_data_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identityNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String identityNumber = _identityNumberController.text.trim();
    final String password = _passwordController.text.trim();

    final Uri url = Uri.parse('https://smart-water-distribution-system.onrender.com/api/customer/login');
    final Map<String, String> body = {
      'identity_number': identityNumber,
      'password': password,
    };

    try {
      final response = await http.post(
        url,
        body: json.encode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String token = data['token'];
        if (kDebugMode) {
          print('Login Successful! Token: $token');
        }

        // Navigate to the next screen or show a success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login Successful!')),
          );
        }
      } else {
        if (kDebugMode) {
          print('Login Failed: ${response.body}');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login Failed: Invalid credentials')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _identityNumberController,
              decoration: InputDecoration(
                labelText: 'Identity Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to the Forgot Password Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForgotPasswordScreen(),
                  ),
                );
              },
              child: Text('Forgot Password?'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to the Update Password Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdatePasswordScreen(),
                  ),
                );
              },
              child: Text('Update Password'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to the Update Data Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateDataScreen(),
                  ),
                );
              },
              child: Text('Update Profile Data'),
            ),
          ],
        ),
      ),
    );
  }
}