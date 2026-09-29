
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_stop_screen.dart';

class AddRouteStopScreen extends StatefulWidget {
  const AddRouteStopScreen({super.key});

  @override
  State<AddRouteStopScreen> createState() =>
      _AddRouteStopScreenState();
}

class _AddRouteStopScreenState
    extends State<AddRouteStopScreen> {
  List<dynamic> routes = [];
  List<dynamic> stops = [];

  int? selectedRouteId;
  int? selectedStopId;

  final TextEditingController stopOrderController =
  TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    stopOrderController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final routeResult = await ApiService.getRoutes();
      final stopResult = await ApiService.getStops();

      if (!mounted) return;

      setState(() {
        routes = routeResult;
        stops = stopResult;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load routes and stops';
      });
    }
  }

  Future<void> openAddStopScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddStopScreen(),
      ),
    );

    if (result == true) {
      await loadData();

      if (!mounted) return;

      showMessage('Bus stop list updated');
    }
  }

  Future<void> saveRouteStop() async {
    if (selectedRouteId == null) {
      showMessage('Please select a route');
      return;
    }

    if (selectedStopId == null) {
      showMessage('Please select a bus stop');
      return;
    }

    final int? stopOrder =
    int.tryParse(stopOrderController.text.trim());

    if (stopOrder == null || stopOrder <= 0) {
      showMessage('Enter a valid stop order');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final result = await ApiService.addRouteStop(
        routeId: selectedRouteId!,
        stopId: selectedStopId!,
        stopOrder: stopOrder,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'Bus stop added successfully',
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        showMessage(
          result['message'] ??
              'Unable to add bus stop',
        );
      }
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to add bus stop');
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Stop to Route'),
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
            Text(errorMessage),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,

            children: [
              const Text(
                'Select Route',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<int>(
                value: selectedRouteId,

                decoration:
                const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Choose a route',
                ),

                items: routes.map((route) {
                  final int routeId =
                  int.parse(
                    route['route_id'].toString(),
                  );

                  final String routeName =
                      route['route_name']
                          ?.toString() ??
                          'Unknown Route';

                  return DropdownMenuItem<int>(
                    value: routeId,
                    child: Text(routeName),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedRouteId = value;
                  });
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Select Bus Stop',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<int>(
                value: selectedStopId,

                decoration:
                const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Choose a bus stop',
                ),

                items: stops.map((stop) {
                  final int stopId =
                  int.parse(
                    stop['stop_id'].toString(),
                  );

                  final String stopName =
                      stop['stop_name']
                          ?.toString() ??
                          'Unknown Stop';

                  return DropdownMenuItem<int>(
                    value: stopId,
                    child: Text(stopName),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedStopId = value;
                  });
                },
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,

                child: TextButton.icon(
                  onPressed: openAddStopScreen,

                  icon: const Icon(
                    Icons.add_location_alt,
                  ),

                  label: const Text(
                    'Add New Stop',
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Stop Order',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: stopOrderController,

                keyboardType:
                TextInputType.number,

                decoration:
                const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Example: 7',
                  helperText:
                  'Enter the position of this stop on the route',
                ),
              ),

              const SizedBox(height: 35),

              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : saveRouteStop,

                style:
                ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),

                child: isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,

                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Add Stop to Route',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}