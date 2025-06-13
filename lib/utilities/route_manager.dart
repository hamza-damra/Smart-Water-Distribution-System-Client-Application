import 'package:flutter/material.dart';
import 'package:mytank/screens/login_screen.dart';
import 'package:mytank/screens/forgot_password_screen.dart';
import 'package:mytank/screens/update_password_screen.dart';
import 'package:mytank/screens/update_data_screen.dart';
import 'package:mytank/screens/home_screen.dart';
import 'package:mytank/screens/profile_screen.dart';
import 'package:mytank/screens/tanks_screen.dart';
import 'package:mytank/screens/tank_details_screen.dart';
import 'package:mytank/screens/tank_screen.dart';
import 'package:mytank/screens/bills_screen.dart';
import 'package:mytank/screens/payment_screen_custom.dart';
import 'package:mytank/screens/splash_screen.dart';
import 'package:mytank/screens/bill_details_screen.dart';
import 'package:mytank/screens/about_us_screen.dart';
import 'package:mytank/models/bill_model.dart';

class RouteManager {
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String forgotPasswordRoute = '/forgotPassword';
  static const String updatePasswordRoute = '/updatePassword';
  static const String updateDataRoute = '/updateData';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String tanksRoute = '/tanks';
  static const String tankDetailsRoute = '/tankDetails';
  static const String tankRoute = '/tank';
  static const String billsRoute = '/bills';
  static const String paymentRoute = '/payment';
  static const String billDetailsRoute = '/billDetails';
  static const String aboutUsRoute = '/aboutUs';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
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
      case tankRoute:
        return MaterialPageRoute(builder: (_) => const TankScreen());
      case billsRoute:
        return MaterialPageRoute(builder: (_) => const BillsScreen());
      case paymentRoute:
        final bill = settings.arguments as Bill;
        return MaterialPageRoute(builder: (_) => PaymentScreen(bill: bill));
      case billDetailsRoute:
        final bill = settings.arguments as Bill;
        return MaterialPageRoute(builder: (_) => BillDetailsScreen(bill: bill));
      case aboutUsRoute:
        return MaterialPageRoute(builder: (_) => const AboutUsScreen());
      default:
        throw const FormatException('Route not found! Check routes again.');
    }
  }
}
