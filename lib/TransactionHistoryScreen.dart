import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'transaction_model.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Transaction History")),
      child: ValueListenableBuilder(
        valueListenable: Hive.box<TransactionHistory>("historyBox").listenable(),
        builder: (context, Box<TransactionHistory> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No transactions yet."));
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final tx = box.getAt(box.length - 1 - index); // Latest first
              return CupertinoListTile(
                title: Text(tx!.itemName),
                subtitle: Text("${tx.date.day}/${tx.date.month}/${tx.date.year}"),
                trailing: Text("₱${tx.amount.toStringAsFixed(2)}",
                    style: const TextStyle(color: CupertinoColors.activeGreen, fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}