/// Supabase configuration for Routica.
///
/// The anon key is safe to expose in client code — Supabase uses
/// Row Level Security (RLS) to protect data, not key secrecy.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://ilpcdndtvebdpwjeryah.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlscGNkbmR0dmViZHB3amVyeWFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3NTIwOTUsImV4cCI6MjA5ODMyODA5NX0.PyO1k6oR8vPvvA7gfdlFmB47yzx8vsihFgourKsOhdU';
}
