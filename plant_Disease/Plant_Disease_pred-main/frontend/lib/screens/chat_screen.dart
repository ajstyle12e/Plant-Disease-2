import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String  sessionId;
  final String  diseaseContext;   // e.g. "Apple___Apple_scab" from last scan
  final String  title;

  const ChatScreen({
    super.key,
    required this.sessionId,
    this.diseaseContext = '',
    this.title = 'Plant AI Chat',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _green = Color(0xFF2E7D32);

  final _ctrl      = TextEditingController();
  final _scroll    = ScrollController();
  final List<_Msg> _msgs = [];
  bool _sending = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ApiService.getChatSession(widget.sessionId);
      setState(() {
        _msgs.addAll(
          data.map((m) => _Msg(
                role:      m['role'] as String,
                text:      m['content'] as String,
                timestamp: m['timestamp'] as String? ?? '',
              )),
        );
        _loading = false;
      });
      _scrollBottom();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(role: 'user', text: text,
          timestamp: DateTime.now().toIso8601String()));
      _sending = true;
    });
    _scrollBottom();

    try {
      final res = await ApiService.sendChat(
        sessionId:      widget.sessionId,
        message:        text,
        diseaseContext: widget.diseaseContext,
      );
      setState(() {
        _msgs.add(_Msg(
          role:      'assistant',
          text:      res['response'] as String,
          timestamp: DateTime.now().toIso8601String(),
        ));
        _sending = false;
      });
    } catch (e) {
      setState(() {
        _msgs.add(_Msg(
          role:      'assistant',
          text:      'Error: ${e.toString().replaceFirst("Exception: ", "")}',
          timestamp: DateTime.now().toIso8601String(),
          isError:   true,
        ));
        _sending = false;
      });
    }
    _scrollBottom();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            if (widget.diseaseContext.isNotEmpty)
              Text(
                widget.diseaseContext
                    .replaceAll('___', ' → ')
                    .replaceAll('_', ' '),
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11),
              ),
          ],
        ),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF0F4F0),
      body: Column(
        children: [
          // ── Messages ─────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _green))
                : _msgs.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        itemCount: _msgs.length + (_sending ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _msgs.length) return _TypingBubble();
                          return _MessageBubble(msg: _msgs[i]);
                        },
                      ),
          ),

          // ── Input bar ────────────────────────────────────────────────
          _InputBar(
            ctrl:     _ctrl,
            sending:  _sending,
            onSend:   _send,
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 64, color: Colors.black12),
              const SizedBox(height: 16),
              const Text('Ask me anything about plant diseases',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black38,
                      fontSize: 15)),
              const SizedBox(height: 8),
              if (widget.diseaseContext.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Context: ${widget.diseaseContext.replaceAll("___", " → ").replaceAll("_", " ")}',
                    style: const TextStyle(
                        color: _green, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              ..._suggestions(widget.diseaseContext)
                  .map((s) => _SuggestionChip(
                        text:   s,
                        onTap:  () {
                          _ctrl.text = s;
                          _send();
                        },
                      )),
            ],
          ),
        ),
      );

  List<String> _suggestions(String ctx) {
    if (ctx.isEmpty) {
      return [
        'What causes leaf spots?',
        'How to prevent fungal diseases?',
        'Best organic treatments for plants?',
      ];
    }
    final name = ctx.split('___').last.replaceAll('_', ' ');
    return [
      'What are the symptoms of $name?',
      'How do I treat $name?',
      'How to prevent $name from spreading?',
    ];
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────
class _Msg {
  final String role;
  final String text;
  final String timestamp;
  final bool   isError;
  _Msg({
    required this.role,
    required this.text,
    required this.timestamp,
    this.isError = false,
  });
  bool get isUser => role == 'user';
}

// ── Message bubble ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  const _MessageBubble({required this.msg});

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    final time   = _fmtTime(msg.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _green,
              child: const Icon(Icons.eco,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isError
                        ? const Color(0xFFFFEBEE)
                        : isUser
                            ? _green
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isError
                          ? Colors.red
                          : isUser
                              ? Colors.white
                              : Colors.black87,
                      fontSize: 13.5,
                      height:   1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(time,
                    style: const TextStyle(
                        color: Colors.black38, fontSize: 10)),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _fmtTime(String ts) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(ts).toLocal());
    } catch (_) {
      return '';
    }
  }
}

// ── Typing indicator ───────────────────────────────────────────────────────────
class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF2E7D32),
            child: Icon(Icons.eco, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _Dot(delay: i * 200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ac,
        curve: Interval(
            widget.delay / 1000, min(1, widget.delay / 1000 + 0.5),
            curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: 8, height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(Colors.black26, const Color(0xFF2E7D32),
                _anim.value),
          ),
        ),
      );
}

// ── Input bar ──────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool         sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.ctrl,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                minLines:   1,
                maxLines:   4,
                enabled:    !sending,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:    'Ask about plant diseases...',
                  filled:      true,
                  fillColor:   const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sending
                      ? Colors.grey.shade300
                      : const Color(0xFF2E7D32),
                ),
                child: sending
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Suggestion chip ────────────────────────────────────────────────────────────
class _SuggestionChip extends StatelessWidget {
  final String       text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2E7D32)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: Color(0xFF2E7D32), fontSize: 13)),
        ),
      );
}
