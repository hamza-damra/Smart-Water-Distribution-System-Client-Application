import 'package:flutter/material.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/providers/forgot_password_provider.dart';
import 'package:mytank/providers/update_data_provider.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (context) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (context) => UpdateDataProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Water System',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: RouteManager.loginRoute,
        onGenerateRoute: RouteManager.generateRoute,
      ),
    );
  }
}