
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'operator_bus_details_screen.dart';

class MyBusesScreen extends StatefulWidget {
  final int operatorId;

  const MyBusesScreen({
    super.key,
    required this.operatorId,
  });

  @override
  State<MyBusesScreen> createState() => _MyBusesScreenState();
}

class _MyBusesScreenState extends State<MyBusesScreen> {
  List<dynamic> buses = [];

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadOperatorBuses();
  }

  // Load buses assigned to the logged-in operator
  Future<void> loadOperatorBuses() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await ApiService.getOperatorBuses(
        widget.operatorId,
      );

      if (!mounted) return;

      setState(() {
        buses = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load assigned buses';
      });

      debugPrint('Error loading operator buses: $e');
    }
  }

  // Build a bus card
  Widget buildBusCard(Map<String, dynamic> bus) {
    final int? busId = bus['bus_id'] is int
        ? bus['bus_id']
        : int.tryParse(
      bus['bus_id']?.toString() ?? '',
    );

    final String busNumber =
        bus['bus_number']?.toString() ?? 'Unknown';

    final String busName =
        bus['bus_name']?.toString() ?? 'Unknown Bus';

    final String capacity =
        bus['capacity']?.toString() ?? 'Not available';

    final String status =
        bus['status']?.toString() ?? 'Unknown';

    final bool isActive =
        status.toLowerCase() == 'active';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            Icons.directions_bus,
            color: Colors.blue.shade700,
            size: 28,
          ),
        ),

        title: Text(
          'Bus $busNumber',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                busName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 5),

              Text(
                'Capacity: $capacity',
              ),

              const SizedBox(height: 5),

              Text(
                'Status: ${status.toUpperCase()}',
                style: TextStyle(
                  color: isActive
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),

        onTap: () {
          if (busId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Bus ID is not available',
                ),
              ),
            );

            return;
          }

          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (context) =>
                  OperatorBusDetailsScreen(
                    busId: busId,
                    busName: busName,
                  ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Buses'),

        actions: [
          IconButton(
            onPressed: loadOperatorBuses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )

          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
            ),

            const SizedBox(height: 15),

            Text(errorMessage),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadOperatorBuses,
              child: const Text('Retry'),
            ),
          ],
        ),
      )

          : buses.isEmpty
          ? RefreshIndicator(
        onRefresh: loadOperatorBuses,

        child: ListView(
          children: const [
            SizedBox(height: 250),

            Center(
              child: Text(
                'No buses assigned to you',
              ),
            ),
          ],
        ),
      )

          : RefreshIndicator(
        onRefresh: loadOperatorBuses,

        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ),

          itemCount: buses.length,

          itemBuilder: (context, index) {
            final bus =
            Map<String, dynamic>.from(
              buses[index],
            );

            return buildBusCard(bus);
          },
        ),
      ),
    );
  }
}