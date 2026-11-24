import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  static const _green = Color(0xFF2E7D32);
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = ApiService.getChatSessions());

  String _newSessionId() =>
      'session_${DateTime.now().millisecondsSinceEpoch}';

  void _openChat({
    required String sessionId,
    String diseaseContext = '',
    String title = 'Plant AI Chat',
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          sessionId:      sessionId,
          diseaseContext: diseaseContext,
          title:          title,
        ),
      ),
    ).then((_) => _load());   // refresh list on return
  }

  Future<void> _deleteSession(String sessionId) async {
    await ApiService.deleteChatSession(sessionId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text('New Chat',
            style: TextStyle(color: Colors.white)),
        onPressed: () => _openChat(sessionId: _newSessionId()),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _green));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off,
                      size: 48, color: Colors.black26),
                  const SizedBox(height: 12),
                  Text(snap.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black45)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _green),
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final sessions = snap.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.black12),
                  const SizedBox(height: 12),
                  const Text('No chat history yet',
                      style: TextStyle(
                          color: Colors.black38, fontSize: 15)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _openChat(sessionId: _newSessionId()),
                    icon: const Icon(Icons.add_comment,
                        color: Colors.white),
                    label: const Text('Start a new chat',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = sessions[i] as Map<String, dynamic>;
              return _SessionCard(
                session:   s,
                onTap:     () => _openChat(
                  sessionId:      s['session_id'] as String,
                  diseaseContext: s['disease_context'] as String? ?? '',
                  title: _sessionTitle(s),
                ),
                onDelete: () => _deleteSession(
                    s['session_id'] as String),
              );
            },
          );
        },
      ),
    );
  }

  String _sessionTitle(Map<String, dynamic> s) {
    final ctx = s['disease_context'] as String? ?? '';
    if (ctx.isNotEmpty) {
      return ctx.split('___').last.replaceAll('_', ' ');
    }
    final msg = s['last_message'] as String? ?? '';
    if (msg.length > 30) return '${msg.substring(0, 30)}...';
    return msg.isEmpty ? 'Chat' : msg;
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final ctx      = session['disease_context'] as String? ?? '';
    final lastMsg  = session['last_message']    as String? ?? '';
    final updatedAt = session['updated_at']     as String? ?? '';

    String timeStr = '';
    try {
      timeStr = DateFormat('dd MMM, HH:mm')
          .format(DateTime.parse(updatedAt).toLocal());
    } catch (_) {}

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_bubble,
                  color: _green, size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease context badge
                  if (ctx.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ctx.split('___').last.replaceAll('_', ' '),
                        style: const TextStyle(
                            color: _green,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  Text(
                    lastMsg.isNotEmpty ? lastMsg : 'New conversation',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(timeStr,
                      style: const TextStyle(
                          color: Colors.black38, fontSize: 11)),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
            const Icon(Icons.chevron_right,
                color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
