import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../providers/auth_provider.dart';

// بيانات اليوم الواحد
class DayUsage {
  final int day;
  final double amount;
  DayUsage(this.day, this.amount);
}

// موديل بيانات الخزان
class TankDetail {
  final String id;
  final double currentLevel;
  final double maxCapacity;
  final List<DayUsage> dailyUsage;

  TankDetail({
    required this.id,
    required this.currentLevel,
    required this.maxCapacity,
    required this.dailyUsage,
  });

  factory TankDetail.fromJson(Map<String, dynamic> json) {
    final usageMap = json['amount_per_month']?['days'] as Map<String, dynamic>? ?? {};
    final usage = usageMap.entries.map((entry) {
      return DayUsage(int.parse(entry.key), (entry.value as num).toDouble());
    }).toList();
    return TankDetail(
      id: json['_id'] ?? json['id'],
      currentLevel: (json['current_level'] as num).toDouble(),
      maxCapacity: (json['max_capacity'] as num).toDouble(),
      dailyUsage: usage,
    );
  }
}

class TankDetailsScreen extends StatefulWidget {
  final String tankId;
  const TankDetailsScreen({Key? key, required this.tankId}) : super(key: key);

  @override
  State<TankDetailsScreen> createState() => _TankDetailsScreenState();
}

class _TankDetailsScreenState extends State<TankDetailsScreen> {
  bool _isLoading = false;
  TankDetail? _tankDetail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTankDetails();
  }

  Future<void> _fetchTankDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    final url = Uri.parse(
      'https://smart-water-distribution-system.onrender.com/api/tank/customer-tank/${widget.tankId}',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Cookie': 'access_token=$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _tankDetail = TankDetail.fromJson(data);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load tank details. Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildBarChart(List<DayUsage> usage) {
    usage.sort((a, b) => a.day.compareTo(b.day));
    final barGroups = usage.map((e) {
      return BarChartGroupData(
        x: e.day,
        barRods: [
          BarChartRodData(
            toY: e.amount,
            color: Colors.lightBlueAccent,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: usage.length * 20, // dynamic width
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: usage.map((e) => e.amount).reduce((a, b) => a > b ? a : b) + 5,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final detail = _tankDetail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tank Details'),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : detail == null
          ? const Center(child: Text('No data found.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tank ID: ${detail.id}', style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 10),
            Text('Current Level: ${detail.currentLevel} L', style: const TextStyle(color: Colors.white)),
            Text('Max Capacity: ${detail.maxCapacity} L', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            const Text(
              'Daily Usage (March)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: _buildBarChart(detail.dailyUsage),
            ),
          ],
        ),
      ),
    );
  }
}
