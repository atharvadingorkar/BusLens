
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/api_service.dart';

class NearbyStopsScreen extends StatefulWidget {
  const NearbyStopsScreen({super.key});

  @override
  State<NearbyStopsScreen> createState() =>
      _NearbyStopsScreenState();
}

class _NearbyStopsScreenState
    extends State<NearbyStopsScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<dynamic> nearbyStops = [];

  @override
  void initState() {
    super.initState();
    loadNearbyStops();
  }

  Future<void> loadNearbyStops() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      nearbyStops = [];
    });

    try {
      // 1. Check whether location service is enabled.
      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location service is disabled. '
              'Please enable location.',
        );
      }

      // 2. Check location permission.
      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied.',
        );
      }

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
              'Please enable it from app settings.',
        );
      }

      // 3. Get the passenger's current GPS location.
      final Position position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 0,
        ),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException(
            'Unable to get your current location. '
                'Please check GPS settings and try again.',
          );
        },
      );

      // 4. Load stops from FastAPI with a timeout.
      final List<dynamic> stops =
      await ApiService.getStops().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Stops API request timed out.',
          );
        },
      );

      // 5. Calculate distance to every stop.
      final List<Map<String, dynamic>> calculatedStops =
      [];

      for (final stop in stops) {
        final double latitude =
        (stop['latitude'] as num).toDouble();

        final double longitude =
        (stop['longitude'] as num).toDouble();

        final double distanceInMeters =
        Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          latitude,
          longitude,
        );

        calculatedStops.add({
          'stop_id': stop['stop_id'],
          'stop_name': stop['stop_name'],
          'latitude': latitude,
          'longitude': longitude,
          'distance': distanceInMeters,
        });
      }

      // 6. Sort stops from nearest to farthest.
      calculatedStops.sort(
            (a, b) =>
            (a['distance'] as double).compareTo(
              b['distance'] as double,
            ),
      );

      // 7. Display only the five nearest stops.
      final List<Map<String, dynamic>> nearestStops =
      calculatedStops.length > 5
          ? calculatedStops.sublist(0, 5)
          : calculatedStops;

      if (!mounted) return;

      setState(() {
        nearbyStops = nearestStops;
        isLoading = false;
      });
    } on TimeoutException catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            e.message ??
                'The request timed out. Please try again.';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
        isLoading = false;
      });
    }
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Stops'),
        actions: [
          IconButton(
            onPressed: isLoading
                ? null
                : loadNearbyStops,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Finding nearby stops...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 50,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: loadNearbyStops,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      )
          : nearbyStops.isEmpty
          ? const Center(
        child: Text(
          'No nearby stops found.',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: nearbyStops.length,
        separatorBuilder:
            (context, index) =>
        const Divider(),
        itemBuilder: (context, index) {
          final stop = nearbyStops[index];

          return ListTile(
            leading: const Icon(
              Icons.location_on,
            ),
            title: Text(
              stop['stop_name'].toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              formatDistance(
                (stop['distance'] as num)
                    .toDouble(),
              ),
            ),
          );
        },
      ),
    );
  }
}