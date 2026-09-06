import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class AiClientService {

  // 1. OPENROUTER AUTO-DISCOVERY
  static Future<String> _getOpenRouterFreeModel() async {
    try {
      final res = await http.get(Uri.parse('https://openrouter.ai/api/v1/models')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final models = jsonDecode(res.body)['data'] as List;
        List<String> freeModels = [];

        for (var m in models) {
          if (m['id'].toString().endsWith(':free')) freeModels.add(m['id'].toString());
        }

        for (var p in ['qwen', 'llama', 'mistral', 'gemma']) {
          final match = freeModels.firstWhere((id) => id.toLowerCase().contains(p), orElse: () => '');
          if (match.isNotEmpty) return match;
        }

        if (freeModels.isNotEmpty) return freeModels.first;
      }
    } catch (_) {}
    return 'qwen/qwen-2.5-7b-instruct:free'; // Ultimate Fallback
  }

  // 2. THE MASTER ROUTER
  static Future<String> callAi({
    required String systemPrompt,
    required String userPrompt,
    required String userApiKey,
    required String provider,
    double temperature = 0.1,
    int timeoutSeconds = 25,
  }) async {

    if (provider == 'gemini') {
      // NOTE: 'gemini' routes to OpenRouter for unlimited free access
      final activeModel = await _getOpenRouterFreeModel();
      final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

      final requestBody = {
        "model": activeModel,
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userPrompt}
        ],
        "temperature": temperature
      };

      final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $userApiKey'},
          body: jsonEncode(requestBody)
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['choices'][0]['message']['content'];
      } else if (response.statusCode == 429) {
        throw Exception('RATE_LIMIT');
      } else {
        throw Exception('OpenRouter Error: ${response.statusCode} - ${response.body}');
      }

    } else {
      // GROQ (Using ultra-fast Qwen)
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final requestBody = {
        "model": AppConstants.groqModel,
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userPrompt}
        ],
        "temperature": temperature
      };

      final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $userApiKey'},
          body: jsonEncode(requestBody)
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['choices'][0]['message']['content'];
      } else if (response.statusCode == 429) {
        throw Exception('RATE_LIMIT');
      } else {
        throw Exception('Groq Error: ${response.statusCode} - ${response.body}');
      }
    }
  }
}