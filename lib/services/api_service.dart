import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/medical_case.dart';
import 'database_service.dart';

class AiService {
  // 🔴 REPLACE WITH YOUR KEY

  static String groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static final String _apiKey = groqKey;

  static const String _baseUrl = 'https://api.groq.com/openai/v1';

  static Future<MedicalCase> generateCaseReport(String audioPath) async {
    try {
      // 1. Transcribe (Auto-detects Hindi, Tamil, Telugu, etc.)
      final transcript = await _transcribeAudio(audioPath);

      // 2. Analyze & Translate to English SOAP
      final jsonMap = await _analyzeText(transcript);

      // 3. Create Model
      final newCase = MedicalCase(
        patientName: "Patient ${DateTime.now().hour}:${DateTime.now().minute}",
        date: DateTime.now(),
        audioPath: audioPath,
        transcript: transcript, // This might be in Hindi/Mix
        subjective: _clean(jsonMap['subjective']), // This will be English
        objective: _clean(jsonMap['objective']), // This will be English
        assessment: _clean(jsonMap['assessment']), // This will be English
        plan: _clean(jsonMap['plan']), // This will be English
      );

      // 4. Save to DB
      await DatabaseService().insertCase(newCase);

      return newCase;
    } catch (e) {
      throw Exception("AI Generation Failed: $e");
    }
  }

  static String _clean(dynamic val) {
    if (val == null) return "Not Mentioned";
    return val.toString().replaceAll(RegExp(r'[*#]'), '');
  }

  static Future<String> _transcribeAudio(String path) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/audio/transcriptions'),
    );
    request.headers['Authorization'] = 'Bearer $_apiKey';
    request.fields['model'] = 'whisper-large-v3';

    // 🔴 IMPORTANT CHANGE:
    // We REMOVED "request.fields['language'] = 'en';"
    // Now Whisper will auto-detect if you are speaking Hindi, Tamil, etc.

    request.files.add(await http.MultipartFile.fromPath('file', path));

    final res = await request.send();
    final response = await http.Response.fromStream(res);

    if (response.statusCode == 200) {
      // Decode with UTF8 to support Indian characters
      return jsonDecode(utf8.decode(response.bodyBytes))['text'];
    }
    throw Exception('Transcription failed: ${response.body}');
  }

  static Future<Map<String, dynamic>> _analyzeText(String text) async {
    // 🔴 ENGINEERED PROMPT FOR INDIAN CONTEXT
    final systemPrompt = """
    You are an expert Medical Scribe for an Indian Hospital. 
    The doctor's consultation transcript provided below may be in **Hindi, Tamil, Telugu, Kannada, Malayalam, Marathi, or a mix of English (Hinglish)**.
    
    YOUR TASK:
    1. **TRANSLATE** all non-English speech into professional **Clinical English**.
    2. Extract specific medical facts for the SOAP Note.
    3. If the doctor uses local terms (e.g., "Pet dard" -> Abdominal Pain, "Chakkar" -> Vertigo/Dizziness), translate them to medical terminology.
    4. RETURN JSON ONLY.
    
    JSON STRUCTURE:
    {
      "subjective": "Chief complaint and history (Translated to English)",
      "objective": "Vitals and observations (Translated to English)",
      "assessment": "Diagnosis (Translated to English)",
      "plan": "Medications and advice (Translated to English)"
    }
    """;

    final res = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json; charset=utf-8', // Ensure UTF-8
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "temperature": 0.1, // Low temp for accurate translation
        "response_format": {"type": "json_object"},
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": text},
        ],
      }),
    );

    if (res.statusCode == 200) {
      final content = jsonDecode(
        utf8.decode(res.bodyBytes),
      )['choices'][0]['message']['content'];
      return jsonDecode(content);
    }
    throw Exception('Analysis failed: ${res.body}');
  }
}
