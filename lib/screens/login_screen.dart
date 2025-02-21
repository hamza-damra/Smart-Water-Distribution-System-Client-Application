import 'package:flutter/material.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identityNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, RouteManager.homeRoute);
      });
    }

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
            authProvider.isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                try {
                  await authProvider.login(
                    _identityNumberController.text.trim(),
                    _passwordController.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Login Successful!')),
                  );
                  Navigator.pushReplacementNamed(context, RouteManager.homeRoute);
                } catch (e) {
                  // Show only the specific error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Login Failed: Invalid credentials')),
                  );
                }
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteManager.forgotPasswordRoute);
              },
              child: Text('Forgot Password?'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteManager.updatePasswordRoute);
              },
              child: Text('Update Password'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteManager.updateDataRoute);
              },
              child: Text('Update Profile Data'),
            ),
          ],
        ),
      ),
    );
  }
}