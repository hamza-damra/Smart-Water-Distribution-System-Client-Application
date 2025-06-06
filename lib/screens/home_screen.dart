// home_screen.dart
import 'package:flutter/material.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/providers/main_tank_provider.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/widgets/water_tank_3d.dart';
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



  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Wave animation loops indefinitely.

    // Fetch main tank data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMainTankData();
    });
  }

  void _fetchMainTankData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mainTankProvider = Provider.of<MainTankProvider>(context, listen: false);

    if (authProvider.accessToken != null) {
      mainTankProvider.fetchMainTankData(authProvider);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
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
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.userName ?? 'User';

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
                              Text(
                                userName,
                                style: const TextStyle(
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

                    // Water usage card with real data
                    Consumer<MainTankProvider>(
                      builder: (context, mainTankProvider, child) {
                        final currentUsage = mainTankProvider.currentMonthUsage;
                        final usageStatus = mainTankProvider.usageStatus;
                        final usageStatusColor = mainTankProvider.usageStatusColor;
                        final formattedUsage = mainTankProvider.formatUsage(currentUsage);

                        return Container(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Monthly Water Usage',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formattedUsage,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status pill with real data
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: usageStatusColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: withValues(Colors.black, 0.1),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  usageStatus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                  // Smart Tank Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: withValues(Colors.black, 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with current level and status
                        Consumer<MainTankProvider>(
                          builder: (context, mainTankProvider, child) {
                            final waterLevel = mainTankProvider.waterLevelPercentage;
                            final statusText = mainTankProvider.statusText;
                            final statusColor = mainTankProvider.statusColor;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Level',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Constants.greyColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '${(waterLevel * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Constants.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.warning_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            statusText,
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

                                // Professional Cylindrical 3D Tank Widget
                                WaterTank3D(
                                  waterLevel: waterLevel,
                                  maxCapacity: mainTankProvider.mainTank?.maxCapacity ?? 1.0,
                                  currentLevel: mainTankProvider.mainTank?.currentLevel ?? 0.0,
                                ),

                                const SizedBox(height: 30),

                                // Refresh button
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: mainTankProvider.isLoading
                                        ? null
                                        : _fetchMainTankData,
                                    icon: mainTankProvider.isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.refresh_rounded),
                                    label: Text(
                                      mainTankProvider.isLoading
                                          ? 'Refreshing...'
                                          : 'Refresh Tank Data',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Constants.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Last updated text
                                Center(
                                  child: Text(
                                    'Last updated: Just now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Constants.greyColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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


