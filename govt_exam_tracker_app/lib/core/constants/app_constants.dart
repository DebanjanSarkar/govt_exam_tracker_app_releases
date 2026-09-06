class AppConstants {
  static const int aiCooldownSeconds = 75;

  static const String prefsLastAiCallKey = 'last_ai_call_timestamp';
  static const String prefsGeminiApiKey = 'user_gemini_api_key';
  static const String prefsGroqApiKey = 'user_groq_api_key';
  static const String prefsActiveAiProvider = 'active_ai_provider';

  // THE PROVEN, WORKING MODELS
  static const String groqModel = 'qwen/qwen3.8-27b';
  // NEW: OpenRouter Free Llama 3.1 Endpoint
  static const String openRouterModel = 'meta-llama/llama-3.1-8b-instruct:free';
}
