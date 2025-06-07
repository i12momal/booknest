import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Servicio base para la derivación de clases y atributos generales de los servicios.
class BaseService {
  static final SupabaseClient _supabaseClient = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  static SupabaseClient get client => _supabaseClient;
}