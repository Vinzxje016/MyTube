class SupabaseConfig {
  // Fallback values for local runs from the IDE. Use only a publishable/anon key.
  static const _localUrl = 'https://whrcqwmovmhphfilckep.supabase.co';
  static const _localPublishableKey = 'sb_publishable_sRO4fYakt9tND4NCaeZWlw_VcgV-EMg';

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _localUrl,
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _localPublishableKey,
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
