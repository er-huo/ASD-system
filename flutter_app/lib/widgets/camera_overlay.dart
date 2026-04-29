// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../config/constants.dart';

/// Floating badge that streams camera frames to the backend via WebSocket
/// and shows the detected emotion in real-time.
///
/// Does NOT show a video preview — autistic children find it distracting.
class CameraOverlay extends StatefulWidget {
  final String sessionId;
  final String backendUrl;

  const CameraOverlay({
    super.key,
    required this.sessionId,
    required this.backendUrl,
  });

  @override
  State<CameraOverlay> createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay>
    with SingleTickerProviderStateMixin {
  final _ws = WebSocketService();
  html.VideoElement? _video;
  html.CanvasElement? _canvas;
  Timer? _captureTimer;

  String? _detectedEmotion;
  double _confidence = 0.0;
  bool _cameraActive = false;
  bool _permissionDenied = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  static const _emojiMap = {
    'happy': '😊', 'sad': '😢', 'angry': '😠',
    'fear': '😨', 'surprise': '😮', 'neutral': '😐', 'confused': '😕',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(_pulseCtrl);
    _startCamera();
  }

  Future<void> _startCamera() async {
    // Connect WebSocket first (non-blocking)
    final wsUrl = widget.backendUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://') +
        '/emotion/stream/${widget.sessionId}';
    try {
      _ws.connect(wsUrl);
      _ws.emotionStream.listen((frame) {
        if (!mounted) return;
        if (frame.emotion != null) {
          setState(() {
            _detectedEmotion = frame.emotion;
            _confidence = frame.confidence;
          });
        }
      });
    } catch (_) {}

    // Request camera permission
    try {
      final stream = await html.window.navigator.mediaDevices
          ?.getUserMedia({'video': {'facingMode': 'user'}, 'audio': false});
      if (stream == null) {
        if (mounted) setState(() => _permissionDenied = true);
        return;
      }
      _video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..srcObject = stream;
      _canvas = html.CanvasElement(width: 160, height: 120);

      // Wait for video to be ready
      await _video!.onLoadedMetadata.first;

      if (mounted) setState(() => _cameraActive = true);

      // Capture frame every 600ms
      _captureTimer = Timer.periodic(
          const Duration(milliseconds: 600), (_) => _captureAndSend());
    } on html.DomException {
      if (mounted) setState(() => _permissionDenied = true);
    } catch (_) {
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  void _captureAndSend() {
    if (_video == null || _canvas == null) return;
    try {
      _canvas!.context2D.drawImageScaled(_video!, 0, 0, 160, 120);
      _canvas!.toBlob('image/jpeg', 0.65).then((blob) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        reader.onLoad.listen((_) {
          final result = reader.result;
          if (result is List<int>) {
            _ws.sendFrame(Uint8List.fromList(result));
          } else if (result is ByteBuffer) {
            _ws.sendFrame(result.asUint8List());
          }
        });
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _pulseCtrl.dispose();
    _video?.srcObject?.getTracks().forEach((t) => t.stop());
    _ws.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emotion = _detectedEmotion;
    final color = emotion != null
        ? (kEmotionColors[emotion] ?? Colors.blueGrey)
        : Colors.blueGrey;
    final emoji = emotion != null ? (_emojiMap[emotion] ?? '😶') : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _cameraActive ? color.withValues(alpha: 0.8) : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        // Camera status dot
        if (_permissionDenied)
          const Icon(Icons.videocam_off, color: Colors.red, size: 16)
        else if (!_cameraActive)
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Opacity(
              opacity: _pulse.value,
              child: const Icon(Icons.videocam, color: Colors.grey, size: 16),
            ),
          )
        else
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Opacity(
              opacity: _pulse.value,
              child: Icon(Icons.videocam, color: color, size: 16),
            ),
          ),
        const SizedBox(width: 6),
        // Emotion result
        if (_permissionDenied)
          const Text('摄像头未授权',
              style: TextStyle(color: Colors.red, fontSize: 11))
        else if (emoji != null) ...[
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '${((_confidence) * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold,
            ),
          ),
        ] else
          const Text('AI识别中…',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }
}
