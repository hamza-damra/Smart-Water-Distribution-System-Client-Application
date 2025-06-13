import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/providers/forgot_password_provider.dart';
import 'package:mytank/providers/update_data_provider.dart';
import 'package:mytank/providers/tanks_provider.dart';
import 'package:mytank/providers/bills_provider.dart';
import 'package:mytank/providers/payment_provider.dart';
import 'package:mytank/providers/main_tank_provider.dart';
import 'package:mytank/providers/notification_provider.dart';
import 'package:mytank/screens/splash_screen.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:mytank/utilities/back_button_handler.dart';
import 'package:provider/provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for a more immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E3A8A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize back button handler
  BackButtonHandler.init();

  // Force the app to render the first frame immediately
  // This ensures the splash screen appears without delay
  await Future.delayed(Duration.zero);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (context) => UpdateDataProvider()),
        ChangeNotifierProvider(create: (context) => TanksProvider()),
        ChangeNotifierProvider(create: (context) => BillsProvider()),
        ChangeNotifierProvider(create: (context) => PaymentProvider()),
        ChangeNotifierProvider(create: (context) => MainTankProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: Builder(
        builder:
            (context) => BackButtonHandler.wrapWithBackHandler(
              context,
              MaterialApp(
                title: 'Smart Tank',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  primaryColor: const Color(0xFF2E5C8A), // Modern navy blue
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF2E5C8A),
                    primary: const Color(0xFF2E5C8A), // Modern navy blue
                    secondary: const Color(0xFF4A90E2), // Vibrant blue
                    tertiary: const Color(0xFF5AC8FA), // Light blue for water
                    // Using surface for both surface and background (background is deprecated)
                    surface: const Color(
                      0xFFF8FAFD,
                    ), // Very light blue background
                    surfaceTint: const Color(0xFFF7FBFF),
                    onPrimary: const Color(0xFFFFFFFF),
                    onSecondary: const Color(0xFFFFFFFF),
                    onSurface: const Color(
                      0xFF2C3E50,
                    ), // Dark blue-gray for text
                    onTertiary: const Color(
                      0xFF34495E,
                    ), // Slightly lighter blue-gray
                    error: const Color(0xFFE74C3C), // Modern red
                  ),
                  scaffoldBackgroundColor: const Color(
                    0xFFF8FAFD,
                  ), // Very light blue background
                  appBarTheme: const AppBarTheme(
                    elevation: 0,
                    backgroundColor: Color(0xFF2E5C8A),
                    foregroundColor: Colors.white,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // Use home instead of initialRoute to ensure splash screen appears first
                home: const SplashScreen(),
                onGenerateRoute: RouteManager.generateRoute,
              ),
            ),
      ),
    );
  }
}
