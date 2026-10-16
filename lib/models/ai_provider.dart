class AiProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String model;
  final bool isCustom;

  AiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
        'isCustom': isCustom,
      };

  factory AiProvider.fromJson(Map<String, dynamic> json) => AiProvider(
        id: json['id'],
        name: json['name'],
        baseUrl: json['baseUrl'],
        apiKey: json['apiKey'],
        model: json['model'],
        isCustom: json['isCustom'] ?? false,
      );

  AiProvider copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
  }) {
    return AiProvider(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      isCustom: isCustom,
    );
  }
}

// مدل‌های پیش‌فرض
final List<AiProvider> defaultProviders = [
  AiProvider(
    id: 'gemini',
    name: 'Google Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    apiKey: '',
    model: 'gemini-2.0-flash',
  ),
  AiProvider(
    id: 'groq',
    name: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    apiKey: '',
    model: 'llama-3.3-70b-versatile',
  ),
  AiProvider(
    id: 'openrouter',
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    apiKey: '',
    model: 'google/gemini-2.0-flash-exp:free',
  ),
];
