import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';
import '../config/secrets.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final String apiKey = openAiApiKey;

  final List<_ChatMessage> _messages = [
    _ChatMessage(text: 'Hi! I\'m your AI Study Assistant. Ask me anything 📚', isBot: true),
  ];

  bool _isTyping = false;

  Future<String> _getAIResponse(String input) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {"role": "system", "content": "You are a smart and friendly student assistant. Help with studying, explaining concepts, creating notes, solving doubts, and giving exam strategies. Keep answers clear and structured."},
            {"role": "user", "content": input},
          ],
          "temperature": 0.7,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['choices'][0]['message']['content'].trim();
      }
      return "⚠️ Error: Unable to fetch response.";
    } catch (e) {
      return "📵 You're offline or the AI service is unreachable.";
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false));
      _controller.clear();
      _isTyping = true;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();

    final reply = await _getAIResponse(text);
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(text: reply, isBot: true));
    });
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kAmber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: kAmber, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Study Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Powered by GPT-4o mini', style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
          ]),
        ]),
      ),
      body: Column(children: [
        // ── Messages ─────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (_isTyping && i == _messages.length) {
                // Typing indicator
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? kDarkCard : kPrimaryLight.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16), topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _TypingDot(delay: 0),
                      const SizedBox(width: 4),
                      _TypingDot(delay: 200),
                      const SizedBox(width: 4),
                      _TypingDot(delay: 400),
                    ]),
                  ),
                );
              }
              final msg = _messages[i];
              return Align(
                alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: msg.isBot
                        ? (isDark ? kDarkCard : kPrimaryLight.withOpacity(0.55))
                        : kPrimary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isBot ? 4 : 16),
                      bottomRight: Radius.circular(msg.isBot ? 16 : 4),
                    ),
                    border: msg.isBot
                        ? Border.all(color: kPrimary.withOpacity(isDark ? 0.2 : 0.15))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: (msg.isBot ? kPrimary : kPrimary).withOpacity(0.08),
                        blurRadius: 8, offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isBot
                          ? (isDark ? Colors.white : const Color(0xFF2A2A3D))
                          : Colors.white,
                      fontSize: 14, height: 1.45,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Input bar ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: isDark ? kDarkCard : Colors.white,
            border: Border(top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.07) : kPrimary.withOpacity(0.1))),
            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Ask anything about your studies...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton.small(
              onPressed: _sendMessage,
              backgroundColor: kPrimary,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  _ChatMessage({required this.text, required this.isBot});
}
