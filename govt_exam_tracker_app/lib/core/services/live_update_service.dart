import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class LiveUpdateService {

  static Future<String> getLiveStatus(String examName, String phaseName, String userApiKey) async {
    // 1. Construct a highly targeted search query
    final query = "$examName $phaseName admit card exam date result official update 2026";
    final searchUrl = Uri.parse('https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');

    try {
      // 2. Secretly scrape the web for real-time data
      final searchRes = await http.get(searchUrl, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }).timeout(const Duration(seconds: 10));

      String liveContext = '';
      if (searchRes.statusCode == 200) {
        // Use Regex to pluck the summary snippets from the search engine
        final regExp = RegExp(r'class="result__snippet[^>]*>(.*?)</a>', dotAll: true);
        final matches = regExp.allMatches(searchRes.body);
        for (var m in matches.take(5)) {
          liveContext += m.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '') + '\n';
        }
      }

      if (liveContext.isEmpty) {
        liveContext = "No recent search results found online.";
      }

      // 3. Send the LIVE data to Groq to read and summarize!
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final requestBody = {
        "model": AppConstants.activeAiModel,
        "messages": [
          {
            "role": "system",
            "content": "You are a helpful assistant for government exam aspirants. Give a direct, factual 2-sentence answer based ONLY on the provided search results."
          },
          {
            "role": "user",
            "content": '''
              Based on these live internet search results for '$examName - $phaseName':
              
              $liveContext
              
              What is the current official status for the $phaseName phase? 
              - If the exam hasn't happened, check if the admit card is released or exam date is announced. 
              - If the exam was already conducted, check if the result, merit list, or cut-off is declared.
              
              If the search results are vague or don't mention it, just say "There are no official updates available right now."
            '''
          }
        ],
        "temperature": 0.2
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $userApiKey'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'].trim();
      } else {
        return "Failed to analyze live data. The AI server might be busy.";
      }
    } catch (e) {
      return "Could not fetch live updates. Please check your internet connection.";
    }
  }
}