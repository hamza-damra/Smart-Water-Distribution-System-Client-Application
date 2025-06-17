import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

class CustomToast {
  /// Shows a professional toast message for network-related exceptions
  static void showNetworkError(BuildContext context, dynamic error) {
    String message;
    IconData icon;
    Color backgroundColor;

    // Parse the error to determine the appropriate message
    if (_isNetworkError(error)) {
      if (_isServerDownError(error)) {
        message = 'Server is currently unavailable. Please try again later.';
        icon = Icons.cloud_off_rounded;
        backgroundColor = const Color(0xFFEF4444);
      } else if (_isNoInternetError(error)) {
        message = 'No internet connection. Please check your network settings.';
        icon = Icons.wifi_off_rounded;
        backgroundColor = const Color(0xFFEF4444);
      } else if (_isTimeoutError(error)) {
        message = 'Connection timeout. Please check your internet connection.';
        icon = Icons.access_time_rounded;
        backgroundColor = const Color(0xFFF59E0B);
      } else {
        message = 'Network error occurred. Please try again.';
        icon = Icons.error_outline_rounded;
        backgroundColor = const Color(0xFFEF4444);
      }
    } else {
      // For non-network errors, show a generic error message
      message = 'An unexpected error occurred. Please try again.';
      icon = Icons.error_outline_rounded;
      backgroundColor = const Color(0xFFEF4444);
    }

    _showCustomToast(context, message, icon, backgroundColor);
  }

  /// Shows a success toast message
  static void showSuccess(BuildContext context, String message) {
    _showCustomToast(
      context,
      message,
      Icons.check_circle_outline_rounded,
      Constants.successColor,
    );
  }

  /// Shows a warning toast message
  static void showWarning(BuildContext context, String message) {
    _showCustomToast(
      context,
      message,
      Icons.warning_amber_rounded,
      Constants.warningColor,
    );
  }

  /// Shows an info toast message
  static void showInfo(BuildContext context, String message) {
    _showCustomToast(
      context,
      message,
      Icons.info_outline_rounded,
      Constants.infoColor,
    );
  }

  /// Shows a custom error toast message
  static void showError(BuildContext context, String message) {
    _showCustomToast(
      context,
      message,
      Icons.error_outline_rounded,
      Constants.errorColor,
    );
  }

  /// Internal method to show the actual toast
  static void _showCustomToast(
    BuildContext context,
    String message,
    IconData icon,
    Color backgroundColor,
  ) {
    // Check if context is still valid and mounted
    try {
      if (!context.mounted) return;
    } catch (e) {
      // Context is no longer valid
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getToastTitle(backgroundColor),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: Constants.toastDuration,
        elevation: 8,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white.withValues(alpha: 0.8),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Get appropriate title based on toast type
  static String _getToastTitle(Color backgroundColor) {
    if (backgroundColor == Constants.successColor) {
      return 'Success';
    } else if (backgroundColor == Constants.warningColor) {
      return 'Warning';
    } else if (backgroundColor == Constants.infoColor) {
      return 'Information';
    } else if (backgroundColor == const Color(0xFFF59E0B)) {
      return 'Timeout';
    } else {
      return 'Connection Error';
    }
  }

  /// Check if the error is network-related
  static bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('clientexception') ||
        errorString.contains('handshakeexception') ||
        errorString.contains('timeoutexception') ||
        errorString.contains('no route to host') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection timed out') ||
        error is SocketException ||
        error is http.ClientException;
  }

  /// Check if the error indicates server is down
  static bool _isServerDownError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('no route to host') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection reset') ||
        errorString.contains('server') ||
        (error is SocketException &&
            (error.osError?.errorCode == 111 || // Connection refused
                error.osError?.errorCode == 113)); // No route to host
  }

  /// Check if the error indicates no internet connection
  static bool _isNoInternetError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network is unreachable') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('temporary failure in name resolution') ||
        (error is SocketException &&
            (error.osError?.errorCode == 101 || // Network unreachable
                error.osError?.errorCode == -2)); // Name resolution failed
  }

  /// Check if the error is a timeout
  static bool _isTimeoutError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
        errorString.contains('connection timed out') ||
        error.toString().contains('TimeoutException');
  }
}
