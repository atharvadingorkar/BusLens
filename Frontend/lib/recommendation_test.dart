import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const RecommendationTestApp());
}

class RecommendationTestApp extends StatefulWidget {
  const RecommendationTestApp({super.key});

  @override
  State<RecommendationTestApp> createState() =>
      _RecommendationTestAppState();
}

class _RecommendationTestAppState
    extends State<RecommendationTestApp> {

  String result = 'Testing recommendation...';

  @override
  void initState() {
    super.initState();
    testRecommendation();
  }

  Future<void> testRecommendation() async {
    try {
      final data = await ApiService.recommendBus(
        sourceStopId: 2,
        destinationStopId: 5,
      );

      setState(() {
        result = data.toString();
      });
    } catch (e) {
      setState(() {
        result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Recommendation API Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              result,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}