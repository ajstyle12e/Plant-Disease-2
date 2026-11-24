import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_model.dart';
import '../services/api_service.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _green = Color(0xFF2E7D32);

  late Future<List<HistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = ApiService.getHistory());

  Future<void> _delete(String id) async {
    await ApiService.deleteHistory(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
        ],
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<List<HistoryItem>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _green));
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: Colors.black26),
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
                            style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.black12),
                  SizedBox(height: 12),
                  Text('No analysis history yet',
                      style: TextStyle(color: Colors.black38, fontSize: 15)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _HistoryCard(
              item: items[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => HistoryDetailScreen(id: items[i].id)),
              ),
              onDelete: () => _delete(items[i].id),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard(
      {required this.item, required this.onTap, required this.onDelete});

  String _plantName(String raw) =>
      raw.split('___').first.replaceAll('_', ' ');

  String _diseaseName(String raw) {
    final p = raw.split('___');
    return (p.length < 2 ? raw : p.last).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(item.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageBase64.isNotEmpty
                  ? Image.memory(
                      base64Decode(item.imageBase64),
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_diseaseName(item.predictedClass),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(_plantName(item.predictedClass),
                      style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text('Date: $date',
                      style: const TextStyle(
                          color: Colors.black38, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 22),
              onPressed: onDelete,
            ),
            const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 60, height: 60,
        color: Colors.grey.shade100,
        child: const Icon(Icons.image, color: Colors.black26),
      );
}
