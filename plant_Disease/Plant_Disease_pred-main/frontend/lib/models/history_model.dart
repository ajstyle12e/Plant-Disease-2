class Top5 {
  final String className;
  final double confidence;

  Top5({required this.className, required this.confidence});

  factory Top5.fromJson(Map<String, dynamic> j) => Top5(
        className:  j['class'] as String,
        confidence: (j['confidence'] as num).toDouble(),
      );
}

class HistoryItem {
  final String id;
  final String predictedClass;
  final double confidence;
  final List<Top5> top5;
  final String explanation;
  final String imageBase64;
  final DateTime createdAt;

  HistoryItem({
    required this.id,
    required this.predictedClass,
    required this.confidence,
    required this.top5,
    required this.explanation,
    required this.imageBase64,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id:             j['_id'] as String? ?? '',
        predictedClass: j['predicted_class'] as String,
        confidence:     (j['confidence'] as num).toDouble(),
        top5: (j['top_5_predictions'] as List? ?? [])
            .map((e) => Top5.fromJson(e as Map<String, dynamic>))
            .toList(),
        explanation: j['explanation'] as String? ?? '',
        imageBase64: j['image_base64'] as String? ?? '',
        createdAt:   DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
