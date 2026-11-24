import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  static const _green = Color(0xFF2E7D32);

  late Future<Map<String, dynamic>> _future;

  // expansion state
  bool _lifecycleOpen  = false;
  bool _diseaseOpen    = false;
  bool _appGuideOpen   = false;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getGuide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide & Education',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _green));
          }

          // Use static fallback if API fails
          final data = snap.data ?? _staticGuide;
          final lifecycle = List<Map<String, dynamic>>.from(
              data['lifecycle'] as List? ?? []);
          final diseases = List<Map<String, dynamic>>.from(
              data['diseases'] as List? ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 4),

              // ── Lifecycle accordion ────────────────────────────────────
              _AccordionTile(
                icon: Icons.eco,
                iconColor: _green,
                title: 'Plant Lifecycle',
                subtitle: 'Planting phases & nutrition details',
                isOpen: _lifecycleOpen,
                onToggle: () =>
                    setState(() => _lifecycleOpen = !_lifecycleOpen),
                child: Column(
                  children: lifecycle.map((phase) {
                    return _LifecyclePhase(
                      range:       phase['range'] as String? ?? '',
                      title:       phase['title'] as String? ?? '',
                      description: phase['description'] as String? ?? '',
                      tip:         phase['tip'] as String? ?? '',
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // ── Disease encyclopedia accordion ─────────────────────────
              _AccordionTile(
                icon: Icons.biotech,
                iconColor: Colors.redAccent,
                title: 'Disease Encyclopedia',
                subtitle: 'Diagnosis & Complete Solutions',
                isOpen: _diseaseOpen,
                onToggle: () =>
                    setState(() => _diseaseOpen = !_diseaseOpen),
                child: Column(
                  children: diseases.map((d) {
                    return _DiseaseCard(
                      name:       d['name'] as String? ?? '',
                      type:       d['type'] as String? ?? '',
                      scientific: d['scientific'] as String? ?? '',
                      symptoms:   d['symptoms'] as String? ?? '',
                      solution:   d['solution'] as String? ?? '',
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // ── App guide accordion ────────────────────────────────────
              _AccordionTile(
                icon: Icons.phone_android,
                iconColor: Colors.blueAccent,
                title: 'App Guide',
                subtitle: 'How to diagnose quickly',
                isOpen: _appGuideOpen,
                onToggle: () =>
                    setState(() => _appGuideOpen = !_appGuideOpen),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Step(n: '1', text: 'Tap "Disease Classification" on the home screen.'),
                      _Step(n: '2', text: 'Choose Camera or Gallery to select a leaf photo.'),
                      _Step(n: '3', text: 'Ensure the leaf is clearly visible and well-lit.'),
                      _Step(n: '4', text: 'Tap "START ANALYSIS" and wait for the result.'),
                      _Step(n: '5', text: 'Read the AI explanation and follow the recommendations.'),
                      _Step(n: '6', text: 'View past results anytime in Analysis History.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Quote ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '"Healthy plants start from fertile soil and routine observation."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black45,
                      fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

// ── Accordion tile ─────────────────────────────────────────────────────────────
class _AccordionTile extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final bool     isOpen;
  final VoidCallback onToggle;
  final Widget   child;

  const _AccordionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(subtitle,
                            style: const TextStyle(
                                color: Colors.black45, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.black38,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

// ── Lifecycle phase widget ─────────────────────────────────────────────────────
class _LifecyclePhase extends StatelessWidget {
  final String range;
  final String title;
  final String description;
  final String tip;

  const _LifecyclePhase({
    required this.range,
    required this.title,
    required this.description,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32), shape: BoxShape.circle),
              ),
              Container(width: 2, height: 60, color: const Color(0xFFE0E0E0)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(range,
                    style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.4)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text('Tip: $tip',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              fontStyle: FontStyle.italic,
                              height: 1.4)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Disease card ───────────────────────────────────────────────────────────────
class _DiseaseCard extends StatelessWidget {
  final String name;
  final String type;
  final String scientific;
  final String symptoms;
  final String solution;

  const _DiseaseCard({
    required this.name,
    required this.type,
    required this.scientific,
    required this.symptoms,
    required this.solution,
  });

  Color get _typeColor {
    switch (type) {
      case 'BACTERIA': return Colors.orange;
      case 'FUNGUS':   return Colors.purple;
      case 'VIRUS':    return Colors.red;
      default:         return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(scientific,
                        style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(type,
                    style: TextStyle(
                        color: _typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Symptoms:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text(symptoms,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Control & Solution:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text(solution,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── App guide step ─────────────────────────────────────────────────────────────
class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Color(0xFF2E7D32), shape: BoxShape.circle),
            child: Text(n,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ── Static fallback data ───────────────────────────────────────────────────────
const _staticGuide = {
  'lifecycle': [
    {
      'range': '0-14 Days',
      'title': 'Nursery Phase',
      'description': 'Critical root formation phase. Use fine soil + husk charcoal.',
      'tip': 'Keep humidity at 80%. Shade from heavy rain.',
    },
    {
      'range': '15-35 Days',
      'title': 'Transplanting & Early Vegetative',
      'description': 'Focuses on stem and leaf growth. Needs high Nitrogen (N).',
      'tip': 'Install stakes/support sticks. Prune lower water shoots.',
    },
    {
      'range': '36-70 Days',
      'title': 'Generative (Flowering & Fruiting)',
      'description': 'Flower formation phase. Switch to high Phosphorus (P) and Potassium (K).',
      'tip': 'Reduce Nitrogen to avoid excessive foliage over fruit.',
    },
    {
      'range': '75+ Days',
      'title': 'Harvest Phase',
      'description': 'Monitor fruit color and size. Harvest regularly.',
      'tip': 'Harvest in the morning for best quality.',
    },
  ],
  'diseases': [
    {
      'name': 'Bacterial Spot',
      'type': 'BACTERIA',
      'scientific': 'Xanthomonas campestris',
      'symptoms': 'Small necrotic black spots surrounded by yellow halos. Leaves yellow and drop during rain.',
      'solution': 'Reduce humidity (pruning). Spray bactericides containing Copper Hydroxide or Streptomycin sulfate.',
    },
    {
      'name': 'Cercospora Leaf Spot',
      'type': 'FUNGUS',
      'scientific': 'Cercospora capsici',
      'symptoms': 'Round spots with light gray centers and dark brown edges (like an eye). Attacks older leaves first.',
      'solution': 'Burn fallen/infected leaves. Spray Mancozeb or Chlorothalonil fungicides.',
    },
    {
      'name': 'Powdery Mildew',
      'type': 'FUNGUS',
      'scientific': 'Leveillula taurica',
      'symptoms': 'White powdery coating on upper leaf surface. Leaves curl and drop prematurely.',
      'solution': 'Improve air circulation. Apply sulfur-based fungicides.',
    },
  ],
};
