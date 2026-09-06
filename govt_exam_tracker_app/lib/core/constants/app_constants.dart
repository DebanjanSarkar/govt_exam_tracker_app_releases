class AppConstants {
  static const int aiCooldownSeconds = 75;

  static const String prefsLastAiCallKey = 'last_ai_call_timestamp';
  static const String prefsGeminiApiKey = 'user_gemini_api_key';
  static const String prefsGroqApiKey = 'user_groq_api_key';
  static const String prefsActiveAiProvider = 'active_ai_provider';

  // THE PROVEN, WORKING MODELS (No more 404 errors)
  static const String groqModel = 'qwen/qwen3.8-27b';
  static const String geminiModel = 'gemini-flash-latest';
}
