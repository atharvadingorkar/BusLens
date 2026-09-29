import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<dynamic> trips = [];

  @override
  void initState() {
    super.initState();
    loadTripHistory();
  }

  Future<void> loadTripHistory() async {
    try {
      final result = await ApiService.getTrips();

      if (!mounted) return;

      setState(() {
        trips = result.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load trip history';
        isLoading = false;
      });
    }
  }

  String formatValue(dynamic value) {
    if (value == null) {
      return 'Not Available';
    }

    return value.toString();
  }

  String getTripStatus(dynamic trip) {
    final arrivalTime = trip['arrival_time'];

    if (arrivalTime == null ||
        arrivalTime.toString().isEmpty ||
        arrivalTime.toString() == 'null') {
      return 'In Progress';
    }

    return 'Completed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.red,
            ),
          ),
        ),
      )
          : trips.isEmpty
          ? const Center(
        child: Text(
          'No trip history available',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadTripHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];

            final busNumber =
            formatValue(trip['bus_number']);

            final routeName =
            formatValue(trip['route_name']);

            final source =
            formatValue(trip['source']);

            final destination =
            formatValue(trip['destination']);

            final date =
            formatValue(trip['travel_date']);

            final departure =
            formatValue(trip['departure_time']);

            final arrival =
            formatValue(trip['arrival_time']);

            final duration =
            formatValue(trip['travel_duration']);

            final status =
            getTripStatus(trip);

            return Card(
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding:
                      EdgeInsets.zero,

                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.directions_bus,
                        ),
                      ),

                      title: Text(
                        'Bus $busNumber',
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      subtitle: Text(
                        routeName,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),

                      trailing: Text(
                        status,
                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          color: status ==
                              'Completed'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),

                    const Divider(),

                    Row(
                      children: [
                        const Icon(
                          Icons.route,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$source → $destination',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Date: $date',
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Departure: $departure',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.flag,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Arrival: $arrival',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.timer,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: $duration',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}