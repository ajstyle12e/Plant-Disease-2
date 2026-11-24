import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'camera_screen.dart';
import 'result_screen.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  static const _green = Color(0xFF2E7D32);

  Uint8List? _imageBytes;
  String     _imageName = 'capture.jpg';
  bool       _loading   = false;
  String?    _error;

  // ── Open live camera ────────────────────────────────────────────────────────
  Future<void> _openCamera() async {
    if (kIsWeb) {
      // Web: use our custom HTML camera screen
      final bytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
      if (bytes == null || bytes.isEmpty) return;
      setState(() {
        _imageBytes = bytes;
        _imageName  = 'capture.jpg';
        _error      = null;
      });
    } else {
      // Mobile: use native camera
      await _pickFromGallery(ImageSource.camera);
    }
  }

  // ── Open gallery ────────────────────────────────────────────────────────────
  Future<void> _pickFromGallery(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source:       source,
        imageQuality: 100,
        maxWidth:     1024,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        setState(() => _error = 'Selected file is empty.');
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageName  = picked.name.isNotEmpty ? picked.name : 'image.jpg';
        _error      = null;
      });
    } catch (e) {
      setState(() =>
          _error = 'Could not load image: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  // ── Run analysis ────────────────────────────────────────────────────────────
  Future<void> _startAnalysis() async {
    if (_imageBytes == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result =
          await ApiService.predictBytes(_imageBytes!, _imageName);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result:     result,
            imageBytes: _imageBytes!,
          ),
        ),
      );
    } catch (e) {
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Detection',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Image preview ──────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => _pickFromGallery(ImageSource.gallery),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10)
                    ],
                  ),
                  child: _imageBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 64, color: Colors.black26),
                            SizedBox(height: 12),
                            Text('Upload Plant Leaf Photo',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black54)),
                            SizedBox(height: 4),
                            Text('Ensure image is clear and focused',
                                style: TextStyle(
                                    color: Colors.black38,
                                    fontSize: 12)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(
                            _imageBytes!,
                            fit:   BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Camera / Gallery buttons ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon:  Icons.camera_alt,
                    label: 'Camera',
                    color: _green,
                    onTap: _openCamera,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceButton(
                    icon:  Icons.photo_library,
                    label: 'Gallery',
                    color: _green,
                    onTap: () => _pickFromGallery(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center),
                ),
              ),

            // ── Start Analysis ─────────────────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_imageBytes != null && !_loading)
                    ? _startAnalysis
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('START ANALYSIS',
                        style: TextStyle(
                            color:        Colors.white,
                            fontWeight:   FontWeight.bold,
                            fontSize:     15,
                            letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon:  Icon(icon, color: color, size: 20),
      label: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side:    BorderSide(color: color),
        shape:   RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
