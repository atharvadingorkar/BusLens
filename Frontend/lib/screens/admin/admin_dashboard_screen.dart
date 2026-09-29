
import 'package:flutter/material.dart';
import 'manage_buses_screen.dart';
import 'manage_routes_screen.dart';
import 'manage_operators_screen.dart';
import 'reports_screen.dart';
import 'assign_bus_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,

          children: [

            // Manage Buses
            FeatureCard(
              title: 'Manage Buses',
              icon: Icons.directions_bus,

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const ManageBusesScreen(),
                  ),
                );
              },
            ),

            // Manage Routes
            FeatureCard(
              title: 'Manage Routes',
              icon: Icons.route,

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const ManageRoutesScreen(),
                  ),
                );
              },
            ),

            // Manage Operators
            FeatureCard(
              title: 'Manage Operators',
              icon: Icons.people,

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const ManageOperatorsScreen(),
                  ),
                );
              },
            ),

            // Assign Bus
            FeatureCard(
              title: 'Assign Bus',
              icon: Icons.assignment_ind,

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const AssignBusScreen(),
                  ),
                );
              },
            ),

            // Reports
            FeatureCard(
              title: 'Reports',
              icon: Icons.analytics,

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const ReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),

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
      ),
    );
  }
}