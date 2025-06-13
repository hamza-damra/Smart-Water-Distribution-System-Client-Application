import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingConnection = false;
  String? _errorMessage;
  String? _connectionStatus;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _connectionTimeout;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedUrl();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null) {
      setState(() {
        _urlController.text = savedUrl;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _urlController.dispose();
    _connectionTimeout?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isCheckingConnection = true;
      _connectionStatus = null;
      _errorMessage = null;
    });

    String url = _urlController.text.trim();
    
    // Add https:// if not present
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // Remove trailing slash if present
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    // Set a timeout of 10 seconds
    _connectionTimeout = Timer(const Duration(seconds: 10), () {
      if (mounted && _isCheckingConnection) {
        setState(() {
          _isCheckingConnection = false;
          _connectionStatus = 'Server is not responding';
          _errorMessage = 'Connection timeout. Please check if the server is running.';
        });
      }
    });

    try {
      final response = await http.get(Uri.parse(url));
      
      if (_connectionTimeout?.isActive ?? false) {
        _connectionTimeout?.cancel();
      }

      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
          // Consider 404 as successful since it means server is running
          if (response.statusCode == 404 || (response.statusCode >= 200 && response.statusCode < 300)) {
            _connectionStatus = 'Server is running';
            _errorMessage = null;
          } else {
            _connectionStatus = 'Server responded with error';
            _errorMessage = 'Server returned status code: ${response.statusCode}';
          }
        });
      }
    } catch (e) {
      if (_connectionTimeout?.isActive ?? false) {
        _connectionTimeout?.cancel();
      }
      
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
          _connectionStatus = 'Server is down';
          _errorMessage = 'Could not connect to server: $e';
        });
      }
    }
  }

  Future<void> _saveAndValidateUrl() async {
    if (_connectionStatus != 'Connection successful') {
      setState(() {
        _errorMessage = 'Please verify server connection before saving';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      HapticFeedback.mediumImpact();
      String url = _urlController.text.trim();
      
      // Add https:// if not present
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      // Remove trailing slash if present
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }

      // Save the URL
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', url);

      // Update Constants
      Constants.updateBaseUrl(url);

      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteManager.loginRoute);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save server URL: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo and Title
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          size: 64,
                          color: Constants.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Smart Water',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Server Configuration',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // URL Input
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Server URL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: 'Enter server URL',
                            prefixIcon: const Icon(Icons.link_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Constants.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Constants.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Constants.primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveAndValidateUrl(),
                        ),
                        if (_connectionStatus != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _connectionStatus == 'Server is running'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _connectionStatus == 'Server is running'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _connectionStatus == 'Server is running'
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _connectionStatus == 'Server is running'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _connectionStatus!,
                                    style: TextStyle(
                                      color: _connectionStatus == 'Server is running'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Check Connection Button
                  ElevatedButton.icon(
                    onPressed: _isCheckingConnection ? null : _checkConnection,
                    icon: _isCheckingConnection
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: Text(_isCheckingConnection ? 'Checking...' : 'Check Connection'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndValidateUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 