import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../constants/app_constants.dart';

// 1. ISOLATE: Hunts specifically for Syllabus and Exam Pattern pages in the PDF
String _extractSyllabusPages(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(document);
  final int pageCount = document.pages.count;

  String syllabusContext = '';

  for (int i = 0; i < pageCount; i++) {
    // Fast scan
    String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i).toLowerCase();

    // If we find syllabus or exam scheme keywords, we extract this page and the next 3 pages!
    if (pageText.contains('scheme of examination') ||
        pageText.contains('exam pattern') ||
        pageText.contains('indicative syllabus') ||
        pageText.contains('syllabus for') ||
        pageText.contains('structure of examination')) {

      int endPage = (i + 3 < pageCount) ? i + 3 : pageCount - 1;

      for (int j = i; j <= endPage; j++) {
        // Use layoutText: true to keep the Marks & Questions tables intact!
        syllabusContext += '--- PAGE ${j+1} ---\n';
        syllabusContext += extractor.extractText(startPageIndex: j, endPageIndex: j, layoutText: true) + '\n\n';
      }

      i = endPage; // Skip ahead to avoid duplicating pages
    }

    // Safety cap at ~6,000 tokens
    if (syllabusContext.length > 24000) {
      syllabusContext = syllabusContext.substring(0, 24000);
      break;
    }
  }

  document.dispose();
  return syllabusContext;
}

class SyllabusParserService {

  // 2. WEB RAG: Scrapes the internet for detailed chapter-wise topics
  static Future<String> _fetchWebSyllabus(String examName) async {
    final query = "$examName detailed syllabus chapter wise topics list 2026";
    final searchUrl = Uri.parse('https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');

    try {
      final searchRes = await http.get(searchUrl, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }).timeout(const Duration(seconds: 10));

      String liveContext = '';
      if (searchRes.statusCode == 200) {
        final regExp = RegExp(r'class="result__snippet[^>]*>(.*?)</a>', dotAll: true);
        final matches = regExp.allMatches(searchRes.body);
        for (var m in matches.take(8)) {
          liveContext += m.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '') + '\n';
        }
      }
      return liveContext;
    } catch (e) {
      return "No web context available.";
    }
  }

  // 3. THE HYBRID ENGINE
  static Future<Map<String, dynamic>?> generateSyllabusAndPattern(File pdfFile, String examName, String userApiKey) async {
    try {
      // Step A: Extract PDF Tables
      final bytes = await pdfFile.readAsBytes();
      final pdfContext = await compute(_extractSyllabusPages, bytes);

      // Step B: Extract Web Data
      final webContext = await _fetchWebSyllabus(examName);

      // Step C: Send to Groq
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final requestBody = {
        "model": AppConstants.activeAiModel,
        "messages": [
          {
            "role": "system",
            "content": "You are a master curriculum extractor for Government Exams. Output ONLY valid JSON starting with { and ending with }."
          },
          {
            "role": "user",
            "content": '''
              I am providing you with the official PDF text of the exam pattern, and live web search results for the syllabus.
              Merge them into a highly accurate JSON structure.

              RULES:
              1. "examPatternData" must group by Stage (e.g., "Prelims", "Mains"). Each stage must list the sections/subjects, the number of questions, and the total marks.
              2. "syllabusData" must group by Stage, then by Subject. Under each subject, provide a list of detailed topics to study. 
              3. EVERY topic in the syllabus MUST be an object with the key "topic" (String) and "completed" (Boolean set to false).

              JSON STRUCTURE TO STRICTLY FOLLOW:
              {
                "examPatternData": {
                  "Prelims": [
                    {"subject": "General Intelligence", "questions": "25", "marks": "50"},
                    {"subject": "Quantitative Aptitude", "questions": "25", "marks": "50"}
                  ]
                },
                "syllabusData": {
                  "Prelims": {
                    "General Intelligence": [
                      {"topic": "Analogies", "completed": false},
                      {"topic": "Blood Relations", "completed": false}
                    ]
                  }
                }
              }

              --- OFFICIAL PDF TEXT ---
              $pdfContext

              --- WEB SEARCH SYLLABUS TEXT ---
              $webContext
            '''
          }
        ],
        "temperature": 0.1
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $userApiKey'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30), onTimeout: () => throw Exception('TIMEOUT'));

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
          throw Exception('Failed to parse AI response. It did not return valid JSON.');
        }
      } else if (response.statusCode == 429) {
        throw Exception('RATE_LIMIT');
      } else {
        throw Exception('API Server Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Syllabus AI Parse Error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}