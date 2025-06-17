import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utilities/custom_toast.dart';
import '../utilities/constants.dart';

class ToastDemoScreen extends StatelessWidget {
  const ToastDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Toast Demo'),
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Custom Toast Messages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Constants.blackColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Success Toast
            ElevatedButton.icon(
              onPressed: () {
                CustomToast.showSuccess(
                  context,
                  'Operation completed successfully!',
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Show Success Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Error Toast
            ElevatedButton.icon(
              onPressed: () {
                CustomToast.showError(
                  context,
                  'Something went wrong. Please try again.',
                );
              },
              icon: const Icon(Icons.error),
              label: const Text('Show Error Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Warning Toast
            ElevatedButton.icon(
              onPressed: () {
                CustomToast.showWarning(
                  context,
                  'This action requires your attention.',
                );
              },
              icon: const Icon(Icons.warning),
              label: const Text('Show Warning Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Info Toast
            ElevatedButton.icon(
              onPressed: () {
                CustomToast.showInfo(
                  context,
                  'Here is some useful information for you.',
                );
              },
              icon: const Icon(Icons.info),
              label: const Text('Show Info Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.infoColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            
            const Divider(),
            const SizedBox(height: 16),
            
            const Text(
              'Test Network Error Scenarios',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.blackColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Simulate Server Down Error
            ElevatedButton.icon(
              onPressed: () {
                final error = SocketException(
                  'No route to host',
                  osError: OSError('No route to host', 113),
                  address: InternetAddress('192.168.1.26'),
                  port: 8000,
                );
                CustomToast.showNetworkError(context, error);
              },
              icon: const Icon(Icons.cloud_off),
              label: const Text('Simulate Server Down'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Simulate No Internet Error
            ElevatedButton.icon(
              onPressed: () {
                final error = SocketException(
                  'Network is unreachable',
                  osError: OSError('Network is unreachable', 101),
                );
                CustomToast.showNetworkError(context, error);
              },
              icon: const Icon(Icons.wifi_off),
              label: const Text('Simulate No Internet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Simulate Timeout Error
            ElevatedButton.icon(
              onPressed: () {
                final error = http.ClientException(
                  'Connection timeout',
                );
                CustomToast.showNetworkError(context, error);
              },
              icon: const Icon(Icons.access_time),
              label: const Text('Simulate Timeout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
