import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/history_model.dart';

class ApiService {
  // ── Predict ─────────────────────────────────────────────────────────────
  // Takes raw bytes + filename — works on both web and mobile
  static Future<Map<String, dynamic>> predictBytes(
      Uint8List bytes, String filename) async {
    final uri     = Uri.parse(AppConfig.predictUrl);
    final request = http.MultipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
    ));

    final streamed =
        await request.send().timeout(const Duration(seconds: 90));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    final err = jsonDecode(body);
    throw Exception(err['error'] ?? 'Prediction failed (${streamed.statusCode})');
  }

  // ── History list ─────────────────────────────────────────────────────────
  static Future<List<HistoryItem>> getHistory() async {
    final res = await http
        .get(Uri.parse(AppConfig.historyUrl))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load history (${res.statusCode})');
  }

  // ── History detail ────────────────────────────────────────────────────────
  static Future<HistoryItem> getHistoryDetail(String id) async {
    final res = await http
        .get(Uri.parse('${AppConfig.historyUrl}/$id'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return HistoryItem.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load detail (${res.statusCode})');
  }

  // ── Delete history ────────────────────────────────────────────────────────
  static Future<void> deleteHistory(String id) async {
    await http
        .delete(Uri.parse('${AppConfig.historyUrl}/$id'))
        .timeout(const Duration(seconds: 15));
  }

  // ── Guide ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getGuide() async {
    final res = await http
        .get(Uri.parse(AppConfig.guideUrl))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load guide (${res.statusCode})');
  }

  // ── Chat: send message ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendChat({
    required String sessionId,
    required String message,
    String diseaseContext = '',
  }) async {
    final res = await http
        .post(
          Uri.parse(AppConfig.chatUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'session_id':      sessionId,
            'message':         message,
            'disease_context': diseaseContext,
          }),
        )
        .timeout(const Duration(seconds: 90));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Chat failed (${res.statusCode})');
  }

  // ── Chat: list sessions ────────────────────────────────────────────────────
  static Future<List<dynamic>> getChatSessions() async {
    final res = await http
        .get(Uri.parse('${AppConfig.chatUrl}/sessions'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    throw Exception('Failed to load sessions');
  }

  // ── Chat: get session messages ─────────────────────────────────────────────
  static Future<List<dynamic>> getChatSession(String sessionId) async {
    final res = await http
        .get(Uri.parse('${AppConfig.chatUrl}/sessions/$sessionId'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    throw Exception('Failed to load session');
  }

  // ── Chat: delete session ───────────────────────────────────────────────────
  static Future<void> deleteChatSession(String sessionId) async {
    await http
        .delete(Uri.parse('${AppConfig.chatUrl}/sessions/$sessionId'))
        .timeout(const Duration(seconds: 15));
  }
}
