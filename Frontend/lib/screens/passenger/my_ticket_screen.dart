import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MyTicketScreen extends StatefulWidget {
  final int ticketId;

  const MyTicketScreen({
    super.key,
    required this.ticketId,
  });

  @override
  State<MyTicketScreen> createState() => _MyTicketScreenState();
}

class _MyTicketScreenState extends State<MyTicketScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? ticketData;

  @override
  void initState() {
    super.initState();
    loadTicket();
  }

  Future<void> loadTicket() async {
    try {
      final result = await ApiService.getTicket(
        widget.ticketId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          ticketData = result;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              result['message'] ?? 'Ticket not found';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load ticket details';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ticket'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            errorMessage!,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ticketData == null
          ? const Center(
        child: Text(
          'Ticket details not available',
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(15),
            ),
            child: Padding(
              padding:
              const EdgeInsets.all(20),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [

                  const Icon(
                    Icons.confirmation_number,
                    size: 60,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Ticket Confirmed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const Divider(
                    height: 30,
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.directions_bus,
                    ),
                    title: const Text('Bus'),
                    subtitle: Text(
                      'Bus ${ticketData!['bus_number']}',
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.location_on,
                    ),
                    title: const Text('From'),
                    subtitle: Text(
                      ticketData!['source']
                          .toString(),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.flag,
                    ),
                    title: const Text('To'),
                    subtitle: Text(
                      ticketData!['destination']
                          .toString(),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.currency_rupee,
                    ),
                    title: const Text('Fare'),
                    subtitle: Text(
                      '₹${ticketData!['fare']}',
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.numbers,
                    ),
                    title: const Text(
                      'Ticket ID',
                    ),
                    subtitle: Text(
                      'Ticket #${ticketData!['ticket_id']}',
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: const Text(
                      'Ticket Status',
                    ),
                    subtitle: Text(
                      ticketData![
                      'ticket_status']
                          .toString(),
                    ),
                  ),

                  const Divider(
                    height: 30,
                  ),

                  const Align(
                    alignment:
                    Alignment.centerLeft,
                    child: Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ListTile(
                    leading: const Icon(
                      Icons.payment,
                    ),
                    title: const Text(
                      'Payment Method',
                    ),
                    subtitle: Text(
                      ticketData![
                      'payment_method'] ??
                          'Not Available',
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.verified,
                      color: Colors.green,
                    ),
                    title: const Text(
                      'Payment Status',
                    ),
                    subtitle: Text(
                      ticketData![
                      'payment_status'] ??
                          'Not Available',
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.currency_rupee,
                    ),
                    title: const Text(
                      'Payment Amount',
                    ),
                    subtitle: Text(
                      '₹${ticketData!['payment_amount'] ?? ticketData!['fare']}',
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long,
                    ),
                    title: const Text(
                      'Razorpay Payment ID',
                    ),
                    subtitle: Text(
                      ticketData!['razorpay_payment_id'] ??
                          'Not Available',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}