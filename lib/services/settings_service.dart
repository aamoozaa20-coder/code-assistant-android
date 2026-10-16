import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider.dart';

class SettingsService extends ChangeNotifier {
  List<AiProvider> providers = List.from(defaultProviders);
  String selectedProviderId = 'gemini';
  bool isLoaded = false;

  SettingsService() {
    load();
  }

  AiProvider get selectedProvider {
    return providers.firstWhere(
      (p) => p.id == selectedProviderId,
      orElse: () => providers.first,
    );
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final providersJson = prefs.getString('providers');
    if (providersJson != null) {
      final list = jsonDecode(providersJson) as List;
      providers = list.map((e) => AiProvider.fromJson(e)).toList();
    }
    selectedProviderId = prefs.getString('selectedProviderId') ?? 'gemini';
    isLoaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'providers',
      jsonEncode(providers.map((e) => e.toJson()).toList()),
    );
    await prefs.setString('selectedProviderId', selectedProviderId);
  }

  void selectProvider(String id) {
    selectedProviderId = id;
    save();
    notifyListeners();
  }

  void updateProvider(AiProvider provider) {
    final index = providers.indexWhere((p) => p.id == provider.id);
    if (index != -1) {
      providers[index] = provider;
      save();
      notifyListeners();
    }
  }

  void addCustomProvider(AiProvider provider) {
    providers.add(provider);
    save();
    notifyListeners();
  }

  void removeProvider(String id) {
    providers.removeWhere((p) => p.id == id && p.isCustom);
    if (selectedProviderId == id) {
      selectedProviderId = providers.first.id;
    }
    save();
    notifyListeners();
  }
}
