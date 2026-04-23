// lib/screens/chatbot_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<_ChatMsg> _msgs    = [];
  final _ctrl                   = TextEditingController();
  final _scroll                 = ScrollController();
  final _sessionId              = 'mobile_${DateTime.now().millisecondsSinceEpoch}';
  bool _loading = false;

  static const _quickReplies = [
    'Cara daftar anggota?',
    'Jadwal latihan',
    'Tarian apa saja?',
    'Kontak sanggar',
    'Biaya pendaftaran?',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _msgs.add(const _ChatMsg(
      role:    'bot',
      content: 'Halo! Saya asisten virtual Sanggar Mulya Bhakti 🎭\n\n'
               'Saya siap membantu informasi tentang:\n'
               '• Jadwal latihan\n'
               '• Cara mendaftar anggota\n'
               '• Tarian yang diajarkan\n'
               '• Info sanggar lainnya\n\n'
               'Ada yang bisa saya bantu?',
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send(String message) async {
    if (message.trim().isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _msgs.add(_ChatMsg(role: 'user', content: message.trim()));
      _loading = true;
    });
    _scrollBottom();

    try {
      final res = await http.post(
        Uri.parse('$kApiUrl/../chatbot'), // /chatbot bukan /api/v1/chatbot
        headers: {
          'Content-Type': 'application/json',
          'Accept':        'application/json',
          ...await ApiService.authHeader(),
        },
        body: jsonEncode({
          'message':    message.trim(),
          'session_id': _sessionId,
        }),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(res.body);
      final reply = data['reply'] as String? ?? 'Maaf, terjadi kesalahan.';

      if (!mounted) return;
      setState(() {
        _msgs.add(_ChatMsg(role: 'bot', content: reply));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _msgs.add(const _ChatMsg(role: 'bot',
          content: 'Maaf, koneksi bermasalah. Coba lagi sesaat ya! 🙏'));
        _loading = false;
      });
    }
    _scrollBottom();
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      appBar: AppBar(
        backgroundColor: kPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Center(child: Text('AI',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Asisten Sanggar', style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            Text('🟢 Online', style: TextStyle(
                color: Colors.white.withOpacity(0.75), fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _msgs.clear();
              _msgs.add(const _ChatMsg(role: 'bot',
                content: 'Chat dihapus. Ada yang bisa saya bantu? 😊'));
            }),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
          ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(kSpace),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _msgs.length) return _TypingIndicator();
              final msg = _msgs[i];
              return _MessageBubble(msg: msg);
            },
          ),
        ),

        // Quick replies (tampilkan jika pesan sedikit)
        if (_msgs.length <= 2)
        Container(
          color: kBgCard,
          padding: const EdgeInsets.fromLTRB(kSpace, 10, kSpace, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickReplies.map((q) => GestureDetector(
                onTap: () => _send(q),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPrimaryPale,
                    borderRadius: BorderRadius.circular(kRadiusFull),
                    border: Border.all(color: kPrimary.withOpacity(0.2))),
                  child: Text(q, style: const TextStyle(
                      color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              )).toList(),
            ),
          ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.only(
            left: kSpace, right: kSpace,
            top: kSpaceSm,
            bottom: MediaQuery.of(context).viewInsets.bottom + kSpaceSm + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: kBgCard,
            border: Border(top: BorderSide(color: kBorder2)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText:  'Ketik pertanyaan...',
                  filled:    true,
                  fillColor: kBgSoft,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kRadiusFull),
                    borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: kSpaceSm),
            GestureDetector(
              onTap: () => _send(_ctrl.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _loading ? kMuted2 : kPrimary,
                  shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── BUBBLE ───────────────────────────────────────────────────
class _ChatMsg {
  final String role;
  final String content;
  const _ChatMsg({required this.role, required this.content});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _MessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
              child: const Center(child: Text('AI',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:        isUser ? kPrimary : kBgCard,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(kRadius),
                  topRight:    const Radius.circular(kRadius),
                  bottomLeft:  Radius.circular(isUser ? kRadius : kRadiusXs),
                  bottomRight: Radius.circular(isUser ? kRadiusXs : kRadius),
                ),
                border: isUser ? null : Border.all(color: kBorder2),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color:  isUser ? Colors.white : kText,
                  fontSize: 13.5, height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 30, height: 30,
          margin: const EdgeInsets.only(right: 8),
          decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          child: const Center(child: Text('AI',
            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kBorder2)),
          child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Container(
                width: 7, height: 7,
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  color: kMuted2.withOpacity(
                    i == 0 ? _ctrl.value :
                    i == 1 ? (_ctrl.value + 0.33) % 1 :
                             (_ctrl.value + 0.66) % 1),
                  shape: BoxShape.circle),
              ),
            ),
          )),
        ),
      ]),
    );
  }
}