import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../constants/app_constants.dart';

String _processPdfInIsolate(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(document);
  final int pageCount = document.pages.count;

  String coreInfo = '';
  String dateInfo = '\n--- DATES ---\n';
  String feeInfo = '\n--- FEES ---\n';
  String eligibilityInfo = '\n--- ELIGIBILITY ---\n';
  String selectionProcessInfo = '\n--- SELECTION PROCESS ---\n';

  int dateChars = 0;
  int feeChars = 0;
  int eligibilityChars = 0;
  int selectionChars = 0;

  const int limitPerCategory = 2500;

  int corePages = pageCount > 3 ? 3 : pageCount;
  for (int i = 0; i < corePages; i++) {
    coreInfo += extractor.extractText(startPageIndex: i, endPageIndex: i) + '\n\n';
  }

  if (pageCount > 3) {
    for (int i = 3; i < pageCount; i++) {
      if (dateChars >= limitPerCategory && feeChars >= limitPerCategory && eligibilityChars >= limitPerCategory && selectionChars >= limitPerCategory) {
        break;
      }

      String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      List<String> lines = pageText.split('\n');

      for (int j = 0; j < lines.length; j++) {
        String lowerLine = lines[j].toLowerCase();

        bool isDate = lowerLine.contains('opening date') || lowerLine.contains('closing date') || lowerLine.contains('last date') || lowerLine.contains('tentative date');
        bool isFee = lowerLine.contains('application fee') || lowerLine.contains('examination fee') || lowerLine.contains('intimation charges') || lowerLine.contains('fee : rs') || lowerLine.contains('non-refundable');
        bool isElig = lowerLine.contains('age limit') || lowerLine.contains('educational qualification') || lowerLine.contains('essential qualification') || lowerLine.contains('eligibility criteria');
        bool isSelection = lowerLine.contains('scheme of examination') || lowerLine.contains('selection process') || lowerLine.contains('tier-ii') || lowerLine.contains('cbt-2') || lowerLine.contains('interview') || lowerLine.contains('skill test');

        if (isDate || isFee || isElig || isSelection) {
          int start = (j - 1 < 0) ? 0 : j - 1;
          int end = (j + 5 >= lines.length) ? lines.length - 1 : j + 5;
          String contextBlock = lines.sublist(start, end + 1).join(' ') + '\n\n';

          if (isDate && dateChars < limitPerCategory) {
            dateInfo += contextBlock; dateChars += contextBlock.length; j = end;
          } else if (isFee && feeChars < limitPerCategory) {
            feeInfo += contextBlock; feeChars += contextBlock.length; j = end;
          } else if (isElig && eligibilityChars < limitPerCategory) {
            eligibilityInfo += contextBlock; eligibilityChars += contextBlock.length; j = end;
          } else if (isSelection && selectionChars < limitPerCategory) {
            selectionProcessInfo += contextBlock; selectionChars += contextBlock.length; j = end;
          }
        }
      }
    }
  }

  document.dispose();
  String finalContext = coreInfo + dateInfo + feeInfo + eligibilityInfo + selectionProcessInfo;
  const int maxChars = 14000;
  if (finalContext.length > maxChars) finalContext = finalContext.substring(0, maxChars);
  return finalContext;
}

class AiParserService {
  static Future<Map<String, dynamic>?> parseNotificationPdf(File pdfFile, String userApiKey) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final pdfText = await compute(_processPdfInIsolate, bytes);

      if (pdfText.isEmpty) throw Exception('No readable text found in this PDF.');

      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final requestBody = {
        "model": AppConstants.activeAiModel,
        "messages": [
          {
            "role": "system",
            "content": "You are a precise data extractor. Output ONLY valid JSON starting with { and ending with }."
          },
          {
            "role": "user",
            "content": '''
              Analyze the following text extracted from a recruitment PDF. 
              Return ONLY a valid JSON object. If a date is not found, make it null. Use format "yyyy-MM-dd".
              
              Keys to return:
              - "examName": Combine the Organization and the Exam/Post.
              - "advertisementNo": Advt. No., CEN No., or Notice No.
              - "portalUrl": Official website link to apply.
              - "appStartDate": Date of commencement of online registration.
              - "appEndDate": Closing date of online application.
              - "examDate": Tentative Date for Prelims / CBT 1 / Phase-I.
              - "notes": 2 sentences. 1: Age & Education. 2: Exact Application Fee amounts.
              - "hasMains": Boolean. true if there is a Mains/Tier-2/CBT-2/Phase-II exam.
              - "hasSkillTest": Boolean. true if a skill test, typing test, physical test, or psycho test is mentioned.
              - "hasInterview": Boolean. true if interview or personality test is part of the selection.
              - "hasDV": Boolean. true if Document Verification is explicitly listed as a selection stage.

              TEXT TO ANALYZE:
              $pdfText
            '''
          }
        ],
        "temperature": 0.1
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $userApiKey'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 25), onTimeout: () => throw Exception('TIMEOUT'));

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          String rawText = jsonResponse['choices'][0]['message']['content'];
          rawText = rawText.replaceAll('```json', '').replaceAll('```JSON', '').replaceAll('```', '').trim();
          final int startIndex = rawText.indexOf('{');
          final int endIndex = rawText.lastIndexOf('}');
          if (startIndex != -1 && endIndex != -1) rawText = rawText.substring(startIndex, endIndex + 1);
          return jsonDecode(rawText) as Map<String, dynamic>;
        } catch (e) {
          throw Exception('Failed to parse AI response.');
        }
      } else if (response.statusCode == 429) {
        throw Exception('RATE_LIMIT');
      } else if (response.statusCode == 413) {
        throw Exception('PDF is too complex.');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API Key. Please check AI Settings.');
      } else {
        throw Exception('API Server Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AI Parse Error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}