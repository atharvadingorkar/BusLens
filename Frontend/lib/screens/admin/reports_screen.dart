import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<Map<String, dynamic>> reportsFuture;

  @override
  void initState() {
    super.initState();
    reportsFuture = ApiService.getAdminReports();
  }

  Widget reportCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.blue,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: reportsFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading reports:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No report data available'),
            );
          }

          final reports = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),

            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,

              children: [
                reportCard(
                  title: 'Total Buses',
                  value: '${reports['total_buses']}',
                  icon: Icons.directions_bus,
                ),

                reportCard(
                  title: 'Active Buses',
                  value: '${reports['active_buses']}',
                  icon: Icons.check_circle,
                ),

                reportCard(
                  title: 'Total Routes',
                  value: '${reports['total_routes']}',
                  icon: Icons.route,
                ),

                reportCard(
                  title: 'Active Routes',
                  value: '${reports['active_routes']}',
                  icon: Icons.alt_route,
                ),

                reportCard(
                  title: 'Total Operators',
                  value: '${reports['total_operators']}',
                  icon: Icons.people,
                ),

                reportCard(
                  title: 'Total Trips',
                  value: '${reports['total_trips']}',
                  icon: Icons.directions_transit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}