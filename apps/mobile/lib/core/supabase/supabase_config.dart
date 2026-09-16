import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'supabase_service.dart';

class SupabaseConfig {
  static String get url =>
      dotenv.env['SUPABASE_URL'] ??
      (throw StateError(
        'SUPABASE_URL is missing — check that apps/mobile/.env exists and '
        'defines SUPABASE_URL (see apps/mobile/README.md for setup).',
      ));

  static String get anonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      (throw StateError(
        'SUPABASE_ANON_KEY is missing — check that apps/mobile/.env exists '
        'and defines SUPABASE_ANON_KEY (see apps/mobile/README.md for setup).',
      ));

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    // anonKey is deprecated in favor of publishableKey in this
    // supabase_flutter version.
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  static User? get currentUser => client.auth.currentUser;
  static String? get userId => currentUser?.id;
}

final supabaseProvider = Provider<SupabaseClient>(
  (ref) => SupabaseConfig.client,
);

/// The injectable [SupabaseService]. Overridden with a fake in tests
/// instead of talking to a real Supabase backend.
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseClientService(ref.watch(supabaseProvider)),
);
