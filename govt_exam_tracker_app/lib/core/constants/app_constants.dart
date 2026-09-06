class AppConstants {
  static const int aiCooldownSeconds = 75;

  static const String prefsLastAiCallKey = 'last_ai_call_timestamp';
  static const String prefsGeminiApiKey = 'user_cerebras_api_key'; // Kept the variable name 'prefsGeminiApiKey' so old DBs don't crash, but it holds Cerebras now!
  static const String prefsGroqApiKey = 'user_groq_api_key';
  static const String prefsActiveAiProvider = 'active_ai_provider';

  // THE PROVEN, WORKING MODELS
  static const String groqModel = 'qwen/qwen3.8-27b';
  static const String cerebrasModel = 'llama3.1-8b'; // Cerebras' blazing fast free model
}
