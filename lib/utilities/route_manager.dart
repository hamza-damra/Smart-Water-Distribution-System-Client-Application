import 'package:flutter/material.dart';
import 'package:mytank/screens/login_screen.dart';
import 'package:mytank/screens/forgotPassword_screen.dart';
import 'package:mytank/screens/updatePassword_screen.dart';
import 'package:mytank/screens/update_data_screen.dart';
import 'package:mytank/screens/home_screen.dart';

class RouteManager {
  static const String loginRoute = '/';
  static const String forgotPasswordRoute = '/forgotPassword';
  static const String updatePasswordRoute = '/updatePassword';
  static const String updateDataRoute = '/updateData';
  static const String homeRoute = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case updatePasswordRoute:
        return MaterialPageRoute(builder: (_) => UpdatePasswordScreen());
      case updateDataRoute:
        return MaterialPageRoute(builder: (_) => UpdateDataScreen());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      default:
        throw FormatException('Route not found! Check routes again.');
    }
  }
}