import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'detect_screen.dart';
import 'chat_screen.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final Uint8List            imageBytes;

  const ResultScreen({
    super.key,
    required this.result,
    required this.imageBytes,
  });

  static const _green = Color(0xFF2E7D32);

  String get _rawClass   => result['predicted_class'] as String? ?? '';
  String get _plantName  => _rawClass.split('___').first.replaceAll('_', ' ');
  String get _diseaseName {
    final p = _rawClass.split('___');
    return (p.length < 2 ? _rawClass : p.last).replaceAll('_', ' ');
  }
  String get _explanation => result['explanation'] as String? ?? '';

  String _newSessionId() =>
      'session_${DateTime.now().millisecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification Result',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(imageBytes,
                  width: double.infinity, height: 220, fit: BoxFit.cover),
            ),

            const SizedBox(height: 16),

            // ── Plant & Disease card ───────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant
                  _InfoRow(
                    iconBg: const Color(0xFFE8F5E9),
                    icon: Icons.eco,
                    iconColor: _green,
                    label: 'Plant',
                    value: _plantName,
                    valueColor: Colors.black87,
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  // Disease
                  _InfoRow(
                    iconBg: const Color(0xFFFFEBEE),
                    icon: Icons.coronavirus_outlined,
                    iconColor: Colors.redAccent,
                    label: 'Disease Detected',
                    value: _diseaseName,
                    valueColor: Colors.redAccent,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                      style: const TextStyle(
                          color: Colors.black38, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Ask AI button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      sessionId:      _newSessionId(),
                      diseaseContext: _rawClass,
                      title:          '$_diseaseName Chat',
                    ),
                  ),
                ),
                icon: const Icon(Icons.smart_toy_outlined,
                    color: Colors.white, size: 20),
                label: const Text('Ask AI about this disease',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── LLM Explanation ────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.blueAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('AI Explanation & Recommendation',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _explanation.isNotEmpty
                      ? Text(_explanation,
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.7,
                              color: Colors.black87))
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: _green),
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DetectScreen()),
                      (r) => r.isFirst,
                    ),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('New Image'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _green),
                      foregroundColor: _green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DetectScreen()),
                      (r) => r.isFirst,
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Analyse Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: child,
      );
}

class _InfoRow extends StatelessWidget {
  final Color    iconBg;
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   value;
  final Color    valueColor;

  const _InfoRow({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 11)),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: valueColor)),
              ],
            ),
          ),
        ],
      );
}
