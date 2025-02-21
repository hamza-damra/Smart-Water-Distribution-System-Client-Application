import 'package:flutter/material.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:provider/provider.dart';
import 'package:mytank/providers/forgot_password_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final forgotPasswordProvider = Provider.of<ForgotPasswordProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            forgotPasswordProvider.isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                try {
                  await forgotPasswordProvider.submitEmail(_emailController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset email sent!')),
                  );
                  Navigator.pushReplacementNamed(context, RouteManager.loginRoute);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send reset email: $e')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}