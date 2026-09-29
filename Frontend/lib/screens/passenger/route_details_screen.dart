import 'package:flutter/material.dart';
import 'live_tracking_screen.dart';
import 'recommendation_screen.dart';
import '../../services/api_service.dart';

class RouteDetailsScreen extends StatefulWidget {
  final String busName;
  final int busId;

  const RouteDetailsScreen({
    super.key,
    required this.busName,
    required this.busId,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  Map<String, dynamic>? routeData;

  bool isLoading = true;
  String? errorMessage;

  int? selectedSourceStopId;
  int? selectedDestinationStopId;

  @override
  void initState() {
    super.initState();
    loadRouteDetails();
  }

  // =========================================================
  // LOAD ROUTE DETAILS
  // =========================================================

  Future<void> loadRouteDetails() async {
    try {
      final result = await ApiService.getBusRoute(widget.busId);

      if (!mounted) return;

      if (result['success'] == true) {
        final stops = result['stops'] as List<dynamic>;

        setState(() {
          routeData = result;
          isLoading = false;

          if (stops.length >= 2) {
            selectedSourceStopId = (stops[0]['stop_id'] as num).toInt();
            selectedDestinationStopId = (stops[1]['stop_id'] as num).toInt();
          }
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Route not found';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load route details';
        isLoading = false;
      });
    }
  }

  // =========================================================
  // GET SELECTED STOP NAME
  // =========================================================

  String getStopName(int stopId) {
    if (routeData == null) {
      return 'Unknown';
    }

    final stops = routeData!['stops'] as List<dynamic>;

    for (final stop in stops) {
      final id = (stop['stop_id'] as num).toInt();

      if (id == stopId) {
        return stop['stop_name'].toString();
      }
    }

    return 'Unknown';
  }

  // =========================================================
  // OPEN SMART RECOMMENDATION
  // =========================================================

  void openRecommendation() {
    if (selectedSourceStopId == null || selectedDestinationStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select source and destination'),
        ),
      );
      return;
    }

    if (selectedSourceStopId == selectedDestinationStopId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination cannot be the same'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationScreen(
          sourceStopId: selectedSourceStopId!,
          destinationStopId: selectedDestinationStopId!,
        ),
      ),
    );
  }

  // =========================================================
  // OPEN LIVE TRACKING
  // =========================================================

  void openLiveTracking() {
    if (selectedSourceStopId == null || selectedDestinationStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select source and destination'),
        ),
      );
      return;
    }

    if (selectedSourceStopId == selectedDestinationStopId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination cannot be the same'),
        ),
      );
      return;
    }

    final routeId = (routeData!['route_id'] as num).toInt();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingScreen(
          busId: widget.busId,
          routeId: routeId,
          sourceStopId: selectedSourceStopId!,
          destinationStopId: selectedDestinationStopId!,
          busNumber: routeData!['bus_number'].toString(),
          sourceName: getStopName(selectedSourceStopId!),
          destinationName: getStopName(selectedDestinationStopId!),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : routeData == null
                    ? const Center(
                        child: Text('Route details not available'),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BUS NAME
                            Text(
                              widget.busName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ROUTE SOURCE
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.location_on),
                                title: const Text('Route Source'),
                                subtitle: Text(
                                  routeData!['source'].toString(),
                                ),
                              ),
                            ),

                            // ROUTE DESTINATION
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.flag),
                                title: const Text('Route Destination'),
                                subtitle: Text(
                                  routeData!['destination'].toString(),
                                ),
                              ),
                            ),

                            // ETA
                            const Card(
                              child: ListTile(
                                leading: Icon(Icons.access_time),
                                title: Text('ETA'),
                                subtitle: Text(
                                  'Available from ETA Prediction',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // SELECT JOURNEY
                            const Text(
                              'Select Journey',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // SOURCE DROPDOWN
                            DropdownButtonFormField<int>(
                              value: selectedSourceStopId,
                              decoration: const InputDecoration(
                                labelText: 'Select Source',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.trip_origin),
                              ),
                              items: (routeData!['stops'] as List<dynamic>)
                                  .map<DropdownMenuItem<int>>((stop) {
                                return DropdownMenuItem<int>(
                                  value: (stop['stop_id'] as num).toInt(),
                                  child: Text(
                                    stop['stop_name'].toString(),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSourceStopId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 15),

                            // DESTINATION DROPDOWN
                            DropdownButtonFormField<int>(
                              value: selectedDestinationStopId,
                              decoration: const InputDecoration(
                                labelText: 'Select Destination',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              items: (routeData!['stops'] as List<dynamic>)
                                  .map<DropdownMenuItem<int>>((stop) {
                                return DropdownMenuItem<int>(
                                  value: (stop['stop_id'] as num).toInt(),
                                  child: Text(
                                    stop['stop_name'].toString(),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDestinationStopId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 15),

                            // TRACK BUS LIVE
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: openLiveTracking,
                                icon: const Icon(Icons.location_on),
                                label: const Text('Track Bus Live'),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // SMART RECOMMENDATION
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: openRecommendation,
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Get Smart Recommendation'),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ROUTE STOPS TITLE
                            const Text(
                              'Route Stops',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ROUTE STOPS LIST
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  (routeData!['stops'] as List<dynamic>).length,
                              itemBuilder: (context, index) {
                                final stop =
                                    (routeData!['stops'] as List<dynamic>)[index];

                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 14,
                                    child: Text(
                                      '${stop['stop_order']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  title: Text(
                                    stop['stop_name'].toString(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}