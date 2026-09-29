
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddStopScreen extends StatefulWidget {
  const AddStopScreen({super.key});

  @override
  State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController stopNameController =
  TextEditingController();

  final TextEditingController latitudeController =
  TextEditingController();

  final TextEditingController longitudeController =
  TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    stopNameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> addNewStop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.addStop(
        stopName: stopNameController.text.trim(),
        latitude: double.parse(
          latitudeController.text.trim(),
        ),
        longitude: double.parse(
          longitudeController.text.trim(),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Bus stop added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
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

  String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  String? validateCoordinate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final coordinate = double.tryParse(value.trim());

    if (coordinate == null) {
      return 'Enter a valid number';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Bus Stop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.location_on,
                size: 70,
                color: Colors.blue,
              ),

              const SizedBox(height: 20),

              const Text(
                'Enter Bus Stop Details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: stopNameController,
                decoration: const InputDecoration(
                  labelText: 'Stop Name',
                  hintText: 'e.g. Kopar Khairane',
                  prefixIcon: Icon(Icons.place),
                  border: OutlineInputBorder(),
                ),
                validator: validateRequired,
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: latitudeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g. 19.1036',
                  prefixIcon: Icon(Icons.location_searching),
                  border: OutlineInputBorder(),
                ),
                validator: validateCoordinate,
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: longitudeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g. 73.0097',
                  prefixIcon: Icon(Icons.location_searching),
                  border: OutlineInputBorder(),
                ),
                validator: validateCoordinate,
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: isLoading ? null : addNewStop,
                icon: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  isLoading ? 'Saving...' : 'Save Stop',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
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