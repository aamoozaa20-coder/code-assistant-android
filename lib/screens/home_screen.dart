import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.code_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'کدیار هوشمند',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'نوشتن کد و ساخت فایل با AI',
                          style: TextStyle(fontSize: 13, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Provider selector
            Consumer<SettingsService>(
              builder: (context, settings, _) {
                if (!settings.isLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: settings.providers.length,
                    itemBuilder: (context, index) {
                      final provider = settings.providers[index];
                      final isSelected = provider.id == settings.selectedProviderId;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(provider.name),
                          selected: isSelected,
                          onSelected: (_) => settings.selectProvider(provider.id),
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: const Color(0xFF1E293B),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Chat area
            const Expanded(child: ChatScreen()),
          ],
        ),
      ),
    );
  }
}
