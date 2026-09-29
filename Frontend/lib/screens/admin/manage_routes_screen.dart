
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_route_screen.dart';
import 'add_route_stop_screen.dart';

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() =>
      _ManageRoutesScreenState();
}

class _ManageRoutesScreenState
    extends State<ManageRoutesScreen> {
  List<dynamic> routes = [];

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadRoutes();
  }

  Future<void> loadRoutes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await ApiService.getRoutes();

      if (!mounted) return;

      setState(() {
        routes = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load routes';
      });
    }
  }

  Future<void> changeRouteStatus(
      int routeId,
      String currentStatus,
      ) async {
    final String newStatus =
    currentStatus.toLowerCase() == 'active'
        ? 'inactive'
        : 'active';

    try {
      final result = await ApiService.updateRouteStatus(
        routeId: routeId,
        status: newStatus,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Route status changed to ${newStatus.toUpperCase()}',
            ),
          ),
        );

        await loadRoutes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Unable to update route status',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update route status'),
        ),
      );
    }
  }

  void showStatusDialog(Map<String, dynamic> route) {
    final int routeId = route['route_id'];

    final String routeName =
        route['route_name'] ?? 'Unknown Route';

    final String currentStatus =
    (route['status'] ?? 'active')
        .toString()
        .toLowerCase();

    final bool isActive = currentStatus == 'active';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Route Status'),

          content: Text(
            'Do you want to change the status of "$routeName" '
                'to ${isActive ? 'INACTIVE' : 'ACTIVE'}?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                changeRouteStatus(
                  routeId,
                  currentStatus,
                );
              },
              child: Text(
                isActive ? 'Deactivate' : 'Activate',
              ),
            ),
          ],
        );
      },
    );
  }

  // Display the stops belonging to a selected route
  Future<void> showRouteStopsDialog(
      int routeId,
      String routeName,
      ) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            routeName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: FutureBuilder<List<dynamic>>(
            future: ApiService.getRouteStops(routeId),

            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  'Unable to load bus stops.',
                );
              }

              final stops = snapshot.data ?? [];

              if (stops.isEmpty) {
                return const Text(
                  'No bus stops assigned to this route.',
                );
              }

              return SizedBox(
                width: double.maxFinite,
                height: 350,

                child: ListView.builder(
                  itemCount: stops.length,

                  itemBuilder: (context, index) {
                    final stop = stops[index];

                    final String stopName =
                        stop['stop_name']?.toString() ??
                            'Unknown Stop';

                    final String stopOrder =
                        stop['stop_order']?.toString() ??
                            '${index + 1}';

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(
                          stopOrder,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      title: Text(
                        stopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      subtitle: Text(
                        'Stop order: $stopOrder',
                      ),
                    );
                  },
                ),
              );
            },
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Color getStatusColor(String status) {
    return status.toLowerCase() == 'active'
        ? Colors.green
        : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),

        actions: [
          IconButton(
            tooltip: 'Add Stop to Route',
            icon: const Icon(Icons.add_location_alt),

            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const AddRouteStopScreen(),
                ),
              );
            },
          ),

          IconButton(
            onPressed: loadRoutes,
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
              onPressed: loadRoutes,
              child: const Text('Retry'),
            ),
          ],
        ),
      )

          : routes.isEmpty
          ? const Center(
        child: Text('No routes found'),
      )

          : RefreshIndicator(
        onRefresh: loadRoutes,

        child: ListView.builder(
          itemCount: routes.length,

          itemBuilder: (context, index) {
            final route = routes[index];

            final int routeId =
            int.parse(
              route['route_id'].toString(),
            );

            final String routeName =
                route['route_name'] ??
                    'Unknown Route';

            final String source =
                route['source'] ??
                    'Unknown Source';

            final String destination =
                route['destination'] ??
                    'Unknown Destination';

            final String distance =
                route['distance_km']
                    ?.toString() ??
                    '0';

            final String status =
            (route['status'] ?? 'active')
                .toString();

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),

              child: ListTile(
                contentPadding:
                const EdgeInsets.all(12),

                leading: const Icon(
                  Icons.route,
                  size: 30,
                ),

                title: Text(
                  routeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Padding(
                  padding: const EdgeInsets.only(
                    top: 6,
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      Text(
                        '$source → $destination',
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Distance: $distance km',
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: getStatusColor(
                              status,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            'Status: ${status.toUpperCase()}',
                            style: TextStyle(
                              color:
                              getStatusColor(
                                status,
                              ),
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.blue,
                          ),

                          SizedBox(width: 5),

                          Text(
                            'Tap to view bus stops',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                isThreeLine: true,

                trailing: IconButton(
                  icon: const Icon(
                    Icons.edit,
                  ),

                  onPressed: () {
                    showStatusDialog(route);
                  },
                ),

                onTap: () {
                  showRouteStopsDialog(
                    routeId,
                    routeName,
                  );
                },
              ),
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,

            MaterialPageRoute(
              builder: (context) =>
              const AddRouteScreen(),
            ),
          );

          if (!mounted) return;

          await loadRoutes();
        },

        child: const Icon(Icons.add),
      ),
    );
  }

}