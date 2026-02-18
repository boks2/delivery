import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionHistory extends HiveObject {
  @HiveField(0)
  final String itemName;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final DateTime date;

  TransactionHistory({required this.itemName, required this.amount, required this.date});
}