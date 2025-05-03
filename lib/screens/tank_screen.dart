import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:mytank/components/custom_button.dart';
import 'package:mytank/components/custom_text.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/providers/tanks_provider.dart';
import 'package:mytank/models/tank_model.dart';

class TankScreen extends StatefulWidget {
  const TankScreen({super.key});

  @override
  State<TankScreen> createState() => _TankScreenState();
}

class _TankScreenState extends State<TankScreen> {
  String? lowerMargin;
  String? higherMargin;
  bool isLoading = false;
  Tank? selectedTank;
  int selectedTankIndex = 0;

  // Helper method to replace deprecated withOpacity
  Color withValues(Color color, double opacity) => Color.fromRGBO(
    color.r.toInt(),
    color.g.toInt(),
    color.b.toInt(),
    opacity,
  );

  @override
  void initState() {
    super.initState();
    _fetchTanks();
  }

  Future<void> _fetchTanks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final tanksProvider = Provider.of<TanksProvider>(context, listen: false);
      await tanksProvider.fetchTanks(context);

      // Get the selected tank if available
      if (tanksProvider.tanks.isNotEmpty) {
        // If we have a previously selected tank, try to find it in the new list
        if (selectedTank != null) {
          final index = tanksProvider.tanks.indexWhere(
            (tank) => tank.id == selectedTank!.id,
          );
          if (index >= 0) {
            setState(() {
              selectedTankIndex = index;
              selectedTank = tanksProvider.tanks[index];
            });
          } else {
            // If not found, default to the first tank
            setState(() {
              selectedTankIndex = 0;
              selectedTank = tanksProvider.tanks.first;
            });
          }
        } else {
          // First load, select the first tank
          setState(() {
            selectedTankIndex = 0;
            selectedTank = tanksProvider.tanks.first;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching tanks: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshTankData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _fetchTanks();
    } catch (e) {
      debugPrint('Error refreshing tank data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getWaterColor(double level) {
    if (level < 0.3) {
      return Colors.red.shade400;
    } else if (level < 0.6) {
      return Colors.orange.shade400;
    } else {
      return const Color.fromARGB(207, 27, 123, 201);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.userName ?? "User";

    // Calculate water level percentage
    double waterLevel = 0.0;
    if (selectedTank != null) {
      waterLevel = selectedTank!.fillPercentage / 100;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        elevation: 0,
        title: const Text('Tank Status', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, RouteManager.homeRoute);
            },
            icon: const Icon(Icons.home, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Constants.primaryColor,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Constants.primaryColor, Constants.secondaryColor],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                CustomText(
                  'Welcome, $userName!',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontColor: Colors.white,
                ),
                const SizedBox(height: 5),
                const CustomText(
                  'Monitor your water tank status',
                  fontSize: 14,
                  fontColor: Colors.white70,
                ),
                const SizedBox(height: 15),

                // Tank selector dropdown
                Consumer<TanksProvider>(
                  builder: (context, tanksProvider, child) {
                    if (tanksProvider.tanks.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: withValues(Colors.white, 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<int>(
                        value: selectedTankIndex,
                        dropdownColor: Constants.primaryColor,
                        underline: Container(),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        isExpanded: true,
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedTankIndex = newValue;
                              selectedTank = tanksProvider.tanks[newValue];
                            });
                          }
                        },
                        items: List.generate(
                          tanksProvider.tanks.length,
                          (index) => DropdownMenuItem<int>(
                            value: index,
                            child: Text(
                              tanksProvider.tanks[index].name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Water level indicator card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const CustomText(
                              'CURRENT WATER LEVEL',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontColor: Colors.black87,
                            ),
                            const SizedBox(height: 5),
                            CustomText(
                              '${(waterLevel * 100).toInt()}%',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontColor: getWaterColor(waterLevel),
                            ),
                            const SizedBox(height: 20),

                            // Liquid progress indicator
                            SizedBox(
                              height: screenSize.height * 0.3,
                              width: screenSize.width * 0.5,
                              child: LiquidCircularProgressIndicator(
                                value: waterLevel,
                                valueColor: AlwaysStoppedAnimation(
                                  getWaterColor(waterLevel),
                                ),
                                backgroundColor: Colors.white,
                                direction: Axis.vertical,
                                center: CustomText(
                                  '${(waterLevel * 100).toInt()}%',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontColor: Colors.white,
                                ),
                                borderColor: Constants.primaryColor,
                                borderWidth: 5,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Refresh button
                            isLoading
                                ? CircularProgressIndicator(
                                  color: Constants.primaryColor,
                                )
                                : CustomButton(
                                  'Refresh Data',
                                  mediaQueryData: mediaQuery,
                                  width: screenSize.width * 0.5,
                                  onPressed: refreshTankData,
                                ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Threshold settings card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const CustomText(
                              'THRESHOLD SETTINGS',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontColor: Colors.black87,
                            ),
                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    const CustomText(
                                      'Lower Margin',
                                      fontSize: 14,
                                      fontColor: Colors.grey,
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Constants.lightGreyColor,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: DropdownButton<String>(
                                        value: lowerMargin,
                                        hint: const Text('Select'),
                                        underline: Container(),
                                        items: const [
                                          DropdownMenuItem<String>(
                                            value: '10',
                                            child: Text('10%'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: '20',
                                            child: Text('20%'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: '30',
                                            child: Text('30%'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: '40',
                                            child: Text('40%'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: '50',
                                            child: Text('50%'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            lowerMargin = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const CustomText(
                                      'Higher Margin',
                                      fontSize: 14,
                                      fontColor: Colors.grey,
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Constants.lightGreyColor,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: DropdownButton<String>(
                                        value: higherMargin,
                                        hint: const Text('Select'),
                                        underline: Container(),
                                        items: const [
                                          DropdownMenuItem<String>(
                                            value: '60',
                                            child: Text('60%'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: '70',
                                            child: Text('70%'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: '80',
                                            child: Text('80%'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: '90',
                                            child: Text('90%'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: '100',
                                            child: Text('100%'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            higherMargin = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            CustomButton(
                              'Save Settings',
                              mediaQueryData: mediaQuery,
                              width: double.infinity,
                              onPressed: () {
                                // Save threshold settings
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Settings saved successfully',
                                    ),
                                    backgroundColor: Constants.successColor,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Water usage statistics card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const CustomText(
                                  'WATER USAGE STATISTICS',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontColor: Colors.black87,
                                ),
                                if (selectedTank != null)
                                  CustomText(
                                    selectedTank!.getCurrentMonthName(),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontColor: Constants.primaryColor,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Water in row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const CustomText(
                                  'Water in:',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontColor: Colors.black87,
                                  textAlign: TextAlign.left,
                                ),
                                Row(
                                  children: [
                                    CustomText(
                                      selectedTank != null
                                          ? '${selectedTank!.getWaterInflow().toStringAsFixed(0)} L'
                                          : '0 L',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontColor: Constants.primaryColor,
                                    ),
                                    IconButton(
                                      onPressed: refreshTankData,
                                      icon: const Icon(
                                        Icons.refresh,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const Divider(),

                            // Water out row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const CustomText(
                                  'Water out:',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontColor: Colors.black87,
                                  textAlign: TextAlign.left,
                                ),
                                Row(
                                  children: [
                                    CustomText(
                                      selectedTank != null
                                          ? '${selectedTank!.getWaterOutflow().toStringAsFixed(0)} L'
                                          : '0 L',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontColor: Constants.primaryColor,
                                    ),
                                    IconButton(
                                      onPressed: refreshTankData,
                                      icon: const Icon(
                                        Icons.refresh,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const Divider(),

                            // Total usage row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const CustomText(
                                  'Total usage:',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontColor: Colors.black87,
                                  textAlign: TextAlign.left,
                                ),
                                CustomText(
                                  selectedTank != null
                                      ? '${selectedTank!.getCurrentMonthUsage().toStringAsFixed(0)} L'
                                      : '0 L',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontColor: Constants.primaryColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
