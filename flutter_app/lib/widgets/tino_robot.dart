// NOTE: Full Rive animation requires .riv files at assets/animations/tino.riv and
// assets/animations/tina.riv. Until those exist the widget renders a CSS-style robot.
// To enable Rive: replace _buildFallbackRobot() call in build() with:
//   RiveAnimation.asset('assets/animations/$robotType.riv',
//     stateMachines: ['EmotionMachine'],
//     onInit: (artboard) { /* set emotion input */ });
import 'package:flutter/material.dart';
import '../config/constants.dart';

class TinoRobot extends StatelessWidget {
  final String emotion;
  final String robotType;
  final double size;

  const TinoRobot({super.key, required this.emotion, required this.robotType, this.size = 160});

  Color get _bodyColor => kEmotionColors[emotion] ?? const Color(0xFFFFAA00);

  @override
  Widget build(BuildContext context) => _buildFallbackRobot();

  Widget _buildFallbackRobot() {
    final color = _bodyColor;
    final headSize = size * 0.45;
    final bodyW = size * 0.55;
    final bodyH = size * 0.42;

    return SizedBox(
      width: size, height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 4, height: size * 0.08, color: color.withValues(alpha: 0.7)),
          Container(width: size * 0.06, height: size * 0.06,
              decoration: BoxDecoration(color: const Color(0xFFFFCC02), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFFFFCC02).withValues(alpha: 0.8), blurRadius: 6)])),
          const SizedBox(height: 2),
          Container(
            key: const Key('tino_head'),
            width: headSize, height: headSize,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: _buildFace(),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: bodyW, height: bodyH,
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(bodyW * 0.2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFace() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(top: 28, left: 18, child: _eye()),
        Positioned(top: 28, right: 18, child: _eye()),
        Positioned(bottom: 18, child: _mouth()),
        Positioned(bottom: 26, left: 12, child: _cheek()),
        Positioned(bottom: 26, right: 12, child: _cheek()),
      ],
    );
  }

  Widget _eye() => Container(
        width: 18, height: 18,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Center(child: CircleAvatar(radius: 5, backgroundColor: Color(0xFF4E342E))));

  Widget _mouth() {
    switch (emotion) {
      case 'happy':
        return Container(width: 28, height: 14,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 3)),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))));
      case 'sad':
        return Container(width: 28, height: 14,
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 3)),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))));
      default:
        return Container(width: 22, height: 3, color: Colors.white);
    }
  }

  Widget _cheek() => Container(
        width: 12, height: 7,
        decoration: BoxDecoration(color: Colors.pink.shade200.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)));
}
