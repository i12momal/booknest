import 'package:supabase_flutter/supabase_flutter.dart';

// Servicio base para la derivación de clases y atributos generales de los servicios.
class BaseService {
  // Inicializamos la instancia de Supabase una sola vez
  static final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Método para inicializar Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://ejqvfrjilmxuqrxnrvbs.supabase.co', 
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqcXZmcmppbG14dXFyeG5ydmJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2ODA0NzcsImV4cCI6MjA1NjI1NjQ3N30.LwpuXcGmxJZf3cs3dCZFpDh01IPsnvFJlzkFLWaQk8s', // Reemplaza con tu clave anon
    );
  }

  // Método para obtener la instancia de Supabase
  static SupabaseClient get client => _supabaseClient;
}