import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddBusScreen extends StatefulWidget {
  const AddBusScreen({super.key});

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final TextEditingController busController =
  TextEditingController();

  final TextEditingController routeController =
  TextEditingController();

  final TextEditingController capacityController =
  TextEditingController(text: '40');

  bool isLoading = false;

  @override
  void dispose() {
    busController.dispose();
    routeController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  Future<void> saveBus() async {
    final busNumber = busController.text.trim();
    final routeName = routeController.text.trim();
    final capacityText = capacityController.text.trim();

    if (busNumber.isEmpty ||
        routeName.isEmpty ||
        capacityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    final capacity = int.tryParse(capacityText);

    if (capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid capacity'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.addBus(
        busNumber: busNumber,
        busName: routeName,
        capacity: capacity,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bus added successfully'),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to add bus',
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
        title: const Text('Add Bus'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: busController,
              decoration: const InputDecoration(
                labelText: 'Bus Number',
                hintText: 'Example: 505',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: routeController,
              decoration: const InputDecoration(
                labelText: 'Route',
                hintText:
                'Example: Kalyan Parking to Ganesh Ghat Depot',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacity',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveBus,
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Save Bus'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}