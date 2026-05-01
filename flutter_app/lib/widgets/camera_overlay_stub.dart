import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  final String sessionId;
  final String backendUrl;

  const CameraOverlay({
    super.key,
    required this.sessionId,
    required this.backendUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey, width: 1.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_outlined, color: Colors.white54, size: 16),
          SizedBox(width: 6),
          Text(
            'AI连接中…',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
