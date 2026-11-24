import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_model.dart';
import '../services/api_service.dart';

class HistoryDetailScreen extends StatefulWidget {
  final String id;
  const HistoryDetailScreen({super.key, required this.id});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  static const _green = Color(0xFF2E7D32);
  late Future<HistoryItem> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getHistoryDetail(widget.id);
  }

  String _plantName(String raw) => raw.split('___').first.replaceAll('_', ' ');
  String _diseaseName(String raw) {
    final p = raw.split('___');
    return (p.length < 2 ? raw : p.last).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Detail',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<HistoryItem>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _green));
          }
          if (snap.hasError) {
            return Center(
                child: Text(snap.error.toString(),
                    style: const TextStyle(color: Colors.black45)));
          }
          final item = snap.data!;
          final date = DateFormat('yyyy-MM-dd HH:mm')
              .format(item.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image ──────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: item.imageBase64.isNotEmpty
                      ? Image.memory(
                          base64Decode(item.imageBase64),
                          width:  double.infinity,
                          height: 220,
                          fit:    BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholder(),
                        )
                      : _placeholder(),
                ),

                const SizedBox(height: 16),

                // ── Plant & Disease ─────────────────────────────────────
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plant
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.eco,
                                color: _green, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Plant',
                                  style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: 11)),
                              Text(
                                  _plantName(
                                      item.predictedClass),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      // Disease
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                                Icons.coronavirus_outlined,
                                color: Colors.redAccent,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('Disease Detected',
                                    style: TextStyle(
                                        color: Colors.black45,
                                        fontSize: 11)),
                                Text(
                                    _diseaseName(
                                        item.predictedClass),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(date,
                            style: const TextStyle(
                                color: Colors.black38,
                                fontSize: 11)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── LLM Explanation ─────────────────────────────────────
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
                          const Text(
                              'AI Explanation & Recommendation',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item.explanation.isNotEmpty
                            ? item.explanation
                            : 'No explanation available.',
                        style: const TextStyle(
                            fontSize: 13,
                            height:   1.7,
                            color:    Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder() => Container(
        width:  double.infinity,
        height: 220,
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18)),
        child:
            const Icon(Icons.image, size: 64, color: Colors.black26),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color:     Colors.black.withOpacity(0.05),
                blurRadius: 8)
          ],
        ),
        child: child,
      );
}
