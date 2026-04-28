import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/session.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _controller = StreamController<EmotionFrame>.broadcast();

  Stream<EmotionFrame> get emotionStream => _controller.stream;
  bool get isConnected => _channel != null;

  void connect(String wsUrl) {
    if (_channel != null) return; // already connected
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _channel!.stream.listen(
      (data) {
        if (data is! String) return; // ignore binary frames
        final json = jsonDecode(data) as Map<String, dynamic>;
        _controller.add(EmotionFrame.fromJson(json));
      },
      onError: (_) => disconnect(),
      onDone: () => _channel = null,
    );
  }

  void sendFrame(Uint8List jpegBytes) {
    _channel?.sink.add(jpegBytes);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
