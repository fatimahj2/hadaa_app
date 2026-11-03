/// Supabase project credentials.
///
/// Replace the placeholders below with the values from your Supabase
/// dashboard:
///   1. Go to https://app.supabase.com → your project
///   2. Project Settings (gear icon) → API
///   3. Copy "Project URL" into [url]
///   4. Copy "anon public" key into [anonKey]
///
/// In a production app you'd keep these out of source control (e.g. in
/// a .env file or via --dart-define), but for a class project hard-coding
/// the anon key is fine — it's designed to be public, and Row Level
/// Security in the database is what actually protects user data.
class SupabaseConfig {
  static const String url     = 'https://okvxdgvjnmhwhrueysgf.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9rdnhkZ3Zqbm1od2hydWV5c2dmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1NzYxNDQsImV4cCI6MjA5MTE1MjE0NH0.qAB3hXryptdEAIUkScu9Nkjm6AXkWgzIb9PKFPNM54E';
}
