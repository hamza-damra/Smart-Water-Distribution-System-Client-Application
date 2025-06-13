// home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/providers/main_tank_provider.dart';
import 'package:mytank/providers/notification_provider.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/widgets/water_tank_3d.dart';
import 'package:mytank/models/user_model.dart';
import 'package:mytank/services/user_service.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _notificationPulseController;
  late AnimationController _notificationBounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  User? _currentUser;
  bool _isLoadingUser = false;
  int _previousUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Wave animation loops indefinitely.

    // Initialize notification animation controllers
    _notificationPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _notificationBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Create animations
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _notificationPulseController,
        curve: Curves.easeInOut,
      ),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _notificationBounceController,
        curve: Curves.elasticOut,
      ),
    );

    // Start pulse animation for notifications
    _notificationPulseController.repeat(reverse: true);

    // Fetch main tank data and user data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMainTankData();
      _fetchUserData();
    });
  }

  void _fetchMainTankData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mainTankProvider = Provider.of<MainTankProvider>(
      context,
      listen: false,
    );

    if (authProvider.accessToken != null) {
      mainTankProvider.fetchMainTankData(authProvider);
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      final user = await UserService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });

        // Update auth provider with real user name
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.updateUserInfo(user.name);

        // Initialize notifications
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        notificationProvider.initializeNotifications(user.notifications);

        // Initialize real-time notifications
        authProvider.initializeRealTimeNotifications(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
      debugPrint('❌ Error fetching user data: $e');
    }
  }

  /// Trigger bounce animation when notification count increases
  void _triggerNotificationBounce(int newCount) {
    if (newCount > _previousUnreadCount && newCount > 0) {
      _notificationBounceController.reset();
      _notificationBounceController.forward();
    }
    _previousUnreadCount = newCount;
  }

  @override
  void dispose() {
    _waveController.dispose();
    _notificationPulseController.dispose();
    _notificationBounceController.dispose();
    super.dispose();
  }

  /// Handle logout with proper async/await pattern
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    await authProvider.logoutWithContext(context);
    if (mounted) {
      navigator.pushReplacementNamed(RouteManager.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Use real user name from User model, fallback to auth provider, then to 'User'
    final userName = _currentUser?.name ?? authProvider.userName ?? 'User';

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
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;

              // Trigger bounce animation when count changes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _triggerNotificationBounce(unreadCount);
              });

              return _buildEnhancedNotificationIcon(unreadCount);
            },
          ),
          const SizedBox(width: 8),
        ],
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
            // Modern Drawer Header with User Information
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
              child:
                  _isLoadingUser ? _buildLoadingHeader() : _buildUserHeader(),
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
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return _buildDrawerItem(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  badge:
                      notificationProvider.unreadCount > 0
                          ? notificationProvider.unreadCount
                          : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteManager.notificationsRoute,
                    );
                  },
                );
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
            _buildDrawerItem(
              icon: Icons.info_outline_rounded,
              title: 'About Us',
              iconColor: Colors.grey.shade600,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteManager.aboutUsRoute);
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
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: withValues(Colors.black, 0.05),
                    blurRadius: 15,
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Constants.primaryColor,
                                Constants.secondaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: withValues(Constants.primaryColor, 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.water_drop_rounded,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Welcome text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome',
                                style: TextStyle(
                                  color: Constants.greyColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userName,
                                style: TextStyle(
                                  color: Constants.primaryColor,
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
                        final usageStatusColor =
                            mainTankProvider.usageStatusColor;
                        final formattedUsage = mainTankProvider.formatUsage(
                          currentUsage,
                        );

                        return Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Constants.primaryColor,
                                Constants.secondaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: withValues(Constants.primaryColor, 0.2),
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
                            final waterLevel =
                                mainTankProvider.waterLevelPercentage;
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(waterLevel * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Constants.primaryColor,
                                      ),
                                    ),
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
                                  maxCapacity:
                                      mainTankProvider.mainTank?.maxCapacity ??
                                      1.0,
                                  currentLevel:
                                      mainTankProvider.mainTank?.currentLevel ??
                                      0.0,
                                ),

                                const SizedBox(height: 30),

                                // Refresh button
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        mainTankProvider.isLoading ||
                                                _isLoadingUser
                                            ? null
                                            : () {
                                              _fetchMainTankData();
                                              _fetchUserData();
                                            },
                                    icon:
                                        (mainTankProvider.isLoading ||
                                                _isLoadingUser)
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                            : const Icon(Icons.refresh_rounded),
                                    label: Text(
                                      (mainTankProvider.isLoading ||
                                              _isLoadingUser)
                                          ? 'Refreshing...'
                                          : 'Refresh Data',
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
    int? badge,
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? const Color(0xFF1976D2) : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            if (badge != null && badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Constants.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge > 99 ? '99+' : badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
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

  // Helper method to build user header in drawer
  Widget _buildUserHeader() {
    final user = _currentUser;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final displayName = user?.name ?? authProvider.userName ?? 'User';
    final displayEmail = user?.email ?? 'No email available';
    final joinDate = user?.getFormattedJoinDate() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Avatar
        Row(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Constants.primaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                      : _buildDefaultAvatar(),
            ),
            const SizedBox(width: 15),
            // App branding (smaller)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Tank',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Water Management',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // User Information
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              displayEmail,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (joinDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                joinDate,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Helper method to build default avatar
  Widget _buildDefaultAvatar() {
    final user = _currentUser;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final displayName = user?.name ?? authProvider.userName ?? 'User';
    final initials = _getInitials(displayName);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.primaryColor.withAlpha(200),
            Constants.secondaryColor.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Helper method to build loading header
  Widget _buildLoadingHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Loading avatar placeholder
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // App branding
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Tank',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Water Management',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Loading placeholders for user info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 24,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to get user initials
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  // Enhanced notification icon with improved animations and design
  Widget _buildEnhancedNotificationIcon(int unreadCount) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale:
              unreadCount > 0
                  ? _pulseAnimation.value * _bounceAnimation.value
                  : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main notification icon with enhanced styling
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      unreadCount > 0
                          ? [
                            BoxShadow(
                              color: withValues(Constants.primaryColor, 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: IconButton(
                  icon: Icon(
                    unreadCount > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip:
                      unreadCount > 0
                          ? '$unreadCount unread notifications'
                          : 'Notifications',
                  onPressed: () {
                    // Add haptic feedback for better user experience
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      RouteManager.notificationsRoute,
                    );
                  },
                ),
              ),
              // Enhanced notification badge
              if (unreadCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Constants.primaryColor,
                          Constants.secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: withValues(Constants.primaryColor, 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: withValues(Colors.white, 0.8),
                          blurRadius: 1,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
