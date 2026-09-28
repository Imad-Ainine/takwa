import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/payments/premium_entitlement.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/supabase/supabase_providers.dart';

/// Reads the signed-in user's server-side premium entitlement (written by
/// the Freemius webhook; RLS lets each user see only their own row).
///
/// A plain fetch instead of a realtime stream: no payment table is in the
/// realtime publication, and every screen that cares (subscription status,
/// post-checkout confirmation) re-reads at the moment it is shown or during
/// its own poll, so a stream would add configuration surface, not accuracy.
class PremiumEntitlementRepository {
  const PremiumEntitlementRepository();

  Future<PremiumEntitlement?> fetch(String userId) async {
    final row = await SupabaseConfig.client
        .from('premium_entitlements')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return PremiumEntitlement.fromRow(Map<String, dynamic>.from(row));
  }
}

final premiumEntitlementRepositoryProvider =
    Provider<PremiumEntitlementRepository>((_) => const PremiumEntitlementRepository());

/// `null` = no entitlement at all (guest, or paid only through the legacy
/// honor-system channels that never wrote server state).
final premiumEntitlementProvider = FutureProvider<PremiumEntitlement?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(premiumEntitlementRepositoryProvider).fetch(user.id);
});
