/// Environment configuration for Aapno Care App
/// Switch between dev and production by changing the active profile
class Env {
  // ─── Development ─────────────────────────
  static const String apiBaseUrl = 'http://localhost:4000/v1';
  static const String wsUrl = 'ws://localhost:4000';
  static const String razorpayKey = 'rzp_test_xxxxx';
  static const String mapApiKey = 'YOUR_GOOGLE_MAPS_KEY';

  // ─── Production (uncomment when deploying) ─
  // static const String apiBaseUrl = 'https://api.aapno.org/v1';
  // static const String wsUrl = 'wss://api.aapno.org';
  // static const String razorpayKey = 'rzp_live_xxxxx';
  // static const String mapApiKey = 'YOUR_PROD_MAPS_KEY';

  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 30000; // ms
}
