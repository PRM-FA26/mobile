import 'package:flutter_test/flutter_test.dart';
import 'package:chapterone_mobile/features/wallet/wallet_logic.dart';

void main() {
  group('vndToXu', () {
    test('converts VND to xu at 1000 VND per xu (matches backend)', () {
      expect(vndToXu(5000), 5);
      expect(vndToXu(10000), 10);
      expect(vndToXu(50000), 50);
      expect(vndToXu(100000), 100);
    });
  });

  group('kDepositPackagesVnd', () {
    test('only contains packages accepted by backend whitelist', () {
      expect(kDepositPackagesVnd, [5000, 10000, 50000, 100000]);
    });
  });

  group('transactionTypeLabel', () {
    test('maps backend transaction types to Vietnamese labels', () {
      expect(transactionTypeLabel('DEPOSIT'), 'Nạp xu');
      expect(transactionTypeLabel('WITHDRAWAL'), 'Rút tiền');
      expect(transactionTypeLabel('UNLOCK'), 'Mua chương');
      expect(transactionTypeLabel('DONATE'), 'Donate');
    });

    test('falls back to raw type for unknown types', () {
      expect(transactionTypeLabel('MYSTERY'), 'MYSTERY');
    });
  });

  group('transactionIsIncoming', () {
    test('is true for non-negative amounts, false for negative', () {
      expect(transactionIsIncoming(50), true);
      expect(transactionIsIncoming(0), true);
      expect(transactionIsIncoming(-50), false);
    });
  });

  group('extractListPayload', () {
    test('reads direct and enveloped lists', () {
      expect(extractListPayload([1, 2]), [1, 2]);
      expect(
        extractListPayload({
          'transactions': [1, 2],
        }),
        [1, 2],
      );
      expect(
        extractListPayload({
          'items': [3],
        }),
        [3],
      );
    });

    test('falls back to empty list for unsupported payloads', () {
      expect(extractListPayload({'data': 'invalid'}), isEmpty);
      expect(extractListPayload(null), isEmpty);
    });
  });

  group('extractPaymentUrl', () {
    test('reads direct and nested payment urls', () {
      expect(
        extractPaymentUrl('https://pay.example/1'),
        'https://pay.example/1',
      );
      expect(
        extractPaymentUrl({
          'data': {
            'checkout': {'checkout_url': 'https://pay.example/2'},
          },
        }),
        'https://pay.example/2',
      );
    });

    test('rejects direct strings without a scheme', () {
      expect(extractPaymentUrl('pay.example/1'), isNull);
    });
  });

  group('readWalletBalance', () {
    test('reads accepted wallet balance fields', () {
      expect(readWalletBalance({'balance': 10}), 10);
      expect(readWalletBalance({'coinBalance': '20'}), 20);
      expect(readWalletBalance({'coins': 30.5}), 30);
      expect(readWalletBalance({'amount': '40'}), 40);
    });

    test('falls back to zero when balance is missing', () {
      expect(readWalletBalance({}), 0);
      expect(readWalletBalance(null), 0);
    });
  });
}
