/// Environment configuration for Aapno Care App
/// Switch between dev and production by changing the active profile
class Env {
  // ─── Development (active) ─────────────────────────
  static const String apiBaseUrl = 'https://shanta-unstabilized-ryker.ngrok-free.dev/v1';
  static const String wsUrl = 'wss://shanta-unstabilized-ryker.ngrok-free.dev';
  static const String razorpayKey = 'rzp_test_SgTgIrRTm5fJjb';
  static const String mapApiKey = 'YOUR_GOOGLE_MAPS_KEY';

  // ─── Production (disabled) ─
  // static const String apiBaseUrl = 'https://api.aapno.org/v1';
  // static const String wsUrl = 'wss://api.aapno.org';
  // static const String razorpayKey = 'rzp_live_xxxxx';
  // static const String mapApiKey = 'YOUR_PROD_MAPS_KEY';

  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 30000; // ms
}
