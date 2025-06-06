import 'package:flutter/material.dart';
import 'package:mytank/models/tank_model.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/providers/tanks_provider.dart';
import 'package:mytank/providers/main_tank_provider.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/widgets/tank_shimmer_loading.dart';
import 'package:mytank/widgets/water_tank_3d.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

// Helper method to replace deprecated withOpacity
Color withValues(Color color, double opacity) =>
    Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), opacity);

class TanksScreen extends StatefulWidget {
  const TanksScreen({super.key});

  @override
  State<TanksScreen> createState() => _TanksScreenState();
}

class _TanksScreenState extends State<TanksScreen> {
  bool _isLoading = true;
  int _selectedTankIndex = 0;
  double _monthlyCapacity = 0;
  double _maxCapacity = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
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





  Widget _buildCapacityCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: withValues(Constants.primaryColor, 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: withValues(color, 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Constants.blackColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Constants.blackColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 5),
          Text(
            'Tank capacity',
            style: TextStyle(fontSize: 12, color: Constants.greyColor),
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
      backgroundColor: Constants.backgroundColor,
      body:
          _isLoading
              ? const TankShimmerLoadingEffect()
              : tanks.isEmpty
              ? const Center(
                child: Text(
                  'No tanks found. Please add a tank to get started.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
              : _buildMainContent(screenSize, tanks, selectedTank, userName),
    );
  }

  // Build main content
  Widget _buildMainContent(Size screenSize, List<Tank> tanks, Tank? selectedTank, String userName) {
    // Calculate water level and capacity values
    double waterLevel = 0.0;
    double currentLevelLiters = 0.0;
    double maxCapacityLiters = 0.0;
    if (selectedTank != null) {
      waterLevel = (selectedTank.currentLevel / selectedTank.maxCapacity).clamp(0.0, 1.0);
      currentLevelLiters = selectedTank.currentLevel;
      maxCapacityLiters = selectedTank.maxCapacity;

      // Update monthly capacity and max capacity based on tank data
      _monthlyCapacity = selectedTank.monthlyCapacity;
      _maxCapacity = selectedTank.maxCapacity;
    }

    return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: screenSize.height * 0.22,
                      pinned: true,
                      backgroundColor: Constants.primaryColor,
                      elevation: innerBoxIsScrolled ? 4 : 0,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: withValues(Colors.white, 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: withValues(Colors.white, 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _fetchData,
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        title: null, // Remove default title
                        centerTitle: true,
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1E3A8A), // Deeper blue
                                Constants.primaryColor,
                                Constants.secondaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Column(
                                children: [
                                  // Custom positioned title
                                  const Text(
                                    'My Tanks',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: withValues(Colors.white, 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Smart Water System',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                ],
                              ),
                            ),
                          ),
                        ),
                        collapseMode: CollapseMode.parallax,
                      ),
                    ),
                  ];
                },
                body: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                    children: [
                      // Tank selector if there are multiple tanks
                      if (tanks.length > 1)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: withValues(Constants.primaryColor, 0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: _selectedTankIndex,
                              hint: const Text('Select Tank'),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Constants.primaryColor,
                              ),
                              items: List.generate(
                                tanks.length,
                                (index) => DropdownMenuItem<int>(
                                  value: index,
                                  child: Text(
                                    'Tank ${tanks[index].id.substring(tanks[index].id.length - 6)}',
                                    style: TextStyle(
                                      color: Constants.blackColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedTankIndex = value;
                                  });

                                  // Fetch detailed data for the newly selected tank
                                  final tanksProvider = Provider.of<TanksProvider>(context, listen: false);
                                  if (tanksProvider.tanks.isNotEmpty) {
                                    final selectedTank = tanksProvider.tanks[value];
                                    _fetchTankDetails(selectedTank.id);
                                  }
                                }
                              },
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      // Tank status summary card
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(20),
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
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: withValues(Colors.white, 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    waterLevel < 0.3
                                        ? 'Low'
                                        : waterLevel < 0.7
                                        ? 'Normal'
                                        : 'Full',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                const Icon(
                                  Icons.water_drop_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Current Level: ${currentLevelLiters.toStringAsFixed(1)} L',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.water,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Capacity: ${maxCapacityLiters.toStringAsFixed(1)} L',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Modern water level indicator card
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: withValues(Constants.primaryColor, 0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          waterLevel < 0.3
                                              ? withValues(
                                                Constants.errorColor,
                                                0.15,
                                              )
                                              : waterLevel < 0.6
                                              ? withValues(
                                                Constants.warningColor,
                                                0.15,
                                              )
                                              : withValues(
                                                Constants.primaryColor,
                                                0.15,
                                              ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.water_drop,
                                      color:
                                          waterLevel < 0.3
                                              ? Constants.errorColor
                                              : waterLevel < 0.6
                                              ? Constants.warningColor
                                              : Constants.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Water Level',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Constants.blackColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${currentLevelLiters.toStringAsFixed(1)} L / ${maxCapacityLiters.toStringAsFixed(1)} L',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Constants.greyColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          waterLevel < 0.3
                                              ? withValues(
                                                Constants.errorColor,
                                                0.15,
                                              )
                                              : waterLevel < 0.6
                                              ? withValues(
                                                Constants.warningColor,
                                                0.15,
                                              )
                                              : withValues(
                                                Constants.primaryColor,
                                                0.15,
                                              ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${(waterLevel * 100).toStringAsFixed(1)}%",
                                      style: TextStyle(
                                        color:
                                            waterLevel < 0.3
                                                ? Constants.errorColor
                                                : waterLevel < 0.6
                                                ? Constants.warningColor
                                                : Constants.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
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
                          ],
                        ),
                      ),

                      // Capacity Information Cards
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: withValues(
                                      Constants.primaryColor,
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.water_drop_outlined,
                                    color: Constants.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  'Tank Capacity',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Constants.blackColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // Capacity cards
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Use column layout on very small screens
                                if (constraints.maxWidth < 300) {
                                  return Column(
                                    children: [
                                      _buildCapacityCard(
                                        title: 'Monthly Capacity',
                                        value: _monthlyCapacity,
                                        icon: Icons.calendar_month_rounded,
                                        color: Constants.primaryColor,
                                        unit: 'L',
                                      ),
                                      const SizedBox(height: 15),
                                      _buildCapacityCard(
                                        title: 'Max Capacity',
                                        value: _maxCapacity,
                                        icon: Icons.water_drop_rounded,
                                        color: Constants.warningColor,
                                        unit: 'L',
                                      ),
                                    ],
                                  );
                                }
                                // Use row layout for normal screens
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildCapacityCard(
                                        title: 'Monthly Capacity',
                                        value: _monthlyCapacity,
                                        icon: Icons.calendar_month_rounded,
                                        color: Constants.primaryColor,
                                        unit: 'L',
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _buildCapacityCard(
                                        title: 'Max Capacity',
                                        value: _maxCapacity,
                                        icon: Icons.water_drop_rounded,
                                        color: Constants.warningColor,
                                        unit: 'L',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Usage Statistics Cards
                      Consumer<MainTankProvider>(
                        builder: (context, mainTankProvider, child) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: withValues(
                                          Constants.primaryColor,
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.analytics_rounded,
                                        color: Constants.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      'Usage Statistics',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Constants.blackColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),

                                // First row of cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildUsageStatCard(
                                        'Today',
                                        mainTankProvider.formatUsage(mainTankProvider.currentDayUsage),
                                        Icons.today_rounded,
                                        Constants.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildUsageStatCard(
                                        'This Week',
                                        mainTankProvider.formatUsage(mainTankProvider.currentWeekUsage),
                                        Icons.calendar_view_week_rounded,
                                        Constants.successColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Second row of cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildUsageStatCard(
                                        'Daily Avg',
                                        mainTankProvider.formatUsage(mainTankProvider.dailyAverageUsage),
                                        Icons.trending_up_rounded,
                                        Constants.warningColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildUsageStatCard(
                                        'This Month',
                                        mainTankProvider.formatUsage(mainTankProvider.currentMonthUsage),
                                        Icons.calendar_month_rounded,
                                        Constants.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Usage history card
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: withValues(Constants.primaryColor, 0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
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
                                    color: withValues(
                                      Constants.primaryColor,
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.show_chart_rounded,
                                    color: Constants.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedTank != null
                                            ? 'Monthly Water Usage - ${selectedTank.getCurrentMonthName()}'
                                            : 'Monthly Water Usage',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Constants.blackColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'All days of the month • Wave chart',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Constants.greyColor,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Wave chart for all days of the month
                            Container(
                              height: screenSize.height * 0.35,
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: withValues(Colors.grey, 0.1),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: selectedTank != null
                                  ? LineChart(
                                      LineChartData(
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: _getMaxChartValue(selectedTank) / 4,
                                          getDrawingHorizontalLine: (value) {
                                            return FlLine(
                                              color: withValues(Constants.greyColor, 0.1),
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
                                                        color: Constants.greyColor,
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
                                                    color: Constants.greyColor,
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
                                            spots: _getAllDaysUsage(selectedTank)
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final day = entry.key + 1;
                                              final usage = entry.value;
                                              return FlSpot(day.toDouble(), usage);
                                            }).toList(),
                                            isCurved: true,
                                            curveSmoothness: 0.35,
                                            color: const Color(0xFF2196F3),
                                            barWidth: 3,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(
                                              show: true,
                                              getDotPainter: (spot, percent, barData, index) {
                                                return FlDotCirclePainter(
                                                  radius: 4,
                                                  color: const Color(0xFF2196F3),
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
                                                  withValues(const Color(0xFF2196F3), 0.3),
                                                  withValues(const Color(0xFF2196F3), 0.1),
                                                  withValues(const Color(0xFF2196F3), 0.05),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                        lineTouchData: LineTouchData(
                                          enabled: true,
                                          touchTooltipData: LineTouchTooltipData(
                                            getTooltipColor: (touchedSpot) =>
                                                withValues(const Color(0xFF2196F3), 0.8),
                                            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
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
                                            color: withValues(Constants.greyColor, 0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Select a tank to view usage data',
                                            style: TextStyle(
                                              color: Constants.greyColor,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // Add some bottom padding
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
  }

  // Helper method to build usage statistics cards with improved styling
  Widget _buildUsageStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: withValues(Constants.primaryColor, 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: withValues(color, 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: withValues(color, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Constants.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Water usage',
            style: TextStyle(
              fontSize: 12,
              color: Constants.greyColor,
            ),
          ),
        ],
      ),
    );
  }


}
