// Pure wallet logic shared by the wallet UI.
//
// Kept free of Flutter imports so it can be unit-tested in isolation and
// stays in sync with the backend (`be-pbvm-web-novel/src/routes/wallet`).

/// Backend conversion rate: 1 xu = 1000 VND (`VND_PER_XU` in wallet.service.ts).
const int kVndPerXu = 1000;

/// Deposit packages accepted by the backend whitelist (wallet.dto.ts).
/// Mobile must only offer these or the backend rejects the request.
const List<int> kDepositPackagesVnd = [5000, 10000, 50000, 100000];

/// Converts a VND amount to the xu the backend will credit.
int vndToXu(int vnd) => vnd ~/ kVndPerXu;

/// Maps a backend transaction `type` to a Vietnamese label.
/// Falls back to the raw type for anything unknown.
String transactionTypeLabel(String type) {
  switch (type) {
    case 'DEPOSIT':
      return 'Nạp xu';
    case 'WITHDRAWAL':
      return 'Rút tiền';
    case 'UNLOCK':
      return 'Mua chương';
    case 'DONATE':
      return 'Donate';
    default:
      return type;
  }
}

/// Whether a transaction increases the wallet balance.
/// Backend stores incoming amounts as non-negative and outgoing as negative.
bool transactionIsIncoming(int amount) => amount >= 0;

/// Extracts a list from common paginated/list response envelopes.
List<dynamic> extractListPayload(dynamic value) {
  if (value is List) return value;
  if (value is Map) {
    for (final key in ['data', 'transactions', 'items', 'results']) {
      final nested = value[key];
      if (nested is List) return nested;
    }
  }
  return const [];
}

/// Finds a checkout URL in direct or nested backend response payloads.
String? extractPaymentUrl(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    return uri != null && uri.hasScheme ? trimmed : null;
  }

  if (value is Map) {
    for (final key in [
      'paymentUrl',
      'checkoutUrl',
      'checkout_url',
      'paymentLink',
      'payment_link',
      'paymentLinkUrl',
      'payment_link_url',
      'url',
      'href',
    ]) {
      final url = value[key];
      if (url is String && url.trim().isNotEmpty) return url.trim();
    }

    for (final key in ['data', 'payment', 'checkout', 'payos', 'result']) {
      final nestedUrl = extractPaymentUrl(value[key]);
      if (nestedUrl != null) return nestedUrl;
    }
  }

  return null;
}

/// Reads an integer from numeric and string API fields.
int? readIntValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// Reads the wallet balance across accepted backend field names.
int readWalletBalance(Map<String, dynamic>? wallet) {
  return readIntValue(
        wallet?['balance'] ??
            wallet?['coinBalance'] ??
            wallet?['coins'] ??
            wallet?['amount'],
      ) ??
      0;
}
