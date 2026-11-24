import 'dart:async';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const _green  = Color(0xFF2E7D32);
  static const _viewId = 'plant-camera-view';

  web.HTMLVideoElement? _video;
  web.MediaStream?      _stream;
  bool   _ready  = false;
  bool   _hasErr = false;
  String _errMsg = '';

  @override
  void initState() {
    super.initState();
    _registerView();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final video = web.HTMLVideoElement()
        ..autoplay  = true
        ..setAttribute('playsinline', 'true')
        ..style.width     = '100%'
        ..style.height    = '100%'
        ..style.objectFit = 'cover';
      _video = video;
      return video;
    });
  }

  Future<void> _startCamera() async {
    try {
      // Request camera via JS interop
      final promise = web.window.navigator.mediaDevices.getUserMedia(
        web.MediaStreamConstraints(
          video: true.toJS,
          audio: false.toJS,
        ),
      );
      final stream = await promise.toDart;
      _stream = stream;
      if (_video != null) {
        _video!.srcObject = stream;
        await _video!.play().toDart;
      }
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasErr = true;
          _errMsg = 'Camera not available.\n\n'
              'Make sure:\n'
              '• You are on localhost (not a network IP)\n'
              '• Browser camera permission is allowed\n'
              '• A webcam/camera is connected\n\n'
              'Error: $e';
        });
      }
    }
  }

  void _stopStream() {
    if (_stream != null) {
      final tracks = _stream!.getTracks().toDart;
      for (final track in tracks) {
        track.stop();
      }
    }
  }

  Future<Uint8List?> _captureFrame() async {
    final video = _video;
    if (video == null) return null;

    final w = video.videoWidth;
    final h = video.videoHeight;
    if (w == 0 || h == 0) return null;

    final canvas = web.HTMLCanvasElement()
      ..width  = w
      ..height = h;

    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
    if (ctx == null) return null;
    ctx.drawImage(video, 0, 0);

    // Convert to blob then to bytes
    final completer = Completer<Uint8List?>();

    canvas.toBlob(
      ((web.Blob blob) {
        final reader = web.FileReader();
        reader.addEventListener(
          'loadend',
          ((web.Event _) {
            final buf = reader.result as JSArrayBuffer?;
            if (buf == null) {
              completer.complete(null);
              return;
            }
            completer.complete(buf.toDart.asUint8List());
          }).toJS,
        );
        reader.readAsArrayBuffer(blob);
      }).toJS,
      'image/jpeg',
    );

    return completer.future.timeout(const Duration(seconds: 5),
        onTimeout: () => null);
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Take Photo',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _hasErr
          ? _buildError()
          : Column(
              children: [
                // ── Live camera feed ─────────────────────────────────
                Expanded(
                  child: _ready
                      ? HtmlElementView(viewType: _viewId)
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: Colors.white),
                              SizedBox(height: 16),
                              Text('Starting camera...',
                                  style: TextStyle(
                                      color: Colors.white70)),
                            ],
                          ),
                        ),
                ),

                // ── Capture button ────────────────────────────────────
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white70, size: 28),
                        onPressed: () {
                          _stopStream();
                          Navigator.pop(context);
                        },
                      ),
                      // Shutter
                      GestureDetector(
                        onTap: _ready ? _onCapture : null,
                        child: Container(
                          width:  76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 4),
                            color: _ready
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white12,
                          ),
                          child: const Icon(Icons.camera,
                              color: Colors.white, size: 38),
                        ),
                      ),
                      // Spacer to balance layout
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography,
                  size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(_errMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.6)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12)),
                child: const Text('Go Back',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  Future<void> _onCapture() async {
    try {
      final bytes = await _captureFrame();
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to capture — try again')),
          );
        }
        return;
      }
      _stopStream();
      if (!mounted) return;
      Navigator.pop(context, bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture error: $e')),
        );
      }
    }
  }
}
