import 'package:flutter/material.dart';
import 'package:mytank/screens/login_screen.dart';
import 'package:mytank/screens/forgotPassword_screen.dart';
import 'package:mytank/screens/updatePassword_screen.dart';
import 'package:mytank/screens/update_data_screen.dart';
import 'package:mytank/screens/home_screen.dart';
// Import the profile screen
import 'package:mytank/screens/profile_screen.dart';

class RouteManager {
  static const String loginRoute = '/';
  static const String forgotPasswordRoute = '/forgotPassword';
  static const String updatePasswordRoute = '/updatePassword';
  static const String updateDataRoute = '/updateData';
  static const String homeRoute = '/home';
  // New route for the ProfileScreen
  static const String profileRoute = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case updatePasswordRoute:
        return MaterialPageRoute(builder: (_) => const UpdatePasswordScreen());
      case updateDataRoute:
        return MaterialPageRoute(builder: (_) => const UpdateDataScreen());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case profileRoute:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        throw const FormatException('Route not found! Check routes again.');
    }
  }
}
