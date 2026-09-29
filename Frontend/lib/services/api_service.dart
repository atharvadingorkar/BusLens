import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://buslens-api.onrender.com';

  // --------------------------------------------------
  // LOGIN
  // --------------------------------------------------

  static Future<Map<String, dynamic>> login(
      String email,
      String password,
      String role,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    return jsonDecode(response.body);
  }

  // --------------------------------------------------
  // GET BUSES
  // --------------------------------------------------

  static Future<List<dynamic>> getBuses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/buses'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['buses'];
    } else {
      throw Exception('Failed to load buses');
    }
  }

  static Future<List<dynamic>> getRoutes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/routes'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['routes'] ?? [];
    } else {
      throw Exception('Failed to load routes');
    }
  }

  // --------------------------------------------------
  // REGISTER
  // --------------------------------------------------

  static Future<Map<String, dynamic>> register(
      String fullName,
      String email,
      String phone,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  // --------------------------------------------------
  // GET BUS ROUTE
  // --------------------------------------------------

  static Future<Map<String, dynamic>> getBusRoute(
      int busId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bus/$busId/route'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load bus route');
    }
  }

  // --------------------------------------------------
  // GET BUS LOCATION
  // --------------------------------------------------

  static Future<Map<String, dynamic>> getBusLocation(
      int busId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bus/$busId/location'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load bus location');
    }
  }

  // --------------------------------------------------
  // ETA PREDICTION
  // --------------------------------------------------

  static Future<Map<String, dynamic>> predictETA({
    required int busId,
    required int routeId,
    required int sourceStopId,
    required int destinationStopId,
    required int departureHour,
    required String weather,
    required String trafficLevel,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict-eta'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bus_id': busId,
        'route_id': routeId,
        'source_stop_id': sourceStopId,
        'destination_stop_id': destinationStopId,
        'departure_hour': departureHour,
        'weather': weather,
        'traffic_level': trafficLevel,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to predict ETA',
      );
    }
  }

  // --------------------------------------------------
  // SMART BUS RECOMMENDATION
  // --------------------------------------------------

  static Future<Map<String, dynamic>> recommendBus({
    required int sourceStopId,
    required int destinationStopId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommend-bus'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'source_stop_id': sourceStopId,
        'destination_stop_id': destinationStopId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get bus recommendation');
    }
  }

  // --------------------------------------------------
  // BOOK TICKET
  // --------------------------------------------------

  static Future<Map<String, dynamic>> bookTicket({
    required int userId,
    required int busId,
    required int sourceStopId,
    required int destinationStopId,
    required double fare,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/book-ticket'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'bus_id': busId,
        'source_stop_id': sourceStopId,
        'destination_stop_id': destinationStopId,
        'fare': fare,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to book ticket');
    }
  }

  // --------------------------------------------------
  // CREATE RAZORPAY ORDER
  // --------------------------------------------------

  static Future<Map<String, dynamic>> createRazorpayOrder({
    required int userId,
    required int busId,
    required int sourceStopId,
    required int destinationStopId,
    required double fare,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-razorpay-order'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'bus_id': busId,
        'source_stop_id': sourceStopId,
        'destination_stop_id': destinationStopId,
        'fare': fare,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create payment order');
    }
  }

  // --------------------------------------------------
  // VERIFY RAZORPAY PAYMENT
  // --------------------------------------------------

  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-razorpay-payment'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify payment');
    }
  }

  // --------------------------------------------------
  // GET ALL TICKETS
  // --------------------------------------------------

  static Future<List<dynamic>> getTickets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tickets'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['tickets'];
    } else {
      throw Exception('Failed to load tickets');
    }
  }

  // --------------------------------------------------
  // GET SINGLE TICKET
  // --------------------------------------------------

  static Future<Map<String, dynamic>> getTicket(
      int ticketId,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/ticket/$ticketId'),
      )
          .timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load ticket: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Unable to load ticket: $e');
    }
  }

  // --------------------------------------------------
  // CALCULATE FARE
  // --------------------------------------------------

  static Future<Map<String, dynamic>> calculateFare({
    required int busId,
    required int sourceStopId,
    required int destinationStopId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calculate-fare'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bus_id': busId,
        'source_stop_id': sourceStopId,
        'destination_stop_id': destinationStopId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to calculate fare');
    }
  }

  static Future<List<dynamic>> getStops() async {
    final response = await http.get(
      Uri.parse('$baseUrl/stops'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['stops'];
    } else {
      throw Exception('Failed to load stops');
    }
  }

  // --------------------------------------------------
  // GET TRIP HISTORY
  // --------------------------------------------------

  static Future<List<dynamic>> getTrips() async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['trips'] ?? [];
    } else {
      throw Exception('Failed to load trips');
    }
  }

  static Future<Map<String, dynamic>> startTrip({
    required int busId,
    required int routeId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/start-trip'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bus_id': busId,
        'route_id': routeId,
        'weather': 'clear',
        'traffic_level': 'moderate',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start trip');
    }
  }


  static Future<Map<String, dynamic>> endTrip({
    required int busId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/end-trip'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bus_id': busId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to end trip',
      );
    }
  }

  static Future<Map<String, dynamic>> addBus({
    required String busNumber,
    required String busName,
    required int capacity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-bus'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bus_number': busNumber,
        'bus_name': busName,
        'capacity': capacity,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add bus');
    }
  }

  static Future<Map<String, dynamic>> addRoute({
    required String routeName,
    required String source,
    required String destination,
    required double distanceKm,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-route'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'route_name': routeName,
        'source': source,
        'destination': destination,
        'distance_km': distanceKm,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add route');
    }
  }


  static Future<Map<String, dynamic>> updateRouteStatus({
    required int routeId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/route/$routeId/status'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update route status');
    }
  }


  static Future<List<dynamic>> getOperators() async {
    final response = await http.get(
      Uri.parse('$baseUrl/operators'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['operators'] ?? [];
    } else {
      throw Exception('Failed to load operators');
    }
  }


  static Future<Map<String, dynamic>> updateOperatorStatus({
    required int userId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/operator/$userId/status'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update operator status');
    }
  }


  static Future<Map<String, dynamic>> updateBusStatus({
    required int busId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bus/$busId/status'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update bus status');
    }
  }

  static Future<Map<String, dynamic>> getAdminReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/reports'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        return Map<String, dynamic>.from(
          data['reports'],
        );
      }

      throw Exception(
        data['message'] ?? 'Failed to fetch reports',
      );
    }

    throw Exception(
      'Failed to fetch reports: ${response.statusCode}',
    );
  }

  // Assign a bus to an operator
  static Future<Map<String, dynamic>> assignBusToOperator({
    required int operatorId,
    required int busId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/assign-bus'),

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'operator_id': operatorId,
        'bus_id': busId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to assign bus: ${response.statusCode}',
      );
    }
  }

  static Future<Map<String, dynamic>> createOperator({
    required String adminEmail,
    required String adminPassword,
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/create-operator'),

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'admin_email': adminEmail,
        'admin_password': adminPassword,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      'Failed to create operator: ${response.statusCode}',
    );
  }

  // Get buses assigned to a specific operator
  static Future<List<dynamic>> getOperatorBuses(
      int operatorId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/operator/$operatorId/buses'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        return data['buses'] ?? [];
      } else {
        throw Exception(
          data['message'] ?? 'Failed to load operator buses',
        );
      }
    } else {
      throw Exception(
        'Failed to load operator buses',
      );
    }
  }

  static Future<List<dynamic>> getRouteStops(int routeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/route-stops/$routeId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['stops'] ?? [];
    } else {
      throw Exception('Failed to load route stops');
    }
  }

  static Future<Map<String, dynamic>> addRouteStop({
    required int routeId,
    required int stopId,
    required int stopOrder,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/add-route-stop'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'route_id': routeId,
        'stop_id': stopId,
        'stop_order': stopOrder,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to add route stop',
      );
    }
  }


  static Future<Map<String, dynamic>> addStop({
    required String stopName,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/add-stop'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'stop_name': stopName,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Failed to add bus stop',
        );
      }
    } else {
      throw Exception(
        data['message'] ?? 'Failed to add bus stop',
      );
    }
  }


  static Future<Map<String, dynamic>> updateBusLocation({
    required int busId,
    required double latitude,
    required double longitude,
    double speed = 0.0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-bus-location'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bus_id': busId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to update bus location',
      );
    }
  }

}