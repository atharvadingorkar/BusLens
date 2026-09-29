import 'package:flutter/material.dart';
import 'ticket_booking_screen.dart';
import '../../services/api_service.dart';

class RecommendationScreen extends StatefulWidget {
  final int sourceStopId;
  final int destinationStopId;

  const RecommendationScreen({
    super.key,
    required this.sourceStopId,
    required this.destinationStopId,
  });

  @override
  State<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState
    extends State<RecommendationScreen> {

  bool isLoading = true;
  String? errorMessage;

  String recommendedBus = 'Loading...';
  String predictedEta = 'Loading...';
  String recommendationReason = 'Loading...';

  bool directRouteAvailable = false;

  int? recommendedBusId;

  @override
  void initState() {
    super.initState();
    loadRecommendation();
  }

  Future<void> loadRecommendation() async {
    try {
      final data = await ApiService.recommendBus(
        sourceStopId: widget.sourceStopId,
        destinationStopId: widget.destinationStopId,
      );

      if (!mounted) return;

      if (data['success'] == true &&
          data['recommended_bus'] != null) {

        final bus = data['recommended_bus'];

        setState(() {
          recommendedBus =
          'Bus ${bus['bus_number']}';

          recommendedBusId =
              (bus['bus_id'] as num).toInt();

          predictedEta =
          '${bus['predicted_eta_minutes']} minutes';

          recommendationReason =
              bus['reason'] ??
                  'Fastest estimated arrival';

          directRouteAvailable = true;

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;

          errorMessage =
              data['message'] ??
                  'No recommended bus found';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage =
        'Unable to load recommendation';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Recommendation'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )

            : errorMessage != null
            ? Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        )

            : Column(
          children: [

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius:
                BorderRadius.circular(12),
              ),

              child: Column(
                children: [

                  const Text(
                    'Recommended Bus',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    recommendedBus,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle,
                ),

                title: const Text(
                  'Fastest Arrival',
                ),

                subtitle: Text(
                  'Estimated arrival: '
                      '$predictedEta',
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle,
                ),

                title: const Text(
                  'Least Waiting Time',
                ),

                subtitle: Text(
                  recommendationReason,
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle,
                ),

                title: Text(
                  directRouteAvailable
                      ? 'Direct Route Available'
                      : 'Direct Route Not Available',
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(

                onPressed:
                recommendedBusId == null
                    ? null
                    : () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) =>
                          TicketBookingScreen(
                            busId:
                            recommendedBusId!,

                            sourceStopId:
                            widget.sourceStopId,

                            destinationStopId:
                            widget.destinationStopId,
                          ),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.confirmation_number,
                ),

                label: const Text(
                  'Book Ticket',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}