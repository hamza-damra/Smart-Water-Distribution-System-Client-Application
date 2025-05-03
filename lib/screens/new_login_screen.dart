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

        // Show success dialog with modern styling
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 10),
                    const Text('Success'),
                  ],
                ),
                content: const Text('User logged in successfully'),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      getUserInfoById(token);
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                ],
              );
            },
          );
        }
      } else if (response.statusCode == 200 && !responseData['success']) {
        // Show error dialog for invalid credentials
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 10),
                    const Text('Error'),
                  ],
                ),
                content: const Text('Invalid email or password'),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        // Show error dialog for other errors
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 10),
                    const Text('Error'),
                  ],
                ),
                content: Text('Error logging in: ${responseData['message']}'),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error dialog for exceptions
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  const SizedBox(width: 10),
                  const Text('Error'),
                ],
              ),
              content: Text('Error: $e'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
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
                // Top section with logo and welcome text
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 30),
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
