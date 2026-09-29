import 'package:flutter/material.dart';
import 'my_buses_screen.dart';
import 'trip_history_screen.dart';

class OperatorDashboardScreen extends StatelessWidget {
  final int operatorId;

  const OperatorDashboardScreen({
    super.key,
    required this.operatorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Dashboard'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,

          children: [

            // My Buses
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyBusesScreen(
                      operatorId: operatorId,
                    ),
                  ),
                );
              },

              child: const FeatureCard(
                title: 'My Buses',
                icon: Icons.directions_bus,
              ),
            ),

            // Trip History
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const TripHistoryScreen(),
                  ),
                );
              },

              child: const FeatureCard(
                title: 'Trip History',
                icon: Icons.history,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Feature Card
class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Icon(
            icon,
            size: 50,
            color: Colors.blue,
          ),

          const SizedBox(height: 10),

          Text(
            title,
            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}