
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_bus_screen.dart';

class ManageBusesScreen extends StatefulWidget {
  const ManageBusesScreen({super.key});

  @override
  State<ManageBusesScreen> createState() => _ManageBusesScreenState();
}

class _ManageBusesScreenState extends State<ManageBusesScreen> {
  List<dynamic> buses = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadBuses();
  }

  Future<void> loadBuses() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await ApiService.getBuses();

      if (!mounted) return;

      setState(() {
        buses = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load buses';
      });
    }
  }

  Future<void> showChangeBusStatusDialog(
      Map<String, dynamic> bus,
      ) async {
    final int busId = bus['bus_id'];

    final String currentStatus =
    (bus['status'] ?? 'inactive').toString().toLowerCase();

    final bool isActive = currentStatus == 'active';

    final String newStatus = isActive ? 'inactive' : 'active';

    final String busNumber =
    (bus['bus_number'] ?? 'Unknown').toString();

    final String actionText = isActive ? 'Deactivate' : 'Activate';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Bus Status'),
          content: Text(
            'Do you want to change Bus $busNumber '
                'from ${currentStatus.toUpperCase()} '
                'to ${newStatus.toUpperCase()}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(actionText),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await updateBusStatus(busId, newStatus);
    }
  }

  Future<void> updateBusStatus(
      int busId,
      String newStatus,
      ) async {
    try {
      final result = await ApiService.updateBusStatus(
        busId: busId,
        status: newStatus,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'Bus status updated successfully',
            ),
          ),
        );

        await loadBuses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'Unable to update bus status',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update bus status',
          ),
        ),
      );
    }
  }

  Widget buildStatusChip(String status) {
    final bool isActive = status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.shade100
            : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isActive
              ? Colors.green.shade800
              : Colors.red.shade800,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Buses'),
        actions: [
          IconButton(
            onPressed: loadBuses,
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
              onPressed: loadBuses,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : buses.isEmpty
          ? const Center(
        child: Text('No buses found'),
      )
          : RefreshIndicator(
        onRefresh: loadBuses,
        child: ListView.builder(
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final bus = Map<String, dynamic>.from(
              buses[index],
            );

            final String busNumber =
            (bus['bus_number'] ?? 'Unknown')
                .toString();

            final String busName =
            (bus['bus_name'] ?? 'Unknown Route')
                .toString();

            final String capacity =
            (bus['capacity'] ?? 'N/A')
                .toString();

            final String status =
            (bus['status'] ?? 'inactive')
                .toString();

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: InkWell(
                borderRadius:
                BorderRadius.circular(12),
                onTap: () {
                  showChangeBusStatusDialog(bus);
                },
                child: Padding(
                  padding:
                  const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                        Colors.blue.shade100,
                        child: Icon(
                          Icons.directions_bus,
                          color:
                          Colors.blue.shade800,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bus $busNumber',
                              style:
                              const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              busName,
                              style:
                              const TextStyle(
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              'Capacity: $capacity',
                              style:
                              TextStyle(
                                color: Colors
                                    .grey.shade700,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                buildStatusChip(
                                  status,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  'Tap to change',
                                  style: TextStyle(
                                    color: Colors
                                        .grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                    ],
                  ),
                ),
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
              builder: (context) => const AddBusScreen(),
            ),
          );

          await loadBuses();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}