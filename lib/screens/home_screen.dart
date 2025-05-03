// home_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:provider/provider.dart';

// Helper method to replace deprecated withOpacity
Color withValues(Color color, double opacity) {
  return Color.fromRGBO(
    color.r.toInt(),
    color.g.toInt(),
    color.b.toInt(),
    opacity,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  /// The water level in the tank (0.0 = empty, 1.0 = full)
  double _waterLevel = 0.4;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Wave animation loops indefinitely.
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  /// Increases water level by 0.05 (5%)
  void _increaseWaterLevel() {
    setState(() {
      _waterLevel += 0.05;
      if (_waterLevel > 1.0) _waterLevel = 1.0; // Clamp at max (full)
    });
  }

  /// Decreases water level by 0.05 (5%)
  void _decreaseWaterLevel() {
    setState(() {
      _waterLevel -= 0.05;
      if (_waterLevel < 0.0) _waterLevel = 0.0; // Clamp at min (empty)
    });
  }

  /// Get status color based on water level
  Color _getStatusColor() {
    if (_waterLevel >= 0.7) {
      return Constants.successColor; // High level - green
    } else if (_waterLevel >= 0.3) {
      return Constants.warningColor; // Medium level - orange
    } else {
      return Constants.errorColor; // Low level - red
    }
  }

  /// Get status icon based on water level
  IconData _getStatusIcon() {
    if (_waterLevel >= 0.7) {
      return Icons.check_circle_outline;
    } else if (_waterLevel >= 0.3) {
      return Icons.info_outline;
    } else {
      return Icons.warning_amber_outlined;
    }
  }

  /// Get status text based on water level
  String _getStatusText() {
    if (_waterLevel >= 0.7) {
      return 'High';
    } else if (_waterLevel >= 0.3) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  /// Handle logout with proper async/await pattern
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    await authProvider.logout();
    if (mounted) {
      navigator.pushReplacementNamed(RouteManager.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        title: const Text(
          'Smart Tank',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      // Modern Navigation Drawer
      drawer: Drawer(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Modern Drawer Header with Logo
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    withValues(Constants.primaryColor, 0.9),
                    Constants.primaryColor,
                    Constants.secondaryColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: withValues(Constants.primaryColor, 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Logo
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      size: 35,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Smart Tank',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Manage your water efficiently',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Modern menu items
            _buildDrawerItem(
              icon: Icons.home_rounded,
              title: 'Home',
              isActive: true,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, RouteManager.homeRoute);
              },
            ),
            _buildDrawerItem(
              icon: Icons.water_rounded,
              title: 'My Tanks',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteManager.tanksRoute);
              },
            ),
            _buildDrawerItem(
              icon: Icons.person_rounded,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteManager.profileRoute);
              },
            ),
            _buildDrawerItem(
              icon: Icons.receipt_rounded,
              title: 'My Bills',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteManager.billsRoute);
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(color: Colors.grey.withAlpha(100)),
            ),

            _buildDrawerItem(
              icon: Icons.settings_rounded,
              title: 'Settings',
              iconColor: Colors.grey.shade600,
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings when implemented
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              iconColor: Colors.grey.shade600,
              onTap: () {
                Navigator.pop(context);
                // Navigate to help when implemented
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(color: Colors.grey.withAlpha(100)),
            ),

            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              iconColor: const Color(0xFFF44336),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header content with welcome and water usage
            Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Constants.primaryColor, Constants.secondaryColor],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: withValues(Constants.primaryColor, 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome header
                    Row(
                      children: [
                        // Avatar container
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: withValues(Colors.black, 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.water_drop_rounded,
                            size: 35,
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Welcome text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'John Doe',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Water usage card
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: withValues(Colors.white, 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: withValues(Colors.white, 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: withValues(Colors.black, 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Water icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: withValues(Colors.white, 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.water_drop_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Usage stats
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Water Usage',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '3,600 Liters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Constants.warningColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: withValues(Colors.black, 0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Medium',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content with modern design
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern section header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: withValues(Constants.primaryColor, 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.water_rounded,
                          color: Constants.primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Water Tank Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Constants.blackColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monitor your current water level',
                            style: TextStyle(
                              fontSize: 14,
                              color: Constants.greyColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Modern tank visualization card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: withValues(Constants.primaryColor, 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Water level indicator row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Water level percentage
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Level',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Constants.greyColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(_waterLevel * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Constants.primaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              // Status indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: withValues(_getStatusColor(), 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getStatusText(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Animated water tank with modern design
                          Container(
                            width: 160,
                            height: 240,
                            decoration: BoxDecoration(
                              color: Constants.lightGreyColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: withValues(
                                    Constants.primaryColor,
                                    0.05,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Level markers
                                Positioned.fill(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 15,
                                          right: 15,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '75%',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Constants.greyColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 1,
                                        color: withValues(
                                          Constants.greyColor,
                                          0.2,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 15,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '50%',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Constants.greyColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 1,
                                        color: withValues(
                                          Constants.greyColor,
                                          0.2,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 15,
                                          right: 15,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '25%',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Constants.greyColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Water level
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 240 * _waterLevel,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Constants.accentColor,
                                          Constants.primaryColor,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.vertical(
                                        bottom: const Radius.circular(20),
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: _WaterTankPainter(
                                        animation: _waveController,
                                        waterLevel: _waterLevel,
                                        waterColor: Constants.primaryColor,
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ),

                                // Percentage in the middle
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: withValues(Colors.white, 0.2),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: withValues(Colors.white, 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${(_waterLevel * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Modern water level controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _decreaseWaterLevel,
                                icon: const Icon(Icons.remove_rounded),
                                label: const Text('Decrease'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.errorColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton.icon(
                                onPressed: _increaseWaterLevel,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Increase'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.successColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Modern quick actions section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.touch_app_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Modern action buttons grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.water_rounded,
                          label: 'My Tanks',
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteManager.tanksRoute,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          color: const Color(0xFF9C27B0),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteManager.profileRoute,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Increased spacing between rows
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.receipt_rounded,
                          label: 'My Bills',
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteManager.billsRoute,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.notifications_rounded,
                          label: 'Alerts',
                          color: const Color(0xFFF44336),
                          onTap: () {
                            // Navigate to alerts when implemented
                          },
                        ),
                      ),
                    ],
                  ),
                  // Add bottom margin after the grid
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build drawer menu items
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isActive
                    ? const Color(0xFF1976D2).withAlpha(20)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color:
                isActive
                    ? const Color(0xFF1976D2)
                    : iconColor ?? const Color(0xFF1976D2),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF1976D2) : Colors.black87,
            fontSize: 16,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        selected: isActive,
        selectedTileColor: const Color(0xFF1976D2).withAlpha(10),
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F4858),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the water tank wave animation.
class _WaterTankPainter extends CustomPainter {
  final Animation<double> animation;
  final double waterLevel; // Expected value between 0.0 and 1.0
  final Color waterColor;

  _WaterTankPainter({
    required this.animation,
    required this.waterLevel,
    this.waterColor = const Color(0xFF0D47A1),
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw modern tank background with subtle gradient
    final backgroundPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFF5F9FF), const Color(0xFFEDF3FF)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(backgroundRect, backgroundPaint);

    // Draw modern water level indicator lines
    final linePaint =
        Paint()
          ..color = Colors.grey.withAlpha(80)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    // Draw level indicator lines with labels (25%, 50%, 75%)
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (1 - (i / 4));

      // Draw dashed lines for modern look
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, y), Offset(startX + 5, y), linePaint);
        startX += 10; // Gap between dashes
      }

      // Draw percentage labels
      final labelStyle = TextStyle(
        color: Colors.grey.withAlpha(150),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      );

      final textSpan = TextSpan(text: '${i * 25}%', style: labelStyle);

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // Use the provided water color

    // Calculate horizontal shift based on animation value for wave effect
    final waveShift = animation.value * size.width;
    // Calculate base water line (top when full, bottom when empty)
    final baseHeight = size.height * (1 - waterLevel);

    // Create modern wave path with smoother curves
    final wavePath = Path();
    // Start from bottom-left corner
    wavePath.moveTo(0, size.height);

    // Adjust wave parameters for more modern look
    final waveHeight = size.width * 0.08; // Slightly smaller waves
    final waveWidth = size.width / 6; // Higher frequency for modern look

    // Create smoother wave with more points
    for (double x = 0; x <= size.width; x += 2) {
      final rawY =
          baseHeight +
          sin((x + waveShift) / waveWidth * pi) * waveHeight +
          sin((x + waveShift) / (waveWidth * 0.5) * pi) *
              (waveHeight * 0.3); // Add secondary wave
      final clampedY = rawY.clamp(0.0, size.height);
      wavePath.lineTo(x, clampedY);
    }

    // Close path at bottom-right
    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    // Draw the water with a clip to keep it inside the rounded rectangle
    canvas.save();
    canvas.clipRRect(backgroundRect);

    // Create modern water gradient
    final waterGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [waterColor.withAlpha(200), waterColor],
    ).createShader(
      Rect.fromLTWH(0, baseHeight, size.width, size.height - baseHeight),
    );

    final waterPaint =
        Paint()
          ..shader = waterGradient
          ..style = PaintingStyle.fill;

    canvas.drawPath(wavePath, waterPaint);

    // Add subtle highlight at the top of the water for 3D effect
    if (waterLevel > 0.05) {
      final highlightPath = Path();
      highlightPath.moveTo(0, baseHeight);

      for (double x = 0; x <= size.width; x += 2) {
        final rawY =
            baseHeight +
            sin((x + waveShift) / waveWidth * pi) * waveHeight +
            sin((x + waveShift) / (waveWidth * 0.5) * pi) * (waveHeight * 0.3);
        final clampedY = rawY.clamp(0.0, size.height);
        highlightPath.lineTo(x, clampedY);
      }

      highlightPath.lineTo(size.width, baseHeight);
      highlightPath.close();

      final highlightPaint =
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withAlpha(100), Colors.transparent],
              stops: const [0.0, 0.3],
            ).createShader(
              Rect.fromLTWH(0, baseHeight, size.width, waveHeight * 2),
            );

      canvas.drawPath(highlightPath, highlightPaint);
    }

    canvas.restore();

    // Draw modern tank border with subtle shadow
    final tankBorderPaint =
        Paint()
          ..color = Colors.grey.withAlpha(100)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    canvas.drawRRect(backgroundRect, tankBorderPaint);

    // Add water level percentage text with modern styling
    final percentage = (waterLevel * 100).toInt();

    // Only draw text if water level is high enough to contain it
    if (waterLevel > 0.15) {
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: size.width * 0.18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        shadows: [
          Shadow(
            color: Colors.black.withAlpha(70),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      );

      final textSpan = TextSpan(text: '$percentage%', style: textStyle);

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout(minWidth: 0, maxWidth: size.width);

      // Position text in the middle of the water
      final waterMiddleY = (baseHeight + size.height) / 2;
      final textX = (size.width - textPainter.width) / 2;
      final textY = waterMiddleY - textPainter.height / 2;

      // Only draw if text is fully submerged
      if (waterMiddleY + textPainter.height / 2 < size.height) {
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }

    // Add water droplets for empty tank (decorative)
    if (waterLevel < 0.1) {
      final dropletPaint =
          Paint()
            ..color = waterColor.withAlpha(150)
            ..style = PaintingStyle.fill;

      // Draw a few droplets at the bottom
      canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.9),
        size.width * 0.03,
        dropletPaint,
      );

      canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.85),
        size.width * 0.02,
        dropletPaint,
      );

      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.95),
        size.width * 0.025,
        dropletPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaterTankPainter oldDelegate) =>
      oldDelegate.waterLevel != waterLevel ||
      oldDelegate.animation.value != animation.value;
}
