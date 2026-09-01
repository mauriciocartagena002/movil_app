import 'package:supabase/supabase.dart';

import '../config/configuracion_supabase.dart';

class ServicioSupabase {
  const ServicioSupabase._();

  static SupabaseClient? _cliente;
  static var _inicializado = false;
  static String? _errorInicializacion;

  static bool get estaInicializado => _inicializado;
  static String? get errorInicializacion => _errorInicializacion;

  static SupabaseClient get cliente {
    if (!_inicializado) {
      throw StateError(
        'Supabase no esta inicializado. Ejecuta Flutter usando --dart-define '
        'para SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY.',
      );
    }

    return _cliente!;
  }

  static Future<void> inicializar() async {
    if (_inicializado) {
      return;
    }

    if (!ConfiguracionSupabase.estaConfigurado) {
      return;
    }

    try {
      _cliente = SupabaseClient(
        ConfiguracionSupabase.url,
        ConfiguracionSupabase.clavePublica,
      );
      _inicializado = true;
      _errorInicializacion = null;
    } catch (error) {
      _cliente = null;
      _inicializado = false;
      _errorInicializacion = error.toString();
    }
  }
}
