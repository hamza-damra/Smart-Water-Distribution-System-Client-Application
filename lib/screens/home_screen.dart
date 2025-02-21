import 'package:flutter/material.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, RouteManager.loginRoute);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome to the Home Screen!'),
      ),
    );
  }
}