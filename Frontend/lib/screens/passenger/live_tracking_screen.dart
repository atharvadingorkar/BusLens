import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'eta_prediction_screen.dart';
import '../../services/api_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final int busId;
  final int routeId;
  final int sourceStopId;
  final int destinationStopId;

  final String busNumber;
  final String sourceName;
  final String destinationName;

  const LiveTrackingScreen({
    super.key,
    required this.busId,
    required this.routeId,
    required this.sourceStopId,
    required this.destinationStopId,
    required this.busNumber,
    required this.sourceName,
    required this.destinationName,
  });

  @override
  State<LiveTrackingScreen> createState() =>
      _LiveTrackingScreenState();
}

class _LiveTrackingScreenState
    extends State<LiveTrackingScreen> {
  Map<String, dynamic>? locationData;
  Map<String, dynamic>? routeData;

  bool isLoading = true;
  String? errorMessage;

  WebSocketChannel? channel;

  // Map controller
  final MapController mapController = MapController();

  // Bus stop markers
  List<Marker> stopMarkers = [];

  @override
  void initState() {
    super.initState();

    // Load current bus location
    loadBusLocation();

    // Load bus route and stops
    loadBusRoute();

    // Connect to WebSocket for live location
    connectWebSocket();
  }

  // =========================================================
  // LOAD BUS LOCATION
  // =========================================================

  Future<void> loadBusLocation() async {
    try {
      final result =
      await ApiService.getBusLocation(widget.busId);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          locationData = result;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              result['message'] ??
                  'Bus location not found';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
        'Unable to load bus location';
        isLoading = false;
      });
    }
  }

  // =========================================================
  // LOAD BUS ROUTE AND STOPS
  // =========================================================

  Future<void> loadBusRoute() async {
    try {
      final result =
      await ApiService.getBusRoute(widget.busId);

      if (!mounted) return;

      if (result['success'] == true) {
        final stops =
        result['stops'] as List<dynamic>;

        final List<Marker> markers = [];

        for (final stop in stops) {
          final latitude =
          double.parse(
            stop['latitude'].toString(),
          );

          final longitude =
          double.parse(
            stop['longitude'].toString(),
          );

          markers.add(
            Marker(
              point: LatLng(
                latitude,
                longitude,
              ),
              width: 35,
              height: 35,
              child: const Icon(
                Icons.location_on,
                size: 30,
                color: Colors.red,
              ),
            ),
          );
        }

        setState(() {
          routeData = result;
          stopMarkers = markers;
        });
      }
    } catch (e) {
      debugPrint(
        'Unable to load bus route: $e',
      );
    }
  }

  // =========================================================
  // WEBSOCKET LIVE LOCATION
  // =========================================================

  void connectWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse(
          'wss://buslens-api.onrender.com/ws/live-location',
        ),
      );

      channel!.stream.listen(
            (message) {
          try {
            final data =
            jsonDecode(message);

            if (data['success'] == true &&
                data['bus_id'] ==
                    widget.busId) {
              if (!mounted) return;

              // New GPS coordinates
              final newLat =
              double.parse(
                data['latitude'].toString(),
              );

              final newLng =
              double.parse(
                data['longitude'].toString(),
              );

              // Update location information
              setState(() {
                locationData = {
                  'success': true,
                  'bus_id': data['bus_id'],
                  'latitude': data['latitude'],
                  'longitude': data['longitude'],
                  'updated_at': data['timestamp'],
                };
              });

              // Move map to new bus location
              mapController.move(
                LatLng(
                  newLat,
                  newLng,
                ),
                mapController.camera.zoom,
              );
            }
          } catch (e) {
            debugPrint(
              'WebSocket message error: $e',
            );
          }
        },
        onError: (error) {
          debugPrint(
            'WebSocket error: $error',
          );
        },
        onDone: () {
          debugPrint(
            'WebSocket connection closed',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'WebSocket connection failed: $e',
      );
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Bus Tracking',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
          child:
          CircularProgressIndicator(),
        )
            : errorMessage != null
            ? Center(
          child: Text(
            errorMessage!,
            style:
            const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          ),
        )
            : locationData == null
            ? const Center(
          child: Text(
            'Location not available',
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [

              // =================================================
              // MAP
              // =================================================

              SizedBox(
                height: 250,
                width:
                double.infinity,
                child: ClipRRect(
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                  child:
                  FlutterMap(
                    mapController:
                    mapController,
                    options:
                    MapOptions(
                      initialCenter:
                      LatLng(
                        double.parse(
                          locationData![
                          'latitude']
                              .toString(),
                        ),
                        double.parse(
                          locationData![
                          'longitude']
                              .toString(),
                        ),
                      ),
                      initialZoom:
                      14,
                    ),
                    children: [

                      // =================================================
                      // OPEN STREET MAP
                      // =================================================

                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                        'com.example.buslens',
                      ),

                      // =================================================
                      // BUS + STOP MARKERS
                      // =================================================

                      MarkerLayer(
                        markers: [

                          // -------------------------------
                          // BUS MARKER
                          // -------------------------------

                          Marker(
                            point:
                            LatLng(
                              double.parse(
                                locationData![
                                'latitude']
                                    .toString(),
                              ),
                              double.parse(
                                locationData![
                                'longitude']
                                    .toString(),
                              ),
                            ),
                            width: 50,
                            height: 50,
                            child:
                            const Icon(
                              Icons
                                  .directions_bus,
                              size: 40,
                              color:
                              Colors.blue,
                            ),
                          ),

                          // -------------------------------
                          // BUS STOP MARKERS
                          // -------------------------------

                          ...stopMarkers,
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // BUS NUMBER
              // =================================================

              Card(
                child: ListTile(
                  leading:
                  const Icon(
                    Icons
                        .directions_bus,
                  ),
                  title:
                  const Text(
                    'Bus Number',
                  ),
                  subtitle:
                  Text(
                    'Bus ${widget.busNumber}',
                  ),
                ),
              ),

              // =================================================
              // CURRENT LOCATION
              // =================================================

              Card(
                child: ListTile(
                  leading:
                  const Icon(
                    Icons
                        .location_on,
                  ),
                  title:
                  const Text(
                    'Current Location',
                  ),
                  subtitle:
                  Text(
                    'Latitude: '
                        '${locationData!['latitude']}\n'
                        'Longitude: '
                        '${locationData!['longitude']}',
                  ),
                ),
              ),

              // =================================================
              // LAST UPDATED
              // =================================================

              Card(
                child: ListTile(
                  leading:
                  const Icon(
                    Icons
                        .access_time,
                  ),
                  title:
                  const Text(
                    'Last Updated',
                  ),
                  subtitle:
                  Text(
                    locationData![
                    'updated_at']
                        .toString(),
                  ),
                ),
              ),

              // =================================================
              // BUS STATUS
              // =================================================

              const Card(
                child: ListTile(
                  leading:
                  Icon(
                    Icons.speed,
                  ),
                  title:
                  Text(
                    'Bus Status',
                  ),
                  subtitle:
                  Text(
                    'Location Available',
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // SELECTED JOURNEY
              // =================================================

              Card(
                child: ListTile(
                  leading:
                  const Icon(
                    Icons
                        .route,
                  ),
                  title:
                  const Text(
                    'Your Journey',
                  ),
                  subtitle:
                  Text(
                    '${widget.sourceName} → '
                        '${widget.destinationName}',
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // =================================================
              // ETA BUTTON
              // =================================================

              SizedBox(
                width:
                double.infinity,
                child:
                ElevatedButton
                    .icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                            EtaPredictionScreen(
                              busId:
                              widget
                                  .busId,
                              routeId:
                              widget
                                  .routeId,
                              sourceStopId:
                              widget
                                  .sourceStopId,
                              destinationStopId:
                              widget
                                  .destinationStopId,
                              busNumber:
                              widget
                                  .busNumber,
                              sourceName:
                              widget
                                  .sourceName,
                              destinationName:
                              widget
                                  .destinationName,
                            ),
                      ),
                    );
                  },
                  icon:
                  const Icon(
                    Icons
                        .access_time,
                  ),
                  label:
                  const Text(
                    'View ETA Prediction',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}