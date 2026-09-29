import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'my_ticket_screen.dart';
import '../../services/api_service.dart';

class TicketBookingScreen extends StatefulWidget {
  final int busId;
  final int sourceStopId;
  final int destinationStopId;

  const TicketBookingScreen({
    super.key,
    required this.busId,
    required this.sourceStopId,
    required this.destinationStopId,
  });

  @override
  State<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen> {
  bool isLoading = true;
  bool isBooking = false;

  String? errorMessage;

  double fare = 0.0;

  String busNumber = 'Loading...';
  String sourceName = 'Loading...';
  String destinationName = 'Loading...';

  final int userId = 1;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    loadTicketDetails();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> loadTicketDetails() async {
    try {
      // Run both API requests at the same time
      final results = await Future.wait([
        ApiService.getBusRoute(widget.busId),
        ApiService.calculateFare(
          busId: widget.busId,
          sourceStopId: widget.sourceStopId,
          destinationStopId: widget.destinationStopId,
        ),
      ]);

      final routeData = results[0];
      final fareData = results[1];

      if (!mounted) return;

      if (routeData['success'] != true) {
        setState(() {
          errorMessage = 'Unable to load bus route';
          isLoading = false;
        });
        return;
      }

      if (fareData['success'] != true) {
        setState(() {
          errorMessage =
              fareData['message'] ?? 'Unable to calculate fare';
          isLoading = false;
        });
        return;
      }

      final stops = routeData['stops'] as List<dynamic>;

      String source = 'Unknown Stop';
      String destination = 'Unknown Stop';

      for (final stop in stops) {
        final stopId = (stop['stop_id'] as num).toInt();

        if (stopId == widget.sourceStopId) {
          source = stop['stop_name'].toString();
        }

        if (stopId == widget.destinationStopId) {
          destination = stop['stop_name'].toString();
        }
      }

      setState(() {
        busNumber = 'Bus ${routeData['bus_number']}';
        sourceName = source;
        destinationName = destination;
        fare = (fareData['fare'] as num).toDouble();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Failed to load ticket details';
        isLoading = false;
      });
    }
  }

  // --------------------------------------------------
  // STEP 1: create the Razorpay order on the backend,
  // then open Razorpay Checkout
  // --------------------------------------------------
  Future<void> bookTicket() async {
    if (isLoading || fare <= 0) return;

    setState(() {
      isBooking = true;
      errorMessage = null;
    });

    try {
      final orderResult = await ApiService.createRazorpayOrder(
        userId: userId,
        busId: widget.busId,
        sourceStopId: widget.sourceStopId,
        destinationStopId: widget.destinationStopId,
        fare: fare,
      );

      if (!mounted) return;

      if (orderResult['success'] != true) {
        setState(() {
          errorMessage =
              orderResult['message'] ?? 'Unable to start payment';
          isBooking = false;
        });
        return;
      }

      final options = {
        'key': orderResult['key_id'],
        'amount': orderResult['amount'],
        'currency': orderResult['currency'] ?? 'INR',
        'name': 'BusLens',
        'description': '$busNumber: $sourceName to $destinationName',
        'order_id': orderResult['order_id'],
      };

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Failed to connect to payment service';
        isBooking = false;
      });
    }
  }

  // --------------------------------------------------
  // STEP 2: Razorpay returned success on-device.
  // We still MUST verify with the backend before
  // trusting the payment.
  // --------------------------------------------------
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verifyResult = await ApiService.verifyRazorpayPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (!mounted) return;

      if (verifyResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful. Ticket confirmed.'),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyTicketScreen(
              ticketId: (verifyResult['ticket_id'] as num).toInt(),
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage =
              verifyResult['message'] ?? 'Payment verification failed';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Payment made, but verification failed. Contact support.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isBooking = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    setState(() {
      errorMessage = 'Payment failed: ${response.message ?? 'Cancelled or declined'}';
      isBooking = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment was not completed. Ticket was not booked.'),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;

    setState(() {
      isBooking = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opened external wallet: ${response.walletName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Ticket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : (errorMessage != null && fare <= 0)
            ? Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        )
            : Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.directions_bus,
                ),
                title: const Text('Bus'),
                subtitle: Text(busNumber),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                ),
                title: const Text('From'),
                subtitle: Text(sourceName),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.flag,
                ),
                title: const Text('To'),
                subtitle: Text(destinationName),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Ticket Fare',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹${fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                isBooking ? null : bookTicket,
                icon: isBooking
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
                  Icons.payment,
                ),
                label: Text(
                  isBooking
                      ? 'Processing...'
                      : 'Proceed to Payment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}