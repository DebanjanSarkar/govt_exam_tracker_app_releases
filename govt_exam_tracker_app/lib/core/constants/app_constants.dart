class AppConstants {
  // Hardcoded to the live, ultra-smart Qwen model
  static String activeAiModel = 'qwen/qwen3.8-27b';

  // GLOBAL AI COOLDOWN SETTINGS
  static const int aiCooldownSeconds = 75; // Change this single value to affect the whole app
  static const String prefsLastAiCallKey = 'last_ai_call_timestamp';

  // User's groq API key:
  static const String prefsApiKey = 'user_groq_api_key';
}
