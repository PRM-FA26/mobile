class WalletWithdrawRequest {
  final int amount;
  final String bankName;
  final String accountNumber;
  final String accountName;

  const WalletWithdrawRequest({
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
    };
  }
}
