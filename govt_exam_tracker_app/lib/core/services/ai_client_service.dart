import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class AiClientService {

  // 1. METICULOUS CEREBRAS AUTO-DISCOVERY
  static Future<String> _getCerebrasModel(String apiKey) async {
    try {
      final res = await http.get(
          Uri.parse('https://api.cerebras.ai/v1/models'),
          headers: {'Authorization': 'Bearer $apiKey'}
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final models = data['data'] as List;

        debugPrint('\n========== LIVE CEREBRAS MODELS ==========');
        for (var m in models) {
          debugPrint(m['id'].toString());
        }
        debugPrint('==========================================\n');

        // Priority 1: Heavy duty 70B model for high accuracy
        for (var m in models) {
          String id = m['id'].toString().toLowerCase();
          if (id.contains('70b') && id.contains('llama')) {
            debugPrint('🎯 Auto-Selected Cerebras Model: ${m['id']}');
            return m['id'].toString();
          }
        }

        // Priority 2: Blazing fast 8B model
        for (var m in models) {
          String id = m['id'].toString().toLowerCase();
          if (id.contains('8b') && id.contains('llama')) {
            debugPrint('🎯 Auto-Selected Cerebras Model: ${m['id']}');
            return m['id'].toString();
          }
        }

        // Failsafe: Just return the first available model
        if (models.isNotEmpty) return models.first['id'].toString();
      } else {
        debugPrint('Cerebras Models API Failed with status: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to dynamically fetch Cerebras models: $e');
    }

    // Ultimate fallback if internet drops during discovery
    return 'llama3.1-8b';
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
      // NOTE: 'gemini' variable internally routes to CEREBRAS Cloud!
      final activeModel = await _getCerebrasModel(userApiKey);
      final url = Uri.parse('https://api.cerebras.ai/v1/chat/completions');

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
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $userApiKey'
          },
          body: jsonEncode(requestBody)
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['choices'][0]['message']['content'];
      } else if (response.statusCode == 429) {
        throw Exception('RATE_LIMIT');
      } else {
        throw Exception('Cerebras Error: ${response.statusCode} - ${response.body}');
      }

    } else {
      // GROQ (Using the stable model from Constants)
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
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $userApiKey'
          },
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