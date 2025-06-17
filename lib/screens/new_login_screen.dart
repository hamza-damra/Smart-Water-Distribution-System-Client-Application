import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mytank/components/custom_button.dart';
import 'package:mytank/components/custom_text.dart';
import 'package:mytank/components/custom_text_field.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/utilities/custom_toast.dart';

class UserProvider extends ChangeNotifier {
  String? userId;
  String? fullName;

  void setUser(String id) {
    userId = id;
    notifyListeners();
  }

  void setName(String name) {
    fullName = name;
    notifyListeners();
  }
}

class NewLoginScreen extends StatefulWidget {
  const NewLoginScreen({super.key});

  @override
  State<NewLoginScreen> createState() => _NewLoginScreenState();
}

class _NewLoginScreenState extends State<NewLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text;
    final String password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('http://54.208.4.191/api/user/login'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = json.decode(response.body);
      debugPrint(responseData.toString());

      if (response.statusCode == 200 && responseData['success']) {
        debugPrint('Login success: ${responseData['message']}');
        final token =
            responseData['data']; // Extract the token from the response

        // Store the token for future use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // Show success toast
        if (mounted) {
          CustomToast.showSuccess(context, 'Login successful! Welcome back.');
          getUserInfoById(token);
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (response.statusCode == 200 && !responseData['success']) {
        // Show error toast for invalid credentials
        if (mounted) {
          CustomToast.showError(
            context,
            'Invalid email or password. Please try again.',
          );
        }
      } else {
        // Show error toast for other errors
        if (mounted) {
          CustomToast.showError(
            context,
            'Error logging in: ${responseData['message']}',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show network error toast for exceptions
      if (mounted) {
        CustomToast.showNetworkError(context, e);
      }
    }
  }

  Future<void> getUserInfoById(String token) async {
    debugPrint('User token: $token');
    const url = 'http://54.208.4.191/api/user/get-user-info-by-id';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
        body: {'token': token},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final success = responseData['success'];
        final data = responseData['data'];

        if (success) {
          // User exists, handle the data
          debugPrint('User Info: $data');
          final userID = responseData['data']['_id'];
          final name = responseData['data']['fullName'];

          // Update the provider with user info
          if (mounted) {
            // Adapt this to your provider implementation
            Provider.of<UserProvider>(context, listen: false).setUser(userID);
            Provider.of<UserProvider>(context, listen: false).setName(name);
          }
        } else {
          // User doesn't exist
          final message = responseData['message'];
          debugPrint('User Info Error: $message');
        }
      } else {
        debugPrint('User Info Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Constants.primaryColor, Constants.secondaryColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Settings icon in top left
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/server-config');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                // Top section with logo and welcome text
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 30),
                  child: Column(
                    children: [
                      // Logo container
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          size: 50,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const CustomText(
                        'Smart Water System',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      const CustomText(
                        'Login to your account',
                        fontSize: 16,
                        fontColor: Colors.white70,
                      ),
                    ],
                  ),
                ),

                // Login card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email field
                        const CustomText(
                          'Email',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontColor: Colors.black87,
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          label: 'Email',
                          mediaQueryData: MediaQuery.of(context),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'Enter your email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Password field
                        const CustomText(
                          'Password',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontColor: Colors.black87,
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          label: 'Password',
                          mediaQueryData: MediaQuery.of(context),
                          controller: _passwordController,
                          obscure: _obscurePassword,
                          keyboardType: TextInputType.visiblePassword,
                          hintText: 'Enter your password',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Constants.primaryColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to forgot password screen
                              // Navigator.pushNamed(context, '/forgot-password');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                            ),
                            child: const Text('Forgot Password?'),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login button
                        _isLoading
                            ? Center(
                              child: CircularProgressIndicator(
                                color: Constants.primaryColor,
                              ),
                            )
                            : GestureDetector(
                              onTap: loginUser,
                              child: CustomButton(
                                'Login',
                                mediaQueryData: MediaQuery.of(context),
                                width: double.infinity,
                                onPressed: loginUser,
                              ),
                            ),

                        // Sign up option
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                "Don't have an account?",
                                fontSize: 14,
                                fontColor: Colors.grey.shade600,
                                fontWeight: FontWeight.normal,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signin');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                ),
                                child: const CustomText(
                                  'Sign Up',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontColor: Constants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.water_drop_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.eco_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.opacity_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Efficient Water Management Solution',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
