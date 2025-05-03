import 'dart:math';
import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:mytank/models/tank_model.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/providers/tanks_provider.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/widgets/tank_shimmer_loading.dart';
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
  double _inletVolume = 0;
  double _outletVolume = 0;

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
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFlowRateCard({
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Constants.blackColor,
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
          ),
          const SizedBox(height: 5),
          Text(
            'Last 30 days',
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

    // Calculate water level as a value between 0.0 and 1.0
    double waterLevel = 0.0;
    double currentLevelLiters = 0.0;
    double maxCapacityLiters = 0.0;
    double monthlyUsage = 0.0;

    if (selectedTank != null) {
      waterLevel = (selectedTank.currentLevel / selectedTank.maxCapacity).clamp(
        0.0,
        1.0,
      );
      currentLevelLiters = selectedTank.currentLevel;
      maxCapacityLiters = selectedTank.maxCapacity;
      monthlyUsage = selectedTank.getCurrentMonthUsage();

      // Update inlet and outlet volumes based on tank data
      if (_inletVolume == 0) {
        _inletVolume = monthlyUsage;
      }

      if (_outletVolume == 0) {
        _outletVolume = maxCapacityLiters - currentLevelLiters;
        if (_outletVolume < 0) _outletVolume = 0;
      }
    }

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
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 180,
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

                                  // User greeting
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: withValues(
                                              Colors.white,
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hi $userName!',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Welcome to your tank dashboard',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
                body: SingleChildScrollView(
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
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedTankIndex = value;
                                  });
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
                                Text(
                                  'Current Level: ${currentLevelLiters.toStringAsFixed(1)} L',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
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
                                Text(
                                  'Capacity: ${maxCapacityLiters.toStringAsFixed(1)} L',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
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
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${currentLevelLiters.toStringAsFixed(1)} L / ${maxCapacityLiters.toStringAsFixed(1)} L',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Constants.greyColor,
                                        ),
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

                            // Modern liquid indicator
                            Container(
                              height: screenSize.height * 0.25,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              child: LiquidCircularProgressIndicator(
                                value: waterLevel,
                                valueColor: AlwaysStoppedAnimation(
                                  waterLevel < 0.3
                                      ? Constants.errorColor
                                      : waterLevel < 0.6
                                      ? Constants.warningColor
                                      : Constants.primaryColor,
                                ),
                                backgroundColor: Constants.backgroundColor,
                                direction: Axis.vertical,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${(waterLevel * 100).toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            waterLevel < 0.3
                                                ? Constants.errorColor
                                                : waterLevel < 0.6
                                                ? Constants.warningColor
                                                : Colors.white,
                                      ),
                                    ),
                                    if (waterLevel < 0.3)
                                      Text(
                                        "Low Level",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Constants.errorColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                borderColor: Colors.transparent,
                                borderWidth: 0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Flow rate cards
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildFlowRateCard(
                                title: 'Inlet Flow',
                                value: _inletVolume,
                                icon: Icons.arrow_downward_rounded,
                                color: Constants.primaryColor,
                                unit: 'L',
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildFlowRateCard(
                                title: 'Outlet Flow',
                                value: _outletVolume,
                                icon: Icons.arrow_upward_rounded,
                                color: Constants.warningColor,
                                unit: 'L',
                              ),
                            ),
                          ],
                        ),
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
                                    Icons.history_rounded,
                                    color: Constants.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  'Usage History',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Constants.blackColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 100,
                                  barTouchData: BarTouchData(enabled: true),
                                  titlesData: const FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(
                                    7,
                                    (index) => BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: Random().nextDouble() * 80 + 10,
                                          color: Constants.primaryColor,
                                          width: 15,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(6),
                                            topRight: Radius.circular(6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
}
