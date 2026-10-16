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
      final response = await _callApi(provider);
      final assistantMessage = Message(
        id: const Uuid().v4(),
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
        modelName: provider.model.isNotEmpty ? provider.model : provider.name,
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

  Future<String> _callApi(AiProvider provider) async {
    if (provider.apiKey.trim().isEmpty) {
      throw Exception('لطفاً ابتدا API Key را در تنظیمات وارد کنید');
    }
    if (provider.model.trim().isEmpty) {
      throw Exception(
          'نام مدل خالی است. در تنظیمات روی «دریافت مدل‌ها» بزن یا دستی بنویس');
    }

    final history = messages
        .where((m) => m.role == 'user' || m.role == 'assistant')
        .where((m) => !m.content.startsWith('خطا:'))
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    if (provider.id == 'gemini' ||
        provider.baseUrl.contains('generativelanguage.googleapis.com')) {
      return await _callGemini(provider, history);
    }

    return await _callOpenAICompatible(provider, history);
  }

  String _cleanBaseUrl(String url) {
    var cleaned = url.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  Future<String> _callGemini(
      AiProvider provider, List<Map<String, String>> history) async {
    final base = _cleanBaseUrl(provider.baseUrl);
    final url = Uri.parse(
      '$base/models/${provider.model}:generateContent?key=${provider.apiKey}',
    );

    final contents = history.map((m) {
      return {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': m['content']}
        ]
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
      throw Exception(
          'Gemini Error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    try {
      return data['candidates'][0]['content']['parts'][0]['text'] ??
          'پاسخی دریافت نشد';
    } catch (_) {
      throw Exception('پاسخ نامعتبر: ${response.body}');
    }
  }

  Future<String> _callOpenAICompatible(
      AiProvider provider, List<Map<String, String>> history) async {
    final base = _cleanBaseUrl(provider.baseUrl);
    final url = Uri.parse('$base/chat/completions');

    final body = {
      'model': provider.model,
      'messages': [
        {
          'role': 'system',
          'content':
              'تو یک دستیار برنامه‌نویسی هستی. کد را تمیز، خوانا و با توضیحات فارسی بنویس. اگر کاربر خواست فایل بساز، کد کامل را در بلوک markdown بده.',
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
      throw Exception(
          'API Error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    try {
      return data['choices'][0]['message']['content'] ?? 'پاسخی دریافت نشد';
    } catch (_) {
      throw Exception('پاسخ نامعتبر: ${response.body}');
    }
  }

  /// مدل‌های پیش‌فرض برای سرویس‌های معروف
  static List<String> knownModelsFor(String baseUrl) {
    final u = baseUrl.toLowerCase();
    if (u.contains('apmix.ai')) {
      return [
        'claude-sonnet-4-6-free',
        'claude-sonnet-4-6',
        'claude-sonnet-5',
        'gpt-5.6-luna',
        'deepseek-v4.1-flash',
        'glm-5.3-flash',
      ];
    }
    if (u.contains('groq.com')) {
      return [
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant',
        'mixtral-8x7b-32768',
        'gemma2-9b-it',
      ];
    }
    if (u.contains('openrouter.ai')) {
      return [
        'google/gemini-2.0-flash-exp:free',
        'meta-llama/llama-3.2-3b-instruct:free',
        'qwen/qwen-2.5-7b-instruct:free',
      ];
    }
    return [];
  }

  /// دریافت لیست مدل‌ها از API
  static Future<List<String>> fetchModels(String baseUrl, String apiKey) async {
    if (baseUrl.trim().isEmpty) {
      throw Exception('Base URL خالی است');
    }
    if (apiKey.trim().isEmpty) {
      throw Exception('API Key خالی است');
    }

    var cleaned = baseUrl.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    // امتحان چند مسیر مختلف
    final candidates = [
      '$cleaned/models',
      '$cleaned/v1/models',
    ];
    // اگر خودش /v1 دارد، دوباره نکن
    if (cleaned.endsWith('/v1')) {
      candidates.remove('$cleaned/v1/models');
    }

    Exception? lastError;

    for (final endpoint in candidates) {
      try {
        final url = Uri.parse(endpoint);
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception(
              'کلید API اشتباه یا مجاز نیست (${response.statusCode})');
        }

        if (response.statusCode != 200) {
          lastError = Exception(
              'خطا ${response.statusCode}: ${response.body}');
          continue;
        }

        final data = jsonDecode(response.body);
        final List models = data['data'] ?? data['models'] ?? [];

        final List<String> ids = [];
        for (final m in models) {
          if (m is Map && m['id'] != null) {
            ids.add(m['id'].toString());
          } else if (m is String) {
            ids.add(m);
          }
        }

        if (ids.isEmpty) {
          // اگر API چیزی برنگردوند، از لیست معروف استفاده کن
          final known = knownModelsFor(baseUrl);
          if (known.isNotEmpty) return known;
          throw Exception('لیست مدل خالی بود');
        }

        ids.sort();
        return ids;
      } catch (e) {
        if (e is Exception &&
            (e.toString().contains('کلید API') ||
                e.toString().contains('اشتباه'))) {
          rethrow;
        }
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    // فالبک: مدل‌های معروف
    final known = knownModelsFor(baseUrl);
    if (known.isNotEmpty) {
      return known;
    }

    throw lastError ??
        Exception(
            'نتوانستم لیست مدل‌ها را بگیرم. اینترنت یا VPN را بررسی کن');
  }
}
