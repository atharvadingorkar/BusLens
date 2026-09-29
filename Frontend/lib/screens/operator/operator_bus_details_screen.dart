
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/api_service.dart';

class OperatorBusDetailsScreen extends StatefulWidget {
  final String busName;

  // Actual database bus ID
  final int? busId;

  // Optional route information
  final int? routeId;
  final String? routeName;

  const OperatorBusDetailsScreen({
    super.key,
    required this.busName,
    this.busId,
    this.routeId,
    this.routeName,
  });

  @override
  State<OperatorBusDetailsScreen> createState() =>
      _OperatorBusDetailsScreenState();
}

class _OperatorBusDetailsScreenState
    extends State<OperatorBusDetailsScreen> {
  bool tripStarted = false;
  bool isLoading = false;
  bool isLoadingRoutes = true;

  String currentLocation = 'Not Available';
  String message = '';

  List<dynamic> routes = [];

  int? selectedRouteId;
  String? selectedRouteName;

  // GPS tracking timer
  Timer? locationTimer;

  @override
  void initState() {
    super.initState();

    // Preserve route information if it was already passed
    selectedRouteId = widget.routeId;
    selectedRouteName = widget.routeName;

    loadRoutes();
  }

  // Load routes from the backend
  Future<void> loadRoutes() async {
    try {
      final result = await ApiService.getRoutes();

      if (!mounted) return;

      setState(() {
        routes = result;
        isLoadingRoutes = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingRoutes = false;
        message = 'Unable to load routes';
      });
    }
  }

  // Start trip using the selected bus and route
  Future<void> startTrip() async {
    if (widget.busId == null) {
      setState(() {
        message = 'Bus information is not available';
      });

      return;
    }

    if (selectedRouteId == null) {
      setState(() {
        message = 'Please select a route first';
      });

      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await ApiService.startTrip(
        busId: widget.busId!,
        routeId: selectedRouteId!,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          tripStarted = true;
          currentLocation = 'Starting GPS tracking...';
          message = 'Trip started successfully';
        });

        // Start automatic GPS tracking
        startLocationTracking();
      } else {
        setState(() {
          message = result['message'] ?? 'Failed to start trip';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = 'Unable to connect to server';
      });
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // Check GPS permissions
  Future<bool> checkLocationPermission() async {
    final bool serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          message = 'Please enable location services';
        });
      }

      return false;
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        setState(() {
          message = 'Location permission was denied';
        });
      }

      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          message =
          'Location permission is permanently denied. '
              'Please enable it from app settings';
        });
      }

      return false;
    }

    return true;
  }

  // Get current GPS location and send it to FastAPI

  Future<void> updateCurrentBusLocation() async {
    if (widget.busId == null || !tripStarted) {
      debugPrint('GPS skipped: trip is not running');
      return;
    }

    try {
      if (mounted) {
        setState(() {
          currentLocation = 'Checking GPS permission...';
        });
      }

      debugPrint('GPS: Checking location permission');

      final bool permissionGranted =
      await checkLocationPermission();

      if (!permissionGranted) {
        debugPrint('GPS: Permission not granted');
        return;
      }

      if (mounted) {
        setState(() {
          currentLocation = 'Getting current GPS location...';
        });
      }

      debugPrint('GPS: Requesting current position');

      final Position position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 0,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'GPS location timed out. '
                'Check emulator location settings.',
          );
        },
      );

      debugPrint(
        'GPS received: '
            '${position.latitude}, ${position.longitude}',
      );

      if (mounted) {
        setState(() {
          currentLocation = 'Sending location to server...';
        });
      }

      final result =
      await ApiService.updateBusLocation(
        busId: widget.busId!,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
      ).timeout(
        const Duration(seconds: 10),
      );

      debugPrint(
        'Location API response: $result',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          currentLocation =
          '${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}';
        });
      } else {
        setState(() {
          currentLocation =
          'Server rejected GPS location';
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('GPS timeout: $e');

      if (!mounted) return;

      setState(() {
        currentLocation =
        'GPS timeout. Check emulator location.';
      });
    } catch (e) {
      debugPrint('GPS error: $e');

      if (!mounted) return;

      setState(() {
        currentLocation =
        'GPS error: ${e.toString()}';
      });
    }
  }
  // Start automatic GPS tracking
  void startLocationTracking() {
    locationTimer?.cancel();

    // Send the first location immediately
    updateCurrentBusLocation();

    // Send location every 10 seconds
    locationTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) {
        if (tripStarted) {
          updateCurrentBusLocation();
        }
      },
    );
  }

  // Stop automatic GPS tracking
  void stopLocationTracking() {
    locationTimer?.cancel();
    locationTimer = null;
  }

  // End trip using the backend
  Future<void> endTrip() async {
    if (widget.busId == null) {
      setState(() {
        message = 'Bus information is not available';
      });

      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await ApiService.endTrip(
        busId: widget.busId!,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Stop GPS tracking after the trip ends
        stopLocationTracking();

        setState(() {
          tripStarted = false;
          currentLocation = 'Not Available';
          message = 'Trip ended successfully';
        });
      } else {
        setState(() {
          message = result['message'] ?? 'Failed to end trip';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = 'Unable to connect to server';
      });
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    // Stop the timer when leaving the screen
    stopLocationTracking();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.busName),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // Bus information
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.directions_bus,
                ),

                title: const Text('Bus'),

                subtitle: Text(
                  widget.busName,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Route selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    const Row(
                      children: [
                        Icon(Icons.route),

                        SizedBox(width: 10),

                        Text(
                          'Select Route',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (isLoadingRoutes)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),

                          child:
                          CircularProgressIndicator(),
                        ),
                      )

                    else if (routes.isEmpty)
                      const Text(
                        'No routes available',

                        style: TextStyle(
                          color: Colors.red,
                        ),
                      )

                    else
                      DropdownButtonFormField<int>(
                        value: routes.any(
                              (route) =>
                          route['route_id'] ==
                              selectedRouteId,
                        )
                            ? selectedRouteId
                            : null,

                        decoration:
                        const InputDecoration(
                          labelText: 'Choose Route',
                          border:
                          OutlineInputBorder(),
                        ),

                        isExpanded: true,

                        items: routes
                            .map<DropdownMenuItem<int>>(
                              (route) {
                            final int routeId =
                            route['route_id'] as int;

                            final String routeName =
                                route['route_name'] ??
                                    '${route['source']} → '
                                        '${route['destination']}';

                            return DropdownMenuItem<int>(
                              value: routeId,

                              child: Text(
                                routeName,
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ).toList(),

                        onChanged: tripStarted
                            ? null
                            : (value) {
                          if (value == null) {
                            return;
                          }

                          final selectedRoute =
                          routes.firstWhere(
                                (route) =>
                            route['route_id'] ==
                                value,
                          );

                          setState(() {
                            selectedRouteId = value;

                            selectedRouteName =
                                selectedRoute[
                                'route_name'] ??
                                    '${selectedRoute['source']} → '
                                        '${selectedRoute['destination']}';

                            message = '';
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Selected route information
            Card(
              child: ListTile(
                leading: const Icon(Icons.map),

                title: const Text('Selected Route'),

                subtitle: Text(
                  selectedRouteName ??
                      'No route selected',
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Trip status
            Card(
              child: ListTile(
                leading: const Icon(Icons.info),

                title: const Text('Status'),

                subtitle: Text(
                  tripStarted
                      ? 'Trip Running'
                      : 'Trip Not Started',
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Current location
            Card(
              child: ListTile(
                leading:
                const Icon(Icons.location_on),

                title: const Text('Current Location'),

                subtitle: Text(
                  currentLocation,
                ),
              ),
            ),

            // Message
            if (message.isNotEmpty) ...[
              const SizedBox(height: 15),

              Text(
                message,

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: message.contains(
                    'successfully',
                  )
                      ? Colors.green
                      : Colors.red,

                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Start trip button
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed: tripStarted ||
                    isLoading ||
                    selectedRouteId == null
                    ? null
                    : startTrip,

                icon: isLoading && !tripStarted
                    ? const SizedBox(
                  width: 20,
                  height: 20,

                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )

                    : const Icon(
                  Icons.play_arrow,
                ),

                label: Text(
                  isLoading && !tripStarted
                      ? 'Starting Trip...'
                      : 'Start Trip',
                ),
              ),
            ),

            const SizedBox(height: 15),

            // End trip button
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed:
                widget.busId != null && !isLoading
                    ? endTrip
                    : null,

                icon: isLoading && tripStarted
                    ? const SizedBox(
                  width: 20,
                  height: 20,

                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )

                    : const Icon(
                  Icons.stop,
                ),

                label: Text(
                  isLoading && tripStarted
                      ? 'Ending Trip...'
                      : 'End Trip',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}