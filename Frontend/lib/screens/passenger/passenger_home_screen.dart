import 'package:flutter/material.dart';

import 'search_bus_screen.dart';
import 'nearby_stops_screen.dart';
import 'my_ticket_screen.dart';
import 'profile_screen.dart';

class PassengerHomeScreen extends StatelessWidget {
  final int userId;
  final String fullName;
  final String email;

  const PassengerHomeScreen({
    super.key,
    required this.userId,
    required this.fullName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BusLens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: userId,
                    fullName: fullName,
                    email: email,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const SearchBusScreen(),
                  ),
                );
              },
              child: const FeatureCard(
                title: 'Search Bus',
                icon: Icons.search,
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const NearbyStopsScreen(),
                  ),
                );
              },
              child: const FeatureCard(
                title: 'Nearby Stops',
                icon: Icons.location_on,
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const MyTicketScreen(
                      ticketId: 1,
                    ),
                  ),
                );
              },
              child: const FeatureCard(
                title: 'My Ticket',
                icon: Icons.confirmation_number,
              ),
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