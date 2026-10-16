import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/ai_provider.dart';

class ChatService extends ChangeNotifier {
  final List<Message> messages = [];
  bool isLoading = false;
  String? error;

  void clearMessages() {
    messages.clear();
    error = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text, AiProvider provider) async {
    if (text.trim().isEmpty) return;

    final userMessage = Message(
      id: const Uuid().v4(),
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );
    messages.add(userMessage);
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _callApi(provider, text.trim());
      final assistantMessage = Message(
        id: const Uuid().v4(),
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
        modelName: provider.name,
      );
      messages.add(assistantMessage);
    } catch (e) {
      error = e.toString();
      messages.add(Message(
        id: const Uuid().v4(),
        role: 'assistant',
        content: 'خطا: $e',
        timestamp: DateTime.now(),
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _callApi(AiProvider provider, String userText) async {
    if (provider.apiKey.isEmpty) {
      throw Exception('لطفاً ابتدا API Key را در تنظیمات وارد کنید');
    }

    // ساخت تاریخچه برای context
    final history = messages
        .where((m) => m.role == 'user' || m.role == 'assistant')
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    // اگر Gemini باشد
    if (provider.id == 'gemini' || provider.baseUrl.contains('generativelanguage.googleapis.com')) {
      return await _callGemini(provider, history);
    }

    // در غیر اینصورت OpenAI-compatible
    return await _callOpenAICompatible(provider, history);
  }

  Future<String> _callGemini(AiProvider provider, List<Map<String, String>> history) async {
    final url = Uri.parse(
      '${provider.baseUrl}/models/${provider.model}:generateContent?key=${provider.apiKey}',
    );

    final contents = history.map((m) {
      return {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': m['content']}]
      };
    }).toList();

    final body = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 8192,
      },
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] ?? 'پاسخی دریافت نشد';
  }

  Future<String> _callOpenAICompatible(AiProvider provider, List<Map<String, String>> history) async {
    final url = Uri.parse('${provider.baseUrl}/chat/completions');

    final body = {
      'model': provider.model,
      'messages': [
        {
          'role': 'system',
          'content': 'تو یک دستیار برنامه‌نویسی هستی. کد را تمیز، خوانا و با توضیحات فارسی بنویس. اگر کاربر خواست فایل بساز، کد کامل را در بلوک markdown بده.',
        },
        ...history,
      ],
      'temperature': 0.7,
      'max_tokens': 8192,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${provider.apiKey}',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] ?? 'پاسخی دریافت نشد';
  }
}
