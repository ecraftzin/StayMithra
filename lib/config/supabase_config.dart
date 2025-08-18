import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://rssnqbqbrejnjeiukrdr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzc25xYnFicmVqbmplaXVrcmRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUyNTYyMzQsImV4cCI6MjA3MDgzMjIzNH0.DPX7FUSjueQ9ex3JTlsjhC78dq1kJY4VB7_2PQLKFGI';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}

// Global Supabase client instance
final supabase = Supabase.instance.client;
