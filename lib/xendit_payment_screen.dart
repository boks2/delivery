import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Para sa ilang Material icons kung kailangan
import 'package:hive/hive.dart';
import 'OrderTrackingScreen.dart'; // Import mo yung tracking screen mo dito

class XenditPaymentScreen extends StatelessWidget {
  final String orderName;
  final double amount;
  final dynamic destination; // LatLng

  const XenditPaymentScreen({super.key, required this.orderName, required this.amount, this.destination});

  void _processPayment(BuildContext context) {
    // 1. I-save sa Hive History
    var box = Hive.box('transactions');
    box.add({
      'name': orderName,
      'amount': amount,
      'date': DateTime.now().toString(),
      'status': 'Success',
    });

    // 2. Pumunta sa Tracking Screen
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder: (context) => OrderTrackingScreen(
          destination: destination,
          orderName: orderName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Xendit Payment")),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.creditcard, size: 80, color: Color(0xFF141240)), // Xendit color
              const SizedBox(height: 20),
              const Text("Xendit Sandbox", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Paying for: $orderName", style: const TextStyle(fontSize: 16)),
              Text("Amount: ₱$amount", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 40),
              CupertinoButton.filled(
                onPressed: () => _processPayment(context),
                child: const Text("Confirm Payment"),
              ),
              CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: CupertinoColors.destructiveRed)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}