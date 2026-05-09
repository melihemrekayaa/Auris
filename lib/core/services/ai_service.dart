import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/word_timestamp.dart';

class AIService {
  final String _groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final String _elevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';

  /// Sends the scraped text to Groq (Llama 3) to generate a podcast dialogue.
  Future<String> generatePodcastScript(String articleText) async {
    if (_groqKey.isEmpty) {
      throw Exception('Groq API Key is missing. Please add it to .env');
    }

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqKey',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant', // Updated to the latest supported Llama 3.1 model
        'messages': [
          {
            'role': 'system',
            'content': '''You are a professional, engaging podcast host. Turn the following article text into a short, compelling 1-person podcast monologue. 
Make it sound natural, conversational, and interesting. Keep it under 500 words.
CRITICAL RULES:
1. DETECT the language of the source article. You MUST write the podcast script in the EXACT SAME LANGUAGE as the source article.
2. DO NOT include any stage directions (e.g., *pause*, [laughs], (sighs), etc).
3. DO NOT include any speaker labels or brackets.
4. ONLY write the exact words that will be spoken out loud. Nothing else.
'''
          },
          {
            'role': 'user',
            'content': articleText
          }
        ],
        'temperature': 0.7,
        'max_tokens': 400, // ~200 kelime = ~400 token = ~1200 karakter (ElevenLabs tasarrufu)
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to generate script via Groq: ${response.body}');
    }
  }

  /// Sends the script to ElevenLabs to generate an mp3 audio stream along with timestamps.
  /// Returns both the audio bytes and the word-level timestamps.
  Future<AudioGenerationResult> generateAudio(String script) async {
    if (_elevenLabsKey.isEmpty || _elevenLabsKey == 'your_elevenlabs_api_key_here') {
      throw Exception('ElevenLabs API Key is missing. Please add it to .env');
    }

    // Kullanıcının oluşturduğu özel sesin ID'sini .env dosyasından çekiyoruz
    final voiceId = dotenv.env['ELEVENLABS_VOICE_ID'] ?? '21m00Tcm4TlvDq8ikWAM'; 
    // YENİ: with-timestamps uç noktasını kullanıyoruz
    final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId/with-timestamps');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json', // Artık direkt mpeg değil JSON dönmesini istiyoruz
        'xi-api-key': _elevenLabsKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': script,
        'model_id': 'eleven_multilingual_v2', // Updated to multilingual model to support Turkish and 28 other languages
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.75 // Slightly higher similarity boost works better for multilingual
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // 1. Sesi base64'ten çöz (decode)
      final String base64Audio = data['audio_base64'];
      final List<int> audioBytes = base64Decode(base64Audio);

      // 2. Karakter hizalamalarını (alignment) kelimelere çevir
      final alignment = data['alignment'];
      final List<dynamic> chars = alignment['characters'];
      final List<dynamic> startTimes = alignment['character_start_times_seconds'];
      final List<dynamic> endTimes = alignment['character_end_times_seconds'];

      List<WordTimestamp> wordTimestamps = [];
      String currentWord = '';
      double? wordStart;
      double? wordEnd;

      for (int i = 0; i < chars.length; i++) {
        final char = chars[i].toString();
        final start = (startTimes[i] as num).toDouble();
        final end = (endTimes[i] as num).toDouble();

        if (char.trim().isEmpty) {
          // Boşluk karakteriyse mevcut kelimeyi listeye ekle
          if (currentWord.trim().isNotEmpty && wordStart != null && wordEnd != null) {
            wordTimestamps.add(WordTimestamp(word: currentWord, startTime: wordStart, endTime: wordEnd));
          }
          currentWord = '';
          wordStart = null;
          wordEnd = null;
        } else {
          // Karakter biriktir ve başlangıç zamanını sadece ilk harfte kaydet
          if (currentWord.isEmpty) {
            wordStart = start;
          }
          currentWord += char;
          wordEnd = end;
        }
      }

      // Döngü bittiğinde elde kalan son kelimeyi de ekle
      if (currentWord.trim().isNotEmpty && wordStart != null && wordEnd != null) {
        wordTimestamps.add(WordTimestamp(word: currentWord, startTime: wordStart, endTime: wordEnd));
      }

      return AudioGenerationResult(audioBytes: audioBytes, wordTimestamps: wordTimestamps);
    } else {
      throw Exception('Failed to generate audio: ${response.body}');
    }
  }
}
