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
import 'package:shimmer/shimmer.dart';
import 'dart:async';

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
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  User? _currentUser;
  bool _isLoadingUser = false;
  int _previousUnreadCount = 0;
  Timer? _notificationRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Fetch main tank data and user data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMainTankData();
      _fetchUserData();
    });
  }

  void _initializeAnimations() {
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

    // New animation controllers for modern design
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
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

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _notificationPulseController.repeat(reverse: true);
    _rotationController.repeat();

    // Start entrance animations after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _scaleController.forward();
      }
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

        // Initialize real-time notifications with user ID from fetched data
        authProvider.updateUserInfo(user.name);

        // Set user ID in auth provider if not already set
        if (authProvider.userId == null) {
          authProvider.updateUserId(user.id);
        }

        authProvider.initializeRealTimeNotifications(context);

        // Start periodic notification refresh (every 30 seconds)
        _startNotificationRefresh();
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

  // Start periodic refresh for notifications as backup to real-time
  void _startNotificationRefresh() {
    _notificationRefreshTimer?.cancel();
    _notificationRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );

        // Only refresh if socket is not connected (as backup)
        if (!notificationProvider.isSocketConnected) {
          debugPrint('🔄 Periodic notification refresh (socket disconnected)');
          notificationProvider.fetchNotifications();
        }
      }
    });
  }

  /// Trigger bounce animation when notification count increases
  void _triggerNotificationBounce(int newCount) {
    if (newCount > _previousUnreadCount && newCount > 0) {
      _notificationBounceController.reset();
      _notificationBounceController.forward();
      debugPrint('🔔 Notification bounce triggered for count: $newCount');
    }
    _previousUnreadCount = newCount;
  }

  @override
  void dispose() {
    _waveController.dispose();
    _notificationPulseController.dispose();
    _notificationBounceController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _notificationRefreshTimer?.cancel();
    super.dispose();
  }

  /// Handle logout with proper async/await pattern
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    // The AuthProvider.logoutWithContext will handle clearing all provider data
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667EEA),
                    Constants.primaryColor,
                    Constants.secondaryColor,
                    const Color(0xFF764BA2),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  transform: GradientRotation(_rotationAnimation.value * 0.5),
                ),
              ),
            );
          },
        ),
        title: const Text(
          'Smart Tank',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
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
          const SizedBox(width: 16),
        ],
        elevation: 0,
      ),
      // Enhanced Modern Navigation Drawer with Fixed UX
      drawer: SizedBox(
        width:
            MediaQuery.of(context).size.width *
            0.85, // Fixed width for better UX
        child: Drawer(
          backgroundColor: const Color(0xFFF8FAFC),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Enhanced Header with overflow-safe responsive design
                Container(
                  // Use flexible height with min/max constraints
                  constraints: BoxConstraints(
                    minHeight: 160,
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top +
                        12, // Reduced padding for better space usage
                    16,
                    16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF667EEA),
                        Constants.primaryColor,
                        Constants.secondaryColor,
                        const Color(0xFF764BA2),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: withValues(Constants.primaryColor, 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top:
                        false, // Don't add safe area padding at top since we handle it manually
                    child:
                        _isLoadingUser
                            ? _buildLoadingHeader()
                            : _buildEnhancedUserHeader(),
                  ),
                ),

                // Scrollable menu items with proper SafeArea
                Expanded(
                  child: SafeArea(
                    top: false, // Header already handles top safe area
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Enhanced menu items with better touch targets
                        _buildEnhancedDrawerItem(
                          icon: Icons.home_rounded,
                          title: 'Home',
                          isActive: true,
                          color: Constants.primaryColor,
                          onTap:
                              () => _navigateFromDrawer(
                                context,
                                RouteManager.homeRoute,
                              ),
                        ),
                        _buildEnhancedDrawerItem(
                          icon: Icons.water_rounded,
                          title: 'My Tanks',
                          color: const Color(0xFF3B82F6),
                          onTap:
                              () => _navigateFromDrawer(
                                context,
                                RouteManager.tanksRoute,
                              ),
                        ),
                        _buildEnhancedDrawerItem(
                          icon: Icons.person_rounded,
                          title: 'Profile',
                          color: const Color(0xFF9C27B0),
                          onTap:
                              () => _navigateFromDrawer(
                                context,
                                RouteManager.profileRoute,
                              ),
                        ),
                        _buildEnhancedDrawerItem(
                          icon: Icons.receipt_rounded,
                          title: 'My Bills',
                          color: const Color(0xFF10B981),
                          onTap:
                              () => _navigateFromDrawer(
                                context,
                                RouteManager.billsRoute,
                              ),
                        ),
                        Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, child) {
                            return _buildEnhancedDrawerItem(
                              icon: Icons.notifications_rounded,
                              title: 'Notifications',
                              color: const Color(0xFFEF4444),
                              badge:
                                  notificationProvider.unreadCount > 0
                                      ? notificationProvider.unreadCount
                                      : null,
                              onTap:
                                  () => _navigateFromDrawer(
                                    context,
                                    RouteManager.notificationsRoute,
                                  ),
                            );
                          },
                        ),

                        const SizedBox(height: 15),
                        _buildDivider(),
                        const SizedBox(height: 15),

                        _buildEnhancedDrawerItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          color: Colors.grey.shade600,
                          onTap:
                              () => _handleDrawerAction(context, () {
                                // Navigate to help when implemented
                                _showSnackBar('Help & Support coming soon!');
                              }),
                        ),
                        _buildEnhancedDrawerItem(
                          icon: Icons.info_outline_rounded,
                          title: 'About Us',
                          color: Colors.grey.shade600,
                          onTap:
                              () => _navigateFromDrawer(
                                context,
                                RouteManager.aboutUsRoute,
                              ),
                        ),

                        const SizedBox(height: 20),
                        _buildDivider(),
                        const SizedBox(height: 20),

                        _buildEnhancedDrawerItem(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          color: const Color(0xFFEF4444),
                          onTap:
                              () => _handleDrawerAction(context, () {
                                _handleLogout(context);
                              }, isDestructive: true),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header content with welcome and water usage
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(35),
                      bottomRight: Radius.circular(35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: withValues(Colors.black, 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome header with shimmer loading
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child:
                              _isLoadingUser
                                  ?
                                  // Shimmer loading state for welcome header
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 70,
                                          width: 70,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 16,
                                                width: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                height: 26,
                                                width: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                height: 20,
                                                width: 140,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  :
                                  // Actual welcome header
                                  Row(
                                    children: [
                                      // Enhanced Avatar container with pulse effect
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale:
                                                0.95 +
                                                (_pulseAnimation.value * 0.05),
                                            child: Container(
                                              height: 70,
                                              width: 70,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    const Color(0xFF667EEA),
                                                    Constants.primaryColor,
                                                    Constants.secondaryColor,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: withValues(
                                                      Constants.primaryColor,
                                                      0.3,
                                                    ),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.water_drop_rounded,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 18),
                                      // Welcome text with enhanced styling
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Welcome back',
                                              style: TextStyle(
                                                color: Constants.greyColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              userName,
                                              style: TextStyle(
                                                color: Constants.primaryColor,
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF10B981,
                                                ).withAlpha(20),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: const Text(
                                                '🌊 Water Guardian',
                                                style: TextStyle(
                                                  color: Color(0xFF10B981),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                        ),

                        // Enhanced water usage card with shimmer loading
                        Consumer<MainTankProvider>(
                          builder: (context, mainTankProvider, child) {
                            return AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 24),
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF667EEA),
                                          Constants.primaryColor,
                                          Constants.secondaryColor,
                                          const Color(0xFF764BA2),
                                        ],
                                        stops: const [0.0, 0.3, 0.7, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: withValues(
                                            Constants.primaryColor,
                                            0.3,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child:
                                        mainTankProvider.isLoading
                                            ?
                                            // Shimmer loading state
                                            Shimmer.fromColors(
                                              baseColor: Colors.white.withAlpha(
                                                60,
                                              ),
                                              highlightColor: Colors.white
                                                  .withAlpha(120),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 18),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          height: 16,
                                                          width:
                                                              double.infinity,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Container(
                                                          height: 28,
                                                          width: 120,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 80,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            :
                                            // Actual content
                                            Row(
                                              children: [
                                                // Enhanced water icon with glow effect
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    14,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: withValues(
                                                      Colors.white,
                                                      0.25,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: withValues(
                                                        Colors.white,
                                                        0.3,
                                                      ),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.waves_rounded,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(width: 18),
                                                // Enhanced usage stats
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'This Month\'s Usage',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        mainTankProvider
                                                            .formatUsage(
                                                              mainTankProvider
                                                                  .currentMonthUsage,
                                                            ),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 28,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Enhanced status pill with real data
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        mainTankProvider
                                                            .usageStatusColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          25,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withAlpha(100),
                                                      width: 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: withValues(
                                                          Colors.black,
                                                          0.15,
                                                        ),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    mainTankProvider
                                                        .usageStatus,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Main content with enhanced modern design
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Smart Tank Header
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: withValues(Colors.black, 0.08),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Enhanced header with tank status and shimmer loading
                              Consumer<MainTankProvider>(
                                builder: (context, mainTankProvider, child) {
                                  if (mainTankProvider.isLoading) {
                                    // Shimmer loading state for tank data
                                    return Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 52,
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 18,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              9,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      height: 14,
                                                      width: 200,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              7,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    height: 16,
                                                    width: 120,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    height: 52,
                                                    width: 100,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                width: 100,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(21),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          // Tank widget placeholder
                                          Container(
                                            height: 200,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          // Button placeholder
                                          Center(
                                            child: Container(
                                              width: 150,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  // Check if user has no tank data (not an error)
                                  if (mainTankProvider.hasNoTankData) {
                                    return _buildNoTankDataState();
                                  }

                                  // Check if there's an actual error
                                  if (mainTankProvider.hasError) {
                                    return _buildErrorState(
                                      mainTankProvider.errorMessage!,
                                    );
                                  }

                                  final waterLevel =
                                      mainTankProvider.waterLevelPercentage;

                                  // Calculate water level and capacity values
                                  double currentLevelLiters =
                                      mainTankProvider.mainTank?.currentLevel ??
                                      0.0;
                                  double maxCapacityLiters =
                                      mainTankProvider.mainTank?.maxCapacity ??
                                      1.0;

                                  // Calculate level color based on water level
                                  Color levelColor =
                                      waterLevel < 0.3
                                          ? const Color(0xFFEF4444)
                                          : waterLevel < 0.6
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF10B981);

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Constants.primaryColor
                                                  .withAlpha(20),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              Icons.water_rounded,
                                              color: Constants.primaryColor,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Smart Tank Monitor',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Real-time water level tracking',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Constants.greyColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Enhanced water level display from tanks screen
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: levelColor.withAlpha(20),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                Icons.water_drop,
                                                color: levelColor,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Water Level',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${currentLevelLiters.toStringAsFixed(1)} L / ${maxCapacityLiters.toStringAsFixed(1)} L',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: levelColor.withAlpha(20),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: levelColor.withAlpha(
                                                    100,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                "${(waterLevel * 100).toStringAsFixed(1)}%",
                                                style: TextStyle(
                                                  color: levelColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Professional Cylindrical 3D Tank Widget
                                      WaterTank3D(
                                        waterLevel: waterLevel,
                                        maxCapacity:
                                            mainTankProvider
                                                .mainTank
                                                ?.maxCapacity ??
                                            1.0,
                                        currentLevel:
                                            mainTankProvider
                                                .mainTank
                                                ?.currentLevel ??
                                            0.0,
                                      ),

                                      const SizedBox(height: 32),

                                      // Enhanced refresh button
                                      Center(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              mainTankProvider.isLoading ||
                                                      _isLoadingUser
                                                  ? null
                                                  : () {
                                                    HapticFeedback.mediumImpact();
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
                                                  : const Icon(
                                                    Icons.refresh_rounded,
                                                  ),
                                          label: Text(
                                            (mainTankProvider.isLoading ||
                                                    _isLoadingUser)
                                                ? 'Refreshing...'
                                                : 'Refresh Data',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Constants.primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 28,
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            elevation: 4,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Enhanced last updated text
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Text(
                                            '🕒 Last updated: Just now',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Constants.greyColor,
                                              fontWeight: FontWeight.w500,
                                            ),
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
                      ),

                      const SizedBox(height: 30),

                      // Enhanced quick actions section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Constants.primaryColor.withAlpha(30),
                                    Constants.primaryColor.withAlpha(10),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.dashboard_rounded,
                                color: Constants.primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Constants.primaryColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Enhanced action buttons grid with animations
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.water_rounded,
                                    label: 'My Tanks',
                                    color: Constants.primaryColor,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      Navigator.pushNamed(
                                        context,
                                        RouteManager.tanksRoute,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.person_rounded,
                                    label: 'Profile',
                                    color: const Color(0xFF9C27B0),
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      Navigator.pushNamed(
                                        context,
                                        RouteManager.profileRoute,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.receipt_rounded,
                                    label: 'My Bills',
                                    color: const Color(0xFF10B981),
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      Navigator.pushNamed(
                                        context,
                                        RouteManager.billsRoute,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.notifications_active_rounded,
                                    label: 'Notifications',
                                    color: const Color(0xFFEF4444),
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      Navigator.pushNamed(
                                        context,
                                        RouteManager.notificationsRoute,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced method to build modern action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withAlpha(30), color.withAlpha(10)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withAlpha(50), width: 1),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build responsive loading header with shimmer
  Widget _buildLoadingHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasSpace = constraints.maxHeight > 140;

        return Shimmer.fromColors(
          baseColor: Colors.white.withAlpha(30),
          highlightColor: Colors.white.withAlpha(80),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Loading avatar placeholder with responsive size
                  Container(
                    height: hasSpace ? 60 : 50,
                    width: hasSpace ? 60 : 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(hasSpace ? 18 : 15),
                    ),
                  ),
                  SizedBox(width: hasSpace ? 16 : 12),
                  // Loading text placeholders
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: hasSpace ? 18 : 16,
                          width: constraints.maxWidth * 0.4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: hasSpace ? 12 : 11,
                          width: constraints.maxWidth * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (hasSpace) ...[
                const SizedBox(height: 16),
                // Loading placeholders for user info (only if space available)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: constraints.maxWidth * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: constraints.maxWidth * 0.8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
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

  // Enhanced method to build overflow-safe user header in drawer
  Widget _buildEnhancedUserHeader() {
    final user = _currentUser;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final displayName = user?.name ?? authProvider.userName ?? 'User';
    final displayEmail = user?.email ?? 'No email available';
    final joinDate = user?.getFormattedJoinDate() ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we have enough space for full content
        final hasSpace = constraints.maxHeight > 140;

        return Column(
          mainAxisSize:
              MainAxisSize.min, // Important: Don't take more space than needed
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced profile section with responsive sizing
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Modern avatar with responsive size
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated background circle with responsive size
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        final size = hasSpace ? 80.0 : 70.0;
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 1.5,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withAlpha(30),
                                  Colors.white.withAlpha(10),
                                  Colors.white.withAlpha(30),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Profile image container with responsive size
                    Container(
                      height: hasSpace ? 60 : 50,
                      width: hasSpace ? 60 : 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(hasSpace ? 18 : 15),
                        border: Border.all(
                          color: Colors.white.withAlpha(100),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child:
                          user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  hasSpace ? 16 : 13,
                                ),
                                child: Image.network(
                                  user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildEnhancedDefaultAvatar();
                                  },
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Constants.primaryColor,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              )
                              : _buildEnhancedDefaultAvatar(),
                    ),
                  ],
                ),
                SizedBox(width: hasSpace ? 16 : 12),
                // Enhanced user information with flexible layout
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User name with responsive font size
                      Text(
                        displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: hasSpace ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: hasSpace ? 6 : 4),
                      // Email with icon
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.white.withAlpha(180),
                            size: hasSpace ? 14 : 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayEmail,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: hasSpace ? 13 : 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Join date only if we have space and it's not empty
                      if (hasSpace && joinDate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white.withAlpha(160),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Joined $joinDate',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Add app branding section to fill space when available
            if (hasSpace) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(25),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Smart Water System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Enhanced default avatar with responsive styling
  Widget _buildEnhancedDefaultAvatar() {
    final user = _currentUser;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final displayName = user?.name ?? authProvider.userName ?? 'User';
    final initials = _getInitials(displayName);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine size based on container constraints
        final isLarge = constraints.maxWidth > 55;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF667EEA).withAlpha(200),
                Constants.primaryColor.withAlpha(200),
                Constants.secondaryColor.withAlpha(200),
              ],
            ),
            borderRadius: BorderRadius.circular(isLarge ? 16 : 13),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: isLarge ? 24 : 20, // Responsive font size
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  // Enhanced method to build modern drawer items with better UX
  Widget _buildEnhancedDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
    int? badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withAlpha(30),
          highlightColor: color.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ), // Larger touch target
            decoration: BoxDecoration(
              color: isActive ? color.withAlpha(20) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border:
                  isActive
                      ? Border.all(color: color.withAlpha(100), width: 1)
                      : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // Larger icon container
                  decoration: BoxDecoration(
                    color: isActive ? color.withAlpha(30) : color.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withAlpha(isActive ? 100 : 50),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22, // Slightly larger icons
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive ? color : Colors.black87,
                      fontSize: 16, // Larger text for better readability
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (badge != null && badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withAlpha(50),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badge > 99 ? '99+' : badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for consistent navigation from drawer with improved UX
  void _navigateFromDrawer(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer
    if (route == RouteManager.homeRoute) {
      return; // Already on home screen
    }
    Navigator.pushNamed(context, route);
  }

  // Helper method for drawer actions with proper feedback
  void _handleDrawerAction(
    BuildContext context,
    VoidCallback action, {
    bool isDestructive = false,
  }) {
    if (isDestructive) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    Navigator.pop(context); // Close drawer first

    // Add delay for smooth drawer closing
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        action();
      }
    });
  }

  // Helper method to build consistent dividers
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.withAlpha(30),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // Helper method to show snackbar messages
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : Constants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Clean and simple notification icon with minimal design
  Widget _buildEnhancedNotificationIcon(int unreadCount) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale:
              unreadCount > 0
                  ? _pulseAnimation.value * _bounceAnimation.value
                  : 1.0,
          child: Container(
            margin: const EdgeInsets.all(2),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Simple notification button - no shadows
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: Tooltip(
                    message:
                        unreadCount > 0
                            ? '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}'
                            : 'Notifications',
                    preferBelow: false,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: withValues(Colors.black, 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(
                          context,
                          RouteManager.notificationsRoute,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          unreadCount > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Simple notification counter positioned closer to icon
                if (unreadCount > 0)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: unreadCount > 9 ? 3 : 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722), // Simple solid color
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build empty state when user has no tank data
  Widget _buildNoTankDataState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.water_drop_outlined,
                color: Colors.grey.shade400,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Tank Assigned',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact admin to assign a tank',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Empty state illustration
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Tank Data Available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You don\'t have any tanks assigned to your account',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Refresh button
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _fetchMainTankData();
              _fetchUserData();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Refresh Data',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  // Build error state when there's an actual error
  Widget _buildErrorState(String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connection Error',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unable to load tank data',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Error state illustration
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  errorMessage,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade500),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Retry button
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _fetchMainTankData();
              _fetchUserData();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Try Again',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }
}
