import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final TextEditingController routeNameController =
  TextEditingController();

  final TextEditingController sourceController =
  TextEditingController();

  final TextEditingController destinationController =
  TextEditingController();

  final TextEditingController distanceController =
  TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    routeNameController.dispose();
    sourceController.dispose();
    destinationController.dispose();
    distanceController.dispose();
    super.dispose();
  }

  Future<void> saveRoute() async {
    final routeName = routeNameController.text.trim();
    final source = sourceController.text.trim();
    final destination = destinationController.text.trim();
    final distanceText = distanceController.text.trim();

    if (routeName.isEmpty ||
        source.isEmpty ||
        destination.isEmpty ||
        distanceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    final distance = double.tryParse(distanceText);

    if (distance == null || distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid distance'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.addRoute(
        routeName: routeName,
        source: source,
        destination: destination,
        distanceKm: distance,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route added successfully'),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to add route',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to connect to server'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Route'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: routeNameController,
              decoration: const InputDecoration(
                labelText: 'Route Name',
                hintText:
                'Example: Kalyan Parking to Durgadi Chowk',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                hintText: 'Example: Kalyan Parking',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'Example: Durgadi Chowk',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: distanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Distance (km)',
                hintText: 'Example: 6.5',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveRoute,
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Save Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}