import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/database_providers.dart';

/// Which channel a support payment was made through.
enum SupportChannel { chargily, wise }

/// One recorded support contribution (honor-system: Chargily entries carry a
/// server-verified `paid` status; Wise entries are user-declared until the
/// account statement is reconciled manually).
class SupportPayment {
  final SupportChannel channel;
  final String? checkoutId;
  final String status;
  final int amountMinor;
  final String currency;
  final DateTime at;

  const SupportPayment({
    required this.channel,
    this.checkoutId,
    required this.status,
    required this.amountMinor,
    required this.currency,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
    'channel': channel.name,
    'checkoutId': checkoutId,
    'status': status,
    'amount': amountMinor,
    'currency': currency,
    'at': at.toIso8601String(),
  };

  factory SupportPayment.fromJson(Map<String, dynamic> j) => SupportPayment(
    channel: SupportChannel.values.byName(j['channel'] as String),
    checkoutId: j['checkoutId'] as String?,
    status: j['status'] as String? ?? 'pending',
    amountMinor: (j['amount'] as num?)?.toInt() ?? 0,
    currency: j['currency'] as String? ?? 'dzd',
    at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Local-first record of the user's support payments, stored in the
/// `premium_payments` settings key (JSON list, newest first). Follows the
/// same honor-system spirit as the rest of the subscription screens —
/// Chargily status is verified server-side when available, Wise receipts
/// cannot be verified from the app.
class SubscriptionStore {
  static const paymentsKey = 'premium_payments';
  static const _maxKept = 24;

  final Ref ref;
  SubscriptionStore(this.ref);

  Future<List<SupportPayment>> loadPayments() async {
    final raw = await ref.read(settingsDaoProvider).get(paymentsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SupportPayment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> recordPayment(SupportPayment payment) async {
    final payments = [...await loadPayments(), payment];
    final trimmed = payments.length > _maxKept
        ? payments.sublist(payments.length - _maxKept)
        : payments;
    await ref.read(settingsDaoProvider).set(
      paymentsKey,
      jsonEncode(trimmed.map((p) => p.toJson()).toList()),
    );
  }
}

final subscriptionStoreProvider = Provider<SubscriptionStore>(
  (ref) => SubscriptionStore(ref),
);
