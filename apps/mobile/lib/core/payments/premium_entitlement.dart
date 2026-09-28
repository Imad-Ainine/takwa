/// Server-side premium entitlement mirrored from the Supabase
/// `premium_entitlements` table (written exclusively by the Freemius
/// webhook — see docs/freemius-integration.md). Pure data + rules, no
/// Supabase imports, so the access logic is unit-testable.
library;

class PremiumEntitlement {
  /// One of: trial, active, past_due, canceled, expired, refunded.
  final String status;
  final bool isTrial;
  final bool cancelAtPeriodEnd;
  final DateTime? currentPeriodEnd;
  final String? planTitle;
  final String? planId;
  final String source;
  final String? email;

  const PremiumEntitlement({
    required this.status,
    this.isTrial = false,
    this.cancelAtPeriodEnd = false,
    this.currentPeriodEnd,
    this.planTitle,
    this.planId,
    this.source = 'freemius',
    this.email,
  });

  factory PremiumEntitlement.fromRow(Map<String, dynamic> row) {
    final rawEnd = row['current_period_end'];
    return PremiumEntitlement(
      status: row['status'] as String? ?? 'expired',
      isTrial: row['is_trial'] as bool? ?? false,
      cancelAtPeriodEnd: row['cancel_at_period_end'] as bool? ?? false,
      // Supabase hands timestamptz back as UTC; compare in local time.
      currentPeriodEnd: rawEnd == null ? null : DateTime.tryParse('$rawEnd')?.toLocal(),
      planTitle: row['plan_title'] as String?,
      planId: row['plan_id'] as String?,
      source: row['source'] as String? ?? 'freemius',
      email: row['email'] as String?,
    );
  }

  /// Access rule shared by UI everywhere: paid-period statuses are live,
  /// past_due keeps access until the period lapses (Freemius is still
  /// retrying the renewal), a canceled subscription keeps access until the
  /// period the user already paid for ends.
  bool isActiveAt(DateTime now) {
    final end = currentPeriodEnd;
    switch (status) {
      case 'trial':
      case 'active':
        return end == null || now.isBefore(end);
      case 'past_due':
      case 'canceled':
        return end != null && now.isBefore(end);
      default:
        return false;
    }
  }

  PremiumDisplay get display {
    final now = DateTime.now();
    switch (status) {
      case 'trial':
        return isActiveAt(now) ? PremiumDisplay.trial : PremiumDisplay.expired;
      case 'active':
        return isActiveAt(now) ? PremiumDisplay.active : PremiumDisplay.expired;
      case 'past_due':
        return isActiveAt(now) ? PremiumDisplay.pastDue : PremiumDisplay.expired;
      case 'canceled':
        return isActiveAt(now) ? PremiumDisplay.canceling : PremiumDisplay.canceled;
      case 'refunded':
        return PremiumDisplay.refunded;
      default:
        return PremiumDisplay.expired;
    }
  }
}

enum PremiumDisplay {
  none,
  active,
  trial,
  pastDue,
  canceling,
  canceled,
  expired,
  refunded,
}
