import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EtaPredictionScreen extends StatefulWidget {
  final int busId;
  final int routeId;
  final int sourceStopId;
  final int destinationStopId;

  final String busNumber;
  final String sourceName;
  final String destinationName;

  const EtaPredictionScreen({
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
  State<EtaPredictionScreen> createState() =>
      _EtaPredictionScreenState();
}

class _EtaPredictionScreenState
    extends State<EtaPredictionScreen> {
  double? predictedEta;

  bool isLoading = false;

  String? errorMessage;

  String currentBusStop = 'Not available';

  Future<void> predictETA() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      predictedEta = null;
      currentBusStop = 'Loading...';
    });

    try {
      final result = await ApiService.predictETA(
        busId: widget.busId,
        routeId: widget.routeId,
        sourceStopId: widget.sourceStopId,
        destinationStopId: widget.destinationStopId,
        departureHour: DateTime.now().hour,
        weather: 'clear',
        trafficLevel: 'moderate',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          predictedEta =
              (result['predicted_eta_minutes'] as num)
                  .toDouble();

          currentBusStop =
              result['current_stop']?.toString() ??
                  'Not available';

          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              result['message'] ??
                  'Unable to predict ETA';

          currentBusStop = 'Not available';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
        'Failed to connect to ETA service';

        currentBusStop = 'Not available';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ETA Prediction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // --------------------------------------------------
            // Selected Bus
            // --------------------------------------------------
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.directions_bus,
                ),
                title: const Text(
                  'Bus Number',
                ),
                subtitle: Text(
                  'Bus ${widget.busNumber}',
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // Current Bus Location
            // --------------------------------------------------
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                ),
                title: const Text(
                  'Current Bus Location',
                ),
                subtitle: Text(
                  currentBusStop,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // Passenger Source
            // --------------------------------------------------
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.trip_origin,
                ),
                title: const Text(
                  'From',
                ),
                subtitle: Text(
                  widget.sourceName,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // Passenger Destination
            // --------------------------------------------------
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.flag,
                ),
                title: const Text(
                  'To',
                ),
                subtitle: Text(
                  widget.destinationName,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // ETA Result
            // --------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Column(
                children: [

                  const Text(
                    'Predicted Arrival Time',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    predictedEta != null
                        ? '${predictedEta!.toStringAsFixed(0)} Minutes'
                        : 'Not Predicted',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // Predict Button
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                isLoading ? null : predictETA,
                icon: isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.access_time,
                ),
                label: Text(
                  isLoading
                      ? 'Predicting...'
                      : 'Predict ETA',
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // Error Message
            // --------------------------------------------------
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}