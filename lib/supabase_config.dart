// supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';
// Pour mobile
// Pour web

class SupabaseConfig {
  static const String supabaseUrl = 'https://xcufqczmpntcerlqzfai.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjdWZxY3ptcG50Y2VybHF6ZmFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxNTQwNjUsImV4cCI6MjA3MTczMDA2NX0.jiU-C9zmSv7eh8__w_iCTJ4WRaVHR2n7sj69fRenkKo';
  static const String bucketName = 'course-files';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
