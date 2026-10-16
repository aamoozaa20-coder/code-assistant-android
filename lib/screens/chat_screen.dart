import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveCodeToFile(String content) async {
    try {
      final codeRegex = RegExp(r'```(?:\w+)?\n([\s\S]*?)```');
      final match = codeRegex.firstMatch(content);
      final code = match != null ? match.group(1)!.trim() : content;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'code_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فایل ذخیره شد: $fileName'),
            backgroundColor: const Color(0xFF22C55E),
            action: SnackBarAction(
              label: 'کپی',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره‌سازی: $e')),
        );
      }
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('کپی شد'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF22C55E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatService, SettingsService>(
      builder: (context, chat, settings, _) {
        _scrollToBottom();

        return Column(
          children: [
            Expanded(
              child: chat.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'چی کدی می‌خوای برات بنویسم؟',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'مثال: یک تابع فیبوناچی بنویس',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.3)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final message = chat.messages[index];
                        return _MessageBubble(
                          message: message,
                          onSave: () => _saveCodeToFile(message.content),
                          onCopy: () => _copyText(message.content),
                        );
                      },
                    ),
            ),

            if (chat.isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(width: 16),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('در حال نوشتن...',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'پیام خود را بنویسید...',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: chat.isLoading
                          ? null
                          : () {
                              final text = _controller.text;
                              _controller.clear();
                              chat.sendMessage(
                                  text, settings.selectedProvider);
                            },
                      icon:
                          const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback onSave;
  final VoidCallback onCopy;

  const _MessageBubble({
    required this.message,
    required this.onSave,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.modelName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  message.modelName!,
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ),
            // متن قابل انتخاب و کپی
            SelectionArea(
              child: isUser
                  ? Text(
                      message.content,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 15),
                    )
                  : MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white, fontSize: 15),
                        code: const TextStyle(
                          backgroundColor: Color(0xFF0F172A),
                          color: Color(0xFF22D3EE),
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ),
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded,
                        size: 16, color: Colors.white54),
                    label: const Text('کپی',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_alt_rounded,
                        size: 16, color: Colors.white54),
                    label: const Text('ذخیره فایل',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
