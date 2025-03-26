import 'package:flutter/material.dart';
import 'package:mytank/screens/login_screen.dart';
import 'package:mytank/screens/forgotPassword_screen.dart';
import 'package:mytank/screens/updatePassword_screen.dart';
import 'package:mytank/screens/update_data_screen.dart';
import 'package:mytank/screens/home_screen.dart';
import 'package:mytank/screens/profile_screen.dart';
import 'package:mytank/screens/tanks_screen.dart';
import 'package:mytank/screens/tank_details_screen.dart'; // Import TankDetailsScreen

class RouteManager {
  static const String loginRoute = '/';
  static const String forgotPasswordRoute = '/forgotPassword';
  static const String updatePasswordRoute = '/updatePassword';
  static const String updateDataRoute = '/updateData';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String tanksRoute = '/tanks';
  static const String tankDetailsRoute = '/tankDetails';

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
      case tankDetailsRoute:
        final tankId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TankDetailsScreen(tankId: tankId),
        );
      case profileRoute:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case tanksRoute:
        return MaterialPageRoute(builder: (_) => const TanksScreen());
      default:
        throw const FormatException('Route not found! Check routes again.');
    }
  }
}
