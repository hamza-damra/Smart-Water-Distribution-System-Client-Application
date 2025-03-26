// tanks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tanks_provider.dart';
import '../utilities/route_manager.dart';
import '../widgets/tank_card.dart';

class TanksScreen extends StatefulWidget {
  const TanksScreen({Key? key}) : super(key: key);

  @override
  State<TanksScreen> createState() => _TanksScreenState();
}

class _TanksScreenState extends State<TanksScreen> {
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _fetchData();
      _isInit = true;
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Pass context so TanksProvider can retrieve the token from AuthProvider.
      await Provider.of<TanksProvider>(context, listen: false).fetchTanks(context);
    } catch (error) {
      debugPrint('Error fetching tanks: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanksProvider = Provider.of<TanksProvider>(context);
    final tanks = tanksProvider.tanks;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tanks Screen'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : tanks.isEmpty
          ? const Center(
        child: Text(
          'No tanks found.',
          style: TextStyle(color: Colors.white),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display the number of tanks
            Text(
              'Tanks: ${tanks.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Generate a vertical list of TankCards
            for (var tank in tanks) ...[
              Container(
                width: double.infinity, // Fill the screen width
                margin: const EdgeInsets.only(bottom: 16),
                child: TankCard(
                  tank: tank,
                  onReadMore: () {
                    Navigator.pushNamed(
                      context,
                      RouteManager.tankDetailsRoute,
                      arguments: tank.id, // Pass the tank's ID here
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
