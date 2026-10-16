import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/settings_service.dart';
import '../models/ai_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'مدل‌های موجود',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ...settings.providers.map((provider) {
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text(provider.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      provider.apiKey.isEmpty ? 'کلید API تنظیم نشده' : 'آماده استفاده',
                      style: TextStyle(
                        color: provider.apiKey.isEmpty ? Colors.orange : Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.white54),
                          onPressed: () => _showEditDialog(context, settings, provider),
                        ),
                        if (provider.isCustom)
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                            onPressed: () => settings.removeProvider(provider.id),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showAddCustomDialog(context, settings),
                icon: const Icon(Icons.add_rounded),
                label: const Text('اضافه کردن API سفارشی'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'توضیحات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                '• برای Gemini: از Google AI Studio یک API Key رایگان بگیرید\n'
                '• برای Groq: از سایت groq.com کلید رایگان بگیرید\n'
                '• برای API سفارشی: آدرس Base URL + API Key + نام مدل را وارد کنید',
                style: TextStyle(color: Colors.white54, height: 1.6),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, SettingsService settings, AiProvider provider) {
    final nameCtrl = TextEditingController(text: provider.name);
    final urlCtrl = TextEditingController(text: provider.baseUrl);
    final keyCtrl = TextEditingController(text: provider.apiKey);
    final modelCtrl = TextEditingController(text: provider.model);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('ویرایش ${provider.name}', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Base URL'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'API Key'), style: const TextStyle(color: Colors.white), obscureText: true),
              const SizedBox(height: 10),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'نام مدل'), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              settings.updateProvider(provider.copyWith(
                name: nameCtrl.text.trim(),
                baseUrl: urlCtrl.text.trim(),
                apiKey: keyCtrl.text.trim(),
                model: modelCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomDialog(BuildContext context, SettingsService settings) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'https://api.openai.com/v1');
    final keyCtrl = TextEditingController();
    final modelCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('اضافه کردن API سفارشی', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام نمایشی'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Base URL'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'API Key'), style: const TextStyle(color: Colors.white), obscureText: true),
              const SizedBox(height: 10),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'نام مدل'), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) return;
              settings.addCustomProvider(AiProvider(
                id: const Uuid().v4(),
                name: nameCtrl.text.trim(),
                baseUrl: urlCtrl.text.trim(),
                apiKey: keyCtrl.text.trim(),
                model: modelCtrl.text.trim(),
                isCustom: true,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('اضافه کردن'),
          ),
        ],
      ),
    );
  }
}
