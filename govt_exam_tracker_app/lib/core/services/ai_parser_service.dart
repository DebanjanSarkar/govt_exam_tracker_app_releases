import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../constants/app_constants.dart';

// FAST PDF EXTRACTOR (layoutText: false)
String _processPdfInIsolate(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(document);
  final int pageCount = document.pages.count;

  String coreInfo = '';
  String dateInfo = '\n--- DATES ---\n';
  String feeInfo = '\n--- FEES ---\n';
  String eligibilityInfo = '\n--- ELIGIBILITY ---\n';

  int dateChars = 0; int feeChars = 0; int eligibilityChars = 0;
  const int limitPerCategory = 2500;

  int corePages = pageCount > 3 ? 3 : pageCount;
  for (int i = 0; i < corePages; i++) {
    coreInfo += extractor.extractText(startPageIndex: i, endPageIndex: i) + '\n\n';
  }

  if (pageCount > 3) {
    for (int i = 3; i < pageCount; i++) {
      if (dateChars >= limitPerCategory && feeChars >= limitPerCategory && eligibilityChars >= limitPerCategory) break;
      String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      List<String> lines = pageText.split('\n');

      for (int j = 0; j < lines.length; j++) {
        String lowerLine = lines[j].toLowerCase();
        bool isDate = lowerLine.contains('opening date') || lowerLine.contains('closing date') || lowerLine.contains('last date') || lowerLine.contains('tentative date') || lowerLine.contains('commencement of');
        bool isFee = lowerLine.contains('application fee') || lowerLine.contains('examination fee') || lowerLine.contains('intimation charges') || lowerLine.contains('fee : rs') || lowerLine.contains('fee: rs') || lowerLine.contains('non-refundable');
        bool isElig = lowerLine.contains('age limit') || lowerLine.contains('educational qualification') || lowerLine.contains('essential qualification') || lowerLine.contains('eligibility criteria');

        if (isDate || isFee || isElig) {
          int start = (j - 1 < 0) ? 0 : j - 1;
          int end = (j + 5 >= lines.length) ? lines.length - 1 : j + 5;
          String contextBlock = lines.sublist(start, end + 1).join(' ') + '\n\n';

          if (isDate && dateChars < limitPerCategory) { dateInfo += contextBlock; dateChars += contextBlock.length; j = end; }
          else if (isFee && feeChars < limitPerCategory) { feeInfo += contextBlock; feeChars += contextBlock.length; j = end; }
          else if (isElig && eligibilityChars < limitPerCategory) { eligibilityInfo += contextBlock; eligibilityChars += contextBlock.length; j = end; }
        }
      }
    }
  }
  document.dispose();
  String finalContext = coreInfo + dateInfo + feeInfo + eligibilityInfo;

  const int maxChars = 14000;
  if (finalContext.length > maxChars) finalContext = finalContext.substring(0, maxChars);
  return finalContext;
}

class AiParserService {

  // DUAL ENGINE ROUTER
  static Future<String> _callDualEngineAi(String systemPrompt, String userPrompt, String userApiKey, String provider) async {
    if (provider == 'gemini') {
      // FIXED: Uses AppConstants.geminiModel
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/${AppConstants.geminiModel}:generateContent?key=$userApiKey');
      final requestBody = {
        "contents": [{"parts": [{"text": "$systemPrompt\n\n$userPrompt"}]}],
        "generationConfig": {"temperature": 0.1, "responseMimeType": "application/json"}
      };

      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(requestBody)).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) return jsonDecode(response.body)['candidates'][0]['content']['parts'][0]['text'];
      else if (response.statusCode == 429) throw Exception('RATE_LIMIT');
      else throw Exception('Gemini Error: ${response.statusCode} - ${response.body}');
    } else {
      // FIXED: Uses AppConstants.groqModel
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final requestBody = {
        "model": AppConstants.groqModel,
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userPrompt}
        ],
        "temperature": 0.1
      };

      final response = await http.post(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $userApiKey'}, body: jsonEncode(requestBody)).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) return jsonDecode(response.body)['choices'][0]['message']['content'];
      else if (response.statusCode == 429) throw Exception('RATE_LIMIT');
      else throw Exception('Groq Error: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> parseNotificationPdf(File pdfFile, String userApiKey, String provider) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final pdfText = await compute(_processPdfInIsolate, bytes);
      if (pdfText.isEmpty) throw Exception('No readable text found in this PDF.');

      String rawText = await _callDualEngineAi(
          "You are a precise data extractor for Indian Government Job Notifications. Output ONLY valid JSON starting with { and ending with }.",
          '''
          Analyze the following text extracted from a recruitment PDF. 
          Return ONLY a valid JSON object with these exact keys. Do not include markdown formatting, backticks, or conversational text. 
          If a date is not found, make it null. Use format "yyyy-MM-dd" for dates.
          
          Keys to return:
          - "examName": Combine the Organization and the Exam/Post.
          - "advertisementNo": Advt. No., CEN No., or Notice No.
          - "portalUrl": The official website link to apply online.
          - "appStartDate": Date of commencement of online registration.
          - "appEndDate": Closing date of online application.
          - "examDate": Tentative Date for Prelims / CBT 1. If only a month and year are given, use the first day: "2026-08-01". If not found, null.
          - "notes": Write exactly 2 clear sentences. 
              Sentence 1: State the Age Limit and core Educational Qualification. 
              Sentence 2: State the Application Fee amounts.

          TEXT TO ANALYZE:
          $pdfText
        ''',
          userApiKey,
          provider
      );

      rawText = rawText.replaceAll('```json', '').replaceAll('```JSON', '').replaceAll('```', '').trim();
      final int startIndex = rawText.indexOf('{');
      final int endIndex = rawText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) rawText = rawText.substring(startIndex, endIndex + 1);

      return jsonDecode(rawText) as Map<String, dynamic>;

    } catch (e) {
      debugPrint('AI Parse Error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}