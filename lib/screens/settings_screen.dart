import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/settings_service.dart';
import '../services/chat_service.dart';
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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ...settings.providers.map((provider) {
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text(provider.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      provider.apiKey.isEmpty
                          ? 'کلید API تنظیم نشده'
                          : (provider.model.isEmpty
                              ? 'مدل انتخاب نشده'
                              : 'مدل: ${provider.model}'),
                      style: TextStyle(
                        color: provider.apiKey.isEmpty
                            ? Colors.orange
                            : Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              color: Colors.white54),
                          onPressed: () =>
                              _showProviderDialog(context, settings, provider),
                        ),
                        if (provider.isCustom)
                          IconButton(
                            icon: const Icon(Icons.delete_rounded,
                                color: Colors.redAccent),
                            onPressed: () =>
                                settings.removeProvider(provider.id),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showProviderDialog(context, settings, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('اضافه کردن API سفارشی'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'توضیحات',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                '• برای Gemini: از Google AI Studio یک API Key رایگان بگیرید\n'
                '• برای Groq: از سایت groq.com کلید رایگان بگیرید\n'
                '• برای API سفارشی: Base URL + API Key را وارد کنید، سپس دکمه «دریافت مدل‌ها» را بزنید',
                style: TextStyle(color: Colors.white54, height: 1.6),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProviderDialog(
      BuildContext context, SettingsService settings, AiProvider? existing) {
    showDialog(
      context: context,
      builder: (ctx) => _ProviderDialog(
        settings: settings,
        existing: existing,
      ),
    );
  }
}

class _ProviderDialog extends StatefulWidget {
  final SettingsService settings;
  final AiProvider? existing;

  const _ProviderDialog({required this.settings, this.existing});

  @override
  State<_ProviderDialog> createState() => _ProviderDialogState();
}

class _ProviderDialogState extends State<_ProviderDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController urlCtrl;
  late final TextEditingController keyCtrl;
  late final TextEditingController modelCtrl;

  List<String> fetchedModels = [];
  bool isFetching = false;
  String? fetchError;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    nameCtrl = TextEditingController(text: p?.name ?? '');
    urlCtrl = TextEditingController(
        text: p?.baseUrl ?? 'https://api.apmix.ai/v1');
    keyCtrl = TextEditingController(text: p?.apiKey ?? '');
    modelCtrl = TextEditingController(text: p?.model ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    urlCtrl.dispose();
    keyCtrl.dispose();
    modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchModels() async {
    setState(() {
      isFetching = true;
      fetchError = null;
      fetchedModels = [];
    });

    try {
      final models = await ChatService.fetchModels(
        urlCtrl.text.trim(),
        keyCtrl.text.trim(),
      );
      setState(() {
        fetchedModels = models;
        isFetching = false;
        if (models.isEmpty) {
          fetchError = 'هیچ مدلی پیدا نشد';
        }
      });
    } catch (e) {
      setState(() {
        isFetching = false;
        fetchError = e.toString();
      });
    }
  }

  void _save() {
    final name = nameCtrl.text.trim();
    final url = urlCtrl.text.trim();
    final key = keyCtrl.text.trim();
    final model = modelCtrl.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام و Base URL الزامی هست')),
      );
      return;
    }

    if (widget.existing != null) {
      widget.settings.updateProvider(widget.existing!.copyWith(
        name: name,
        baseUrl: url,
        apiKey: key,
        model: model,
      ));
    } else {
      widget.settings.addCustomProvider(AiProvider(
        id: const Uuid().v4(),
        name: name,
        baseUrl: url,
        apiKey: key,
        model: model,
        isCustom: true,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text(
        isEdit ? 'ویرایش ${widget.existing!.name}' : 'اضافه کردن API سفارشی',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'نام نمایشی'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://api.apmix.ai/v1',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(labelText: 'API Key'),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: isFetching ? null : _fetchModels,
              icon: isFetching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_rounded),
              label: Text(isFetching ? 'در حال دریافت...' : 'دریافت مدل‌ها'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22D3EE),
                foregroundColor: Colors.black,
              ),
            ),
            if (fetchError != null) ...[
              const SizedBox(height: 8),
              Text(
                fetchError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
            if (fetchedModels.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'مدل‌های دریافت‌شده (یکی را انتخاب کنید):',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: fetchedModels.length,
                  itemBuilder: (context, index) {
                    final m = fetchedModels[index];
                    final selected = modelCtrl.text == m;
                    return ListTile(
                      dense: true,
                      title: Text(m,
                          style: TextStyle(
                            color: selected ? Colors.cyanAccent : Colors.white,
                            fontSize: 13,
                          )),
                      trailing: selected
                          ? const Icon(Icons.check, color: Colors.cyanAccent, size: 18)
                          : null,
                      onTap: () {
                        setState(() {
                          modelCtrl.text = m;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: modelCtrl,
              decoration: const InputDecoration(
                labelText: 'نام مدل',
                hintText: 'یا از لیست بالا انتخاب کنید یا دستی بنویسید',
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEdit ? 'ذخیره' : 'اضافه کردن'),
        ),
      ],
    );
  }
}
