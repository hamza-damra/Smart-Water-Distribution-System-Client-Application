import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytank/models/tank_model.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/providers/tanks_provider.dart';
import 'package:mytank/providers/main_tank_provider.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/widgets/tank_shimmer_loading.dart';
import 'package:mytank/widgets/water_tank_3d.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:mytank/utilities/route_manager.dart';

// Helper method to replace deprecated withOpacity
Color withValues(Color color, double opacity) =>
    Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), opacity);

class TanksScreen extends StatefulWidget {
  const TanksScreen({super.key});

  @override
  State<TanksScreen> createState() => _TanksScreenState();
}

class _TanksScreenState extends State<TanksScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  int _selectedTankIndex = 0;
  double _monthlyCapacity = 0;
  double _maxCapacity = 0;

  // Animation controllers
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchData();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Start background rotation animation
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tanksProvider = Provider.of<TanksProvider>(context, listen: false);
      await tanksProvider.fetchTanks(context);

      // Fetch detailed data for the selected tank
      if (tanksProvider.tanks.isNotEmpty) {
        final selectedTank = tanksProvider.tanks[_selectedTankIndex];
        await tanksProvider.fetchTankDetails(selectedTank.id);
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.mediumImpact();
    await _fetchData();
  }

  // Fetch detailed data for a specific tank
  Future<void> _fetchTankDetails(String tankId) async {
    try {
      final tanksProvider = Provider.of<TanksProvider>(context, listen: false);
      await tanksProvider.fetchTankDetails(tankId);
    } catch (e) {
      debugPrint('Error fetching tank details: $e');
    }
  }

  // Get the maximum value for the chart Y-axis
  double _getMaxChartValue(Tank tank) {
    final usageData = tank.getAllDailyUsageData();
    double maxValue = 0;
    for (var value in usageData) {
      if (value > maxValue) maxValue = value;
    }

    // Add 20% padding to the max value for better visualization
    // If all values are 0, return a default value of 100
    return maxValue > 0 ? maxValue * 1.2 : 100;
  }

  // Get all days usage data for the wave chart
  List<double> _getAllDaysUsage(Tank tank) {
    return tank.getAllDailyUsageData();
  }

  Widget _buildModernCapacityCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required String unit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: color.withAlpha(50), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tanksProvider = Provider.of<TanksProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final tanks = tanksProvider.tanks;
    final userName = authProvider.userName ?? "User";

    // Get the selected tank or default to the first one
    Tank? selectedTank = tanks.isNotEmpty ? tanks[_selectedTankIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern background color
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Constants.primaryColor,
        backgroundColor: Colors.white,
        child:
            _isLoading
                ? const TankShimmerLoadingEffect()
                : tanks.isEmpty
                ? _buildEmptyState()
                : _buildMainContent(screenSize, tanks, selectedTank, userName),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.water_drop_outlined,
                size: 48,
                color: Constants.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Tanks Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first tank to start monitoring water usage and get insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
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
                elevation: 4,
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Add Tank',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build main content
  Widget _buildMainContent(
    Size screenSize,
    List<Tank> tanks,
    Tank? selectedTank,
    String userName,
  ) {
    // Calculate water level and capacity values
    double waterLevel = 0.0;
    double currentLevelLiters = 0.0;
    double maxCapacityLiters = 0.0;
    if (selectedTank != null) {
      waterLevel = (selectedTank.currentLevel / selectedTank.maxCapacity).clamp(
        0.0,
        1.0,
      );
      currentLevelLiters = selectedTank.currentLevel;
      maxCapacityLiters = selectedTank.maxCapacity;

      // Update monthly capacity and max capacity based on tank data
      _monthlyCapacity = selectedTank.monthlyCapacity;
      _maxCapacity = selectedTank.maxCapacity;
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _buildModernAppBar(screenSize),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Tank selector if there are multiple tanks
                if (tanks.length > 1) _buildTankSelector(tanks),
                if (tanks.length > 1) const SizedBox(height: 20),

                // Tank status summary card
                _buildTankStatusCard(
                  waterLevel,
                  currentLevelLiters,
                  maxCapacityLiters,
                ),

                const SizedBox(height: 20),

                // Modern water level indicator card
                _buildWaterLevelCard(
                  waterLevel,
                  currentLevelLiters,
                  maxCapacityLiters,
                ),

                const SizedBox(height: 20),

                // Capacity Information Cards
                _buildCapacitySection(),

                const SizedBox(height: 20),

                // Usage Statistics Cards
                _buildUsageStatisticsSection(),

                const SizedBox(height: 20),

                // Usage history card
                _buildUsageHistoryCard(screenSize, selectedTank),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernAppBar(Size screenSize) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Constants.primaryColor,
      elevation: 0,
      stretch: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _fetchData();
            },
          ),
        ),
      ],
      title: const Text(
        'My Tanks',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        centerTitle: true,
        background: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
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
                      transform: GradientRotation(
                        _rotationAnimation.value * 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Overlay pattern
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(20)],
                ),
              ),
            ),
            // Empty content area
            const SizedBox.shrink(),
          ],
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _buildTankSelector(List<Tank> tanks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.water_drop_outlined,
                  color: Constants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Tank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _selectedTankIndex,
                hint: const Text('Choose a tank'),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Constants.primaryColor,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 8,
                items: List.generate(
                  tanks.length,
                  (index) => DropdownMenuItem<int>(
                    value: index,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _selectedTankIndex == index
                                ? Constants.primaryColor.withAlpha(20)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Constants.primaryColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.water_drop_outlined,
                              color: Constants.primaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tank ${tanks[index].id.substring(tanks[index].id.length - 6)}',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_selectedTankIndex == index)
                            Icon(
                              Icons.check_circle,
                              color: Constants.primaryColor,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedTankIndex = value;
                    });

                    // Navigate to tank details screen
                    Navigator.pushNamed(
                      context,
                      RouteManager.tankDetailsRoute,
                      arguments: {'tankId': tanks[value].id},
                    );

                    // Fetch detailed data for the newly selected tank
                    final tanksProvider = Provider.of<TanksProvider>(
                      context,
                      listen: false,
                    );
                    if (tanksProvider.tanks.isNotEmpty) {
                      final selectedTank = tanksProvider.tanks[value];
                      _fetchTankDetails(selectedTank.id);
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTankStatusCard(
    double waterLevel,
    double currentLevelLiters,
    double maxCapacityLiters,
  ) {
    Color statusColor =
        waterLevel < 0.3
            ? const Color(0xFFEF4444)
            : waterLevel < 0.7
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    String statusText =
        waterLevel < 0.3
            ? 'Low Level'
            : waterLevel < 0.7
            ? 'Normal'
            : 'Optimal';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Constants.primaryColor, Constants.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tank Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Current Level: ${currentLevelLiters.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Capacity: ${maxCapacityLiters.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterLevelCard(
    double waterLevel,
    double currentLevelLiters,
    double maxCapacityLiters,
  ) {
    Color levelColor =
        waterLevel < 0.3
            ? const Color(0xFFEF4444)
            : waterLevel < 0.6
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: levelColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.water_drop, color: levelColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Water Level',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentLevelLiters.toStringAsFixed(2)} L / ${maxCapacityLiters.toStringAsFixed(2)} L',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: levelColor.withAlpha(100),
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
          // Professional Cylindrical 3D Tank Widget
          WaterTank3D(
            waterLevel: waterLevel,
            maxCapacity: maxCapacityLiters,
            currentLevel: currentLevelLiters,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCapacitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: Color(0xFF1890FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tank Capacity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              _buildModernCapacityCard(
                title: 'Monthly Capacity',
                value: _monthlyCapacity,
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF8B5CF6),
                unit: 'L',
              ),
              const SizedBox(height: 16),
              _buildModernCapacityCard(
                title: 'Max Capacity',
                value: _maxCapacity,
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF06B6D4),
                unit: 'L',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatisticsSection() {
    return Consumer<MainTankProvider>(
      builder: (context, mainTankProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Usage Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildModernUsageStatCard(
                      'Today',
                      mainTankProvider.formatUsage(
                        mainTankProvider.currentDayUsage,
                      ),
                      Icons.today_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernUsageStatCard(
                      'This Week',
                      mainTankProvider.formatUsage(
                        mainTankProvider.currentWeekUsage,
                      ),
                      Icons.calendar_view_week_rounded,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernUsageStatCard(
                      'Daily Avg',
                      mainTankProvider.formatUsage(
                        mainTankProvider.dailyAverageUsage,
                      ),
                      Icons.trending_up_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernUsageStatCard(
                      'This Month',
                      mainTankProvider.formatUsage(
                        mainTankProvider.currentMonthUsage,
                      ),
                      Icons.calendar_month_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsageHistoryCard(Size screenSize, Tank? selectedTank) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFFF59E0B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTank != null
                          ? 'Monthly Usage - ${selectedTank.getCurrentMonthName()}'
                          : 'Monthly Water Usage',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daily consumption tracking',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Wave chart for all days of the month
          Container(
            height: screenSize.height * 0.35,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child:
                selectedTank != null
                    ? LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval:
                              _getMaxChartValue(selectedTank) / 4,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final day = value.toInt();
                                if (day % 5 == 0 || day == 1) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      day.toString(),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('0L');
                                return Text(
                                  '${(value).toStringAsFixed(0)}L',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                );
                              },
                              reservedSize: 40,
                              interval: _getMaxChartValue(selectedTank) / 4,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 1,
                        maxX: _getAllDaysUsage(selectedTank).length.toDouble(),
                        minY: 0,
                        maxY: _getMaxChartValue(selectedTank) * 1.1,
                        lineBarsData: [
                          LineChartBarData(
                            spots:
                                _getAllDaysUsage(
                                  selectedTank,
                                ).asMap().entries.map((entry) {
                                  final day = entry.key + 1;
                                  final usage = entry.value;
                                  return FlSpot(day.toDouble(), usage);
                                }).toList(),
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: const Color(0xFF3B82F6),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: const Color(0xFF3B82F6),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF3B82F6).withAlpha(60),
                                  const Color(0xFF3B82F6).withAlpha(20),
                                  const Color(0xFF3B82F6).withAlpha(5),
                                ],
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor:
                                (touchedSpot) =>
                                    const Color(0xFF3B82F6).withAlpha(200),
                            getTooltipItems: (
                              List<LineBarSpot> touchedBarSpots,
                            ) {
                              return touchedBarSpots.map((barSpot) {
                                return LineTooltipItem(
                                  'Day ${barSpot.x.toInt()}\n${barSpot.y.toStringAsFixed(1)}L',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                          handleBuiltInTouches: true,
                        ),
                      ),
                    )
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select a tank to view usage data',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // Helper method to build usage statistics cards with improved styling
  Widget _buildModernUsageStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
