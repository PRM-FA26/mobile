import 'package:flutter_test/flutter_test.dart';
import 'package:chapterone_mobile/features/wallet/models/wallet_transaction.dart';

void main() {
  group('WalletTransaction.fromJson', () {
    test('parses a full transaction payload', () {
      final tx = WalletTransaction.fromJson({
        'type': 'DEPOSIT',
        'amount': 50,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'status': 'SUCCESS',
        'description': 'Nạp qua PayOS',
      });

      expect(tx.type, 'DEPOSIT');
      expect(tx.amount, 50);
      expect(tx.status, 'SUCCESS');
      expect(tx.description, 'Nạp qua PayOS');
      expect(tx.isIncoming, true);
      expect(tx.displayTitle, 'Nạp qua PayOS');
    });

    test('reads amount from coins/coinAmount fallback fields', () {
      expect(WalletTransaction.fromJson({'coins': 10}).amount, 10);
      expect(WalletTransaction.fromJson({'coinAmount': 20}).amount, 20);
    });

    test('treats a blank description as absent and falls back to the type label', () {
      final tx = WalletTransaction.fromJson({'type': 'WITHDRAWAL', 'description': '   '});
      expect(tx.description, isNull);
      expect(tx.displayTitle, 'Rút tiền');
    });

    test('defaults amount to 0 and createdAt to now when missing', () {
      final tx = WalletTransaction.fromJson({});
      expect(tx.amount, 0);
      expect(tx.createdAt, isNotNull);
    });
  });
}
