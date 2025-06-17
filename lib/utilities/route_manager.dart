import 'package:flutter/material.dart';
import '../screens/app_splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/tanks_screen.dart';
import '../screens/tank_details_screen.dart';
import '../screens/bills_screen.dart';
import '../screens/bill_details_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/server_config_screen.dart';
import '../screens/update_data_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/settings_screen.dart';
import '../models/bill_model.dart';

class RouteManager {
  // Route names
  static const String splashRoute = '/splash';
  static const String serverConfigRoute = '/';
  static const String serverConfigSettingsRoute = '/server-config';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String tanksRoute = '/tanks';
  static const String tankDetailsRoute = '/tank-details';
  static const String billsRoute = '/bills';
  static const String billDetailsRoute = '/bill-details';
  static const String paymentRoute = '/payment';
  static const String profileRoute = '/profile';
  static const String notificationsRoute = '/notifications';
  static const String updateDataRoute = '/update-data';
  static const String aboutUsRoute = '/about-us';
  static const String settingsRoute = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const AppSplashScreen());

      case serverConfigRoute:
        return MaterialPageRoute(builder: (_) => const ServerConfigScreen());

      case serverConfigSettingsRoute:
        return MaterialPageRoute(builder: (_) => const ServerConfigScreen());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case tanksRoute:
        return MaterialPageRoute(builder: (_) => const TanksScreen());

      case tankDetailsRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TankDetailsScreen(tankId: args['tankId'] as String),
        );

      case billsRoute:
        return MaterialPageRoute(builder: (_) => const BillsScreen());

      case billDetailsRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BillDetailsScreen(bill: args['bill'] as Bill),
        );

      case paymentRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaymentScreen(bill: args['bill'] as Bill),
        );

      case profileRoute:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case notificationsRoute:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case updateDataRoute:
        return MaterialPageRoute(builder: (_) => const UpdateDataScreen());

      case aboutUsRoute:
        return MaterialPageRoute(builder: (_) => const AboutUsScreen());

      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
