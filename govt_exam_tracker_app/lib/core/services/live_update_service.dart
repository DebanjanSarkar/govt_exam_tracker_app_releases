import 'package:http/http.dart' as http;
import 'ai_client_service.dart'; // NEW IMPORT

class LiveUpdateService {

  static Future<String> getLiveStatus(String examName, String phaseName, String userApiKey, String provider) async {
    final query = "$examName $phaseName admit card exam date result official update 2026";
    final searchUrl = Uri.parse('https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');

    try {
      final searchRes = await http.get(searchUrl, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }).timeout(const Duration(seconds: 10));

      String liveContext = '';
      if (searchRes.statusCode == 200) {
        final regExp = RegExp(r'class="result__snippet[^>]*>(.*?)</a>', dotAll: true);
        final matches = regExp.allMatches(searchRes.body);
        for (var m in matches.take(5)) {
          liveContext += m.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '') + '\n';
        }
      }

      if (liveContext.isEmpty) {
        liveContext = "No recent search results found online.";
      }

      // USE THE NEW MODULAR CLIENT
      return await AiClientService.callAi(
        systemPrompt: "You are a helpful assistant for government exam aspirants. Give a direct, factual 2-sentence answer based ONLY on the provided search results.",
        userPrompt: '''
          Based on these live internet search results for '$examName - $phaseName':
          
          $liveContext
          
          What is the current official status for the $phaseName phase? 
          - If the exam hasn't happened, check if the admit card is released or exam date is announced. 
          - If the exam was already conducted, check if the result, merit list, or cut-off is declared.
          
          If the search results are vague or don't mention it, just say "There are no official updates available right now."
        ''',
        userApiKey: userApiKey,
        provider: provider,
        temperature: 0.2,
        timeoutSeconds: 15, // Faster timeout for live checks
      );

    } catch (e) {
      return "Could not fetch live updates. Please check your internet connection.";
    }
  }
}