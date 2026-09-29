
import 'package:flutter/material.dart';
import 'route_details_screen.dart';
import '../../services/api_service.dart';

class SearchBusScreen extends StatefulWidget {
  const SearchBusScreen({super.key});

  @override
  State<SearchBusScreen> createState() => _SearchBusScreenState();
}

class _SearchBusScreenState extends State<SearchBusScreen> {
  final TextEditingController searchController =
  TextEditingController();

  List<dynamic> buses = [];
  List<dynamic> filteredBuses = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadBuses();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadBuses() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getBuses();

      if (!mounted) return;

      setState(() {
        buses = result;
        filteredBuses = result;
        isLoading = false;
      });

      searchBus(searchController.text);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load buses';
      });
    }
  }

  void searchBus(String query) {
    final searchText = query.trim().toLowerCase();

    setState(() {
      filteredBuses = buses.where((bus) {
        final busNumber =
            bus['bus_number']?.toString().toLowerCase() ?? '';

        final busName =
            bus['bus_name']?.toString().toLowerCase() ?? '';

        return busNumber.contains(searchText) ||
            busName.contains(searchText);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Bus'),

        actions: [
          IconButton(
            onPressed: isLoading ? null : loadBuses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh buses',
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: searchBus,

              decoration: const InputDecoration(
                hintText: 'Search by Bus Number or Route',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: loadBuses,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
                  : filteredBuses.isEmpty
                  ? const Center(
                child: Text(
                  'No buses found',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: filteredBuses.length,

                itemBuilder: (context, index) {
                  final bus =
                  filteredBuses[index];

                  final busNumber =
                      bus['bus_number']
                          ?.toString() ??
                          'Unknown';

                  final busName =
                      bus['bus_name']
                          ?.toString() ??
                          'Unknown Bus';

                  final busId =
                  int.tryParse(
                    bus['bus_id'].toString(),
                  );

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.directions_bus,
                        color: Colors.blue,
                      ),

                      title: Text(
                        'Bus $busNumber',
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(busName),

                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                      ),

                      onTap: busId == null
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                RouteDetailsScreen(
                                  busName:
                                  'Bus $busNumber - $busName',
                                  busId: busId,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}