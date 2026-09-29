
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AssignBusScreen extends StatefulWidget {
  const AssignBusScreen({super.key});

  @override
  State<AssignBusScreen> createState() => _AssignBusScreenState();
}

class _AssignBusScreenState extends State<AssignBusScreen> {
  List<dynamic> operators = [];
  List<dynamic> buses = [];

  int? selectedOperatorId;
  int? selectedBusId;

  bool isLoading = true;
  bool isAssigning = false;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Load operators and buses from the backend
  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final operatorResult = await ApiService.getOperators();
      final busResult = await ApiService.getBuses();

      if (!mounted) return;

      setState(() {
        operators = operatorResult;
        buses = busResult;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load operators or buses';
      });
    }
  }

  // Assign selected bus to selected operator
  Future<void> assignBus() async {
    if (selectedOperatorId == null || selectedBusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an operator and a bus',
          ),
        ),
      );

      return;
    }

    setState(() {
      isAssigning = true;
    });

    try {
      final result = await ApiService.assignBusToOperator(
        operatorId: selectedOperatorId!,
        busId: selectedBusId!,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Bus assigned successfully',
            ),
          ),
        );

        setState(() {
          selectedOperatorId = null;
          selectedBusId = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to assign bus',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to assign bus'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isAssigning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Bus'),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
            ),

            const SizedBox(height: 15),

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

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,

          children: [
            // Select Operator
            const Text(
              'Select Operator',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              value: selectedOperatorId,

              isExpanded: true,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose an operator',
              ),

              items: operators.map((operator) {
                final int userId =
                operator['user_id'];

                final String fullName =
                    operator['full_name'] ??
                        'Unknown Operator';

                return DropdownMenuItem<int>(
                  value: userId,

                  child: SizedBox(
                    width: 220,

                    child: Text(
                      fullName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedOperatorId = value;
                });
              },
            ),

            const SizedBox(height: 25),

            // Select Bus
            const Text(
              'Select Bus',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              value: selectedBusId,

              isExpanded: true,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a bus',
              ),

              items: buses.map((bus) {
                final int busId =
                bus['bus_id'];

                final String busNumber =
                    bus['bus_number'] ?? '';

                final String busName =
                    bus['bus_name'] ??
                        'Unknown Bus';

                return DropdownMenuItem<int>(
                  value: busId,

                  child: SizedBox(
                    width: 220,

                    child: Text(
                      'Bus $busNumber - $busName',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedBusId = value;
                });
              },
            ),

            const SizedBox(height: 35),

            // Assign Bus Button
            SizedBox(
              height: 50,

              child: ElevatedButton(
                onPressed:
                isAssigning ? null : assignBus,

                child: isAssigning
                    ? const SizedBox(
                  height: 24,
                  width: 24,

                  child:
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Assign Bus',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}