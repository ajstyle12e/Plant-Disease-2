import 'package:flutter/material.dart';
import 'detect_screen.dart';
import 'history_screen.dart';
import 'guide_screen.dart';
import 'chat_sessions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Green header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(
              color: _green,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello,',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('Welcome!! 🌿',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text('Plant Disease Classifier',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14)),
                      ),
                      Icon(Icons.eco,
                          color: Color(0xFF2E7D32), size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Menu cards ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _MenuCard(
                    icon: Icons.camera_alt,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: _green,
                    title: 'Disease Classification',
                    subtitle: 'Detect plant disease from a photo',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DetectScreen())),
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    icon: Icons.history,
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: Colors.redAccent,
                    title: 'Analysis History',
                    subtitle: 'View previous analysis results',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen())),
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    icon: Icons.smart_toy_outlined,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: Colors.blueAccent,
                    title: 'AI Chatbot',
                    subtitle:
                        'Ask questions about plant diseases',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ChatSessionsScreen())),
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    icon: Icons.menu_book,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: _green,
                    title: 'Guide & Education',
                    subtitle:
                        'Plant care tips and disease encyclopedia',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GuideScreen())),
                  ),
                  const SizedBox(height: 20),

                  // ── Tip of the day ─────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Tip of the Day 🌱',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        SizedBox(height: 6),
                        Text(
                          'Use clean water when watering plants to prevent '
                          'disease spread through contaminated water.',
                          style: TextStyle(
                              color: Colors.black87, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData     icon;
  final Color        iconBg;
  final Color        iconColor;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
