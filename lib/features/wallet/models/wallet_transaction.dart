import '../wallet_logic.dart';

class WalletTransaction {
  final String type;
  final int amount;
  final DateTime createdAt;
  final String status;
  final String? description;

  const WalletTransaction({
    required this.type,
    required this.amount,
    required this.createdAt,
    required this.status,
    this.description,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final rawDescription = json['description']?.toString().trim();

    return WalletTransaction(
      type: json['type']?.toString() ?? '',
      amount:
          readIntValue(json['amount'] ?? json['coins'] ?? json['coinAmount']) ??
          0,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? '',
      description: rawDescription == null || rawDescription.isEmpty
          ? null
          : rawDescription,
    );
  }

  bool get isIncoming => transactionIsIncoming(amount);

  String get displayTitle => description ?? transactionTypeLabel(type);
}
