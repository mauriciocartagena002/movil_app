class ConfiguracionSupabase {
  const ConfiguracionSupabase._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const clavePublica = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get estaConfigurado {
    return url.trim().isNotEmpty && clavePublica.trim().isNotEmpty;
  }
}
