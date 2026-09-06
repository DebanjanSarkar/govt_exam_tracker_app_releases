import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../data/models/exam_model.dart';
import 'ai_client_service.dart'; // NEW IMPORT

String _extractSyllabusPages(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(document);
  final int pageCount = document.pages.count;
  String syllabusContext = '';

  for (int i = 0; i < pageCount; i++) {
    String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i).toLowerCase();
    if (pageText.contains('scheme of examination') || pageText.contains('exam pattern') || pageText.contains('indicative syllabus') || pageText.contains('syllabus for') || pageText.contains('structure of examination')) {
      int endPage = (i + 3 < pageCount) ? i + 3 : pageCount - 1;
      for (int j = i; j <= endPage; j++) {
        syllabusContext += '--- PAGE ${j+1} ---\n';
        syllabusContext += extractor.extractText(startPageIndex: j, endPageIndex: j, layoutText: true) + '\n\n';
      }
      i = endPage;
    }
    if (syllabusContext.length > 24000) {
      syllabusContext = syllabusContext.substring(0, 24000);
      break;
    }
  }
  document.dispose();
  return syllabusContext;
}

class SyllabusParserService {
  static Future<String> _fetchWebSyllabus(String examName, String? targetPost) async {
    final query = "$examName ${targetPost ?? ''} detailed syllabus chapter wise topics list 2026";
    final searchUrl = Uri.parse('https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');
    try {
      final searchRes = await http.get(searchUrl, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 10));
      String liveContext = '';
      if (searchRes.statusCode == 200) {
        final regExp = RegExp(r'class="result__snippet[^>]*>(.*?)</a>', dotAll: true);
        final matches = regExp.allMatches(searchRes.body);
        for (var m in matches.take(6)) liveContext += m.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '') + '\n';
      }
      return liveContext;
    } catch (e) {
      return "No web context available.";
    }
  }

  static Future<Map<String, dynamic>?> generateSyllabusAndPattern(File pdfFile, ExamModel exam, String userApiKey, String provider) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final pdfContext = await compute(_extractSyllabusPages, bytes);
      final webContext = await _fetchWebSyllabus(exam.examName, exam.targetPost);

      List<String> activeStages = ['Prelims'];
      if (exam.hasMains) activeStages.add('Mains');
      if (exam.hasSkillTest) activeStages.add('Skill Test');
      if (exam.hasInterview) activeStages.add('Interview');

      // USE THE NEW MODULAR CLIENT
      String rawText = await AiClientService.callAi(
        systemPrompt: "You are a master curriculum extractor for Government Exams. Output ONLY valid JSON.",
        userPrompt: '''
          I am providing the official PDF text and live web search results for: "${exam.examName}".
          ${exam.targetPost != null && exam.targetPost!.isNotEmpty ? "CRITICAL: The user applied for: '${exam.targetPost}'. Extract syllabus ONLY for this post." : ""}
          
          Stages: ${activeStages.join(', ')}.

          RULES:
          1. "examPatternData" groups by Stage. List the sections/subjects, questions, and total marks.
          2. "syllabusData" groups by Stage, then by Subject. Under each subject, list detailed topics. 
          3. EVERY topic MUST be an object: {"topic": "Algebra", "completed": false}.

          JSON STRUCTURE:
          {
            "examPatternData": { "Prelims": [{"subject": "Math", "questions": "25", "marks": "50"}] },
            "syllabusData": { "Prelims": { "Math": [{"topic": "Algebra", "completed": false}] } }
          }

          --- OFFICIAL PDF TEXT ---
          $pdfContext

          --- WEB SEARCH SYLLABUS TEXT ---
          $webContext
        ''',
        userApiKey: userApiKey,
        provider: provider,
        temperature: 0.1,
      );

      rawText = rawText.replaceAll('```json', '').replaceAll('```JSON', '').replaceAll('```', '').trim();
      final int startIndex = rawText.indexOf('{');
      final int endIndex = rawText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) rawText = rawText.substring(startIndex, endIndex + 1);

      return jsonDecode(rawText) as Map<String, dynamic>;

    } catch (e) {
      debugPrint('Syllabus AI Parse Error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}