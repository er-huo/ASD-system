// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show Uint8List;
// ignore: deprecated_member_use
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../config/constants.dart';

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

  html.WebSocket? _ws;
  Timer? _pollTimer;
  Timer? _captureTimer;
  Timer? _reconnectTimer;

  String? _detectedEmotion;
  double _confidence = 0.0;
  bool _cameraActive = false;
  bool _wsConnected = false;
  bool _permissionDenied = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  static const _emojiMap = {
    'happy': '😊', 'sad': '😢', 'angry': '😠',
    'fear': '😨', 'surprise': '😮', 'neutral': '😐', 'confused': '😕',
  };

  String get _wsUrl =>
      widget.backendUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://') +
      '/emotion/stream/${widget.sessionId}';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(_pulseCtrl);
    _connectWs();
    _startCamera();
  }

  void _connectWs() {
    _ws?.close();
    _ws = html.WebSocket(_wsUrl);
    _ws!.onOpen.listen((_) {
      if (mounted) setState(() => _wsConnected = true);
    });
    _ws!.onMessage.listen((event) {
      try {
        final data = jsonDecode(event.data as String) as Map<String, dynamic>;
        final emotion = data['emotion'] as String?;
        final conf = (data['confidence'] as num?)?.toDouble() ?? 0.0;
        if (mounted && emotion != null) {
          setState(() { _detectedEmotion = emotion; _confidence = conf; });
        }
      } catch (_) {}
    });
    _ws!.onClose.listen((_) {
      if (mounted) setState(() => _wsConnected = false);
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) _connectWs();
      });
    });
    _ws!.onError.listen((_) {
      if (mounted) setState(() => _wsConnected = false);
    });
  }

  void _startCamera() {
    // Tell JS to start camera entirely in JS — no Dart/JS stream passing
    js.context.callMethod('asdStart', []);

    // Poll until JS reports camera ready or denied
    _pollTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) { t.cancel(); return; }
      final denied = js.context.callMethod('asdIsDenied', []) as bool;
      final ready  = js.context.callMethod('asdIsReady',  []) as bool;
      if (denied) {
        t.cancel();
        setState(() => _permissionDenied = true);
      } else if (ready) {
        t.cancel();
        setState(() => _cameraActive = true);
        _captureLoop();
      }
    });
  }

  void _captureLoop() {
    _captureTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _sendFrame();
      if (mounted) _captureLoop();
    });
  }

  void _sendFrame() {
    if (_ws?.readyState != html.WebSocket.OPEN) return;
    try {
      final url = js.context.callMethod('asdGetFrame', []) as String;
      if (url.length < 3000) return;
      final base64 = url.substring(url.indexOf(',') + 1);
      _ws!.sendTypedData(Uint8List.fromList(base64Decode(base64)));
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _captureTimer?.cancel();
    _reconnectTimer?.cancel();
    _pulseCtrl.dispose();
    _ws?.close();
    js.context.callMethod('asdStop', []);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emotion = _detectedEmotion;
    final color = emotion != null
        ? (kEmotionColors[emotion] ?? Colors.blueGrey)
        : (_wsConnected ? Colors.green : Colors.blueGrey);
    final emoji = emotion != null ? (_emojiMap[emotion] ?? '😶') : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _wsConnected ? color.withValues(alpha: 0.8) : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (_permissionDenied)
          const Icon(Icons.videocam_off, color: Colors.red, size: 16)
        else
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Opacity(
              opacity: _cameraActive ? _pulse.value : 0.4,
              child: Icon(
                _cameraActive ? Icons.videocam : Icons.videocam_outlined,
                color: _wsConnected ? Colors.greenAccent : Colors.grey,
                size: 16,
              ),
            ),
          ),
        const SizedBox(width: 6),
        if (_permissionDenied)
          const Text('摄像头未授权',
              style: TextStyle(color: Colors.red, fontSize: 11))
        else if (emoji != null) ...[
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text('${(_confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ] else
          Text(_wsConnected ? '识别中…' : 'AI连接中…',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }
}
