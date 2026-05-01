import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/constants.dart';

// Tino robot with per-emotion face expressions and body animations.
// Arms animate based on emotion; color changes are driven by kEmotionColors.
class TinoRobot extends StatefulWidget {
  final String emotion;
  final String robotType;
  final double size;

  const TinoRobot({super.key, required this.emotion, required this.robotType, this.size = 160});

  @override
  State<TinoRobot> createState() => _TinoRobotState();
}

class _TinoRobotState extends State<TinoRobot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _setupAnim(widget.emotion);
  }

  @override
  void didUpdateWidget(TinoRobot old) {
    super.didUpdateWidget(old);
    if (widget.emotion != old.emotion) _setupAnim(widget.emotion);
  }

  void _setupAnim(String e) {
    _ctrl.stop();
    final ms = switch (e) {
      'angry'    => 90,
      'fear'     => 280,
      'happy'    => 520,
      'surprise' => 640,
      'sad'      => 1800,
      'confused' => 900,
      _          => 2200,
    };
    _ctrl.duration = Duration(milliseconds: ms);
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _ctrl, builder: (_, __) => _buildRobot());

  Widget _buildRobot() {
    final e = widget.emotion;
    final c = kEmotionColors[e] ?? const Color(0xFFFFAA00);
    final s = widget.size;
    final t = _anim.value;

    final headSize = s * 0.42;
    final bodyW    = s * 0.48;
    final bodyH    = s * 0.36;
    final armW     = s * 0.10;
    final armH     = s * 0.26;

    // Per-emotion transforms
    double bodyDy = 0, bodyDx = 0, headAngle = 0;
    double lArm = 0, rArm = 0;

    switch (e) {
      case 'happy':
        lArm   = -(math.pi / 4) * t;
        rArm   = (math.pi / 4) * t;
        bodyDy = -s * 0.025 * t;
        break;
      case 'sad':
        lArm   = (math.pi / 6) * t;
        rArm   = -(math.pi / 6) * t;
        bodyDy = s * 0.03 * t;
        break;
      case 'angry':
        bodyDx = s * 0.025 * (t * 2 - 1); // rapid shake
        lArm   = -0.45;                     // arms tensed, static
        rArm   = 0.45;
        break;
      case 'fear':
        final up = 0.7 + 0.3 * t;
        lArm   = -(math.pi / 3) * up;      // arms raised, trembling
        rArm   = (math.pi / 3) * up;
        bodyDx = s * 0.01 * (t * 2 - 1);
        break;
      case 'surprise':
        bodyDy = -s * 0.08 * math.sin(t * math.pi); // jump arc
        lArm   = -(math.pi / 3) * t;
        rArm   = (math.pi / 3) * t;
        break;
      case 'confused':
        headAngle = 0.25 * (t - 0.5);      // head tilts
        lArm      = (math.pi / 8) * t;
        break;
      default: // neutral
        bodyDy = -s * 0.02 * t;            // gentle float
    }

    Widget arm(double angle) => Transform.rotate(
      angle: angle,
      alignment: Alignment.topCenter,
      child: Container(
        width: armW, height: armH,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(armW / 2),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.2), blurRadius: 3)],
        ),
      ),
    );

    final head = Transform.rotate(
      angle: headAngle,
      child: Container(
        key: const Key('tino_head'),
        width: headSize, height: headSize,
        decoration: BoxDecoration(
          color: c, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: _buildFace(e),
      ),
    );

    final body = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        arm(lArm),
        Container(
          width: bodyW, height: bodyH,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(bodyW * 0.2),
            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
        ),
        arm(rArm),
      ],
    );

    return SizedBox(
      width: s, height: s,
      child: Transform.translate(
        offset: Offset(bodyDx, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 4, height: s * 0.07, color: c.withValues(alpha: 0.7)),
            Container(
              width: s * 0.06, height: s * 0.06,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC02), shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFFFCC02).withValues(alpha: 0.8), blurRadius: 6)],
              ),
            ),
            const SizedBox(height: 2),
            head,
            Transform.translate(offset: Offset(0, bodyDy), child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildFace(String e) => Stack(
    alignment: Alignment.center,
    children: [
      ..._brows(e),
      Positioned(top: 28, left: 16, child: _eye(e)),
      Positioned(top: 28, right: 16, child: _eye(e)),
      Positioned(bottom: 14, child: _mouth(e)),
      if (e == 'happy' || e == 'surprise') ...[
        Positioned(bottom: 22, left: 10, child: _cheek()),
        Positioned(bottom: 22, right: 10, child: _cheek()),
      ],
    ],
  );

  List<Widget> _brows(String e) {
    Widget bar() => Container(width: 16, height: 3, color: Colors.white);
    return switch (e) {
      'angry' => [
        Positioned(top: 13, left: 12,  child: Transform.rotate(angle:  0.35, child: bar())),
        Positioned(top: 13, right: 12, child: Transform.rotate(angle: -0.35, child: bar())),
      ],
      'sad' => [
        Positioned(top: 16, left: 12,  child: Transform.rotate(angle: -0.3, child: bar())),
        Positioned(top: 16, right: 12, child: Transform.rotate(angle:  0.3, child: bar())),
      ],
      'confused' => [
        Positioned(top: 16, left: 12,  child: bar()),
        Positioned(top: 14, right: 12, child: Transform.rotate(angle: -0.3, child: bar())),
      ],
      _ => [],
    };
  }

  Widget _eye(String e) {
    final wide = e == 'fear' || e == 'surprise';
    final eyeSize = wide ? 22.0 : 18.0;
    return Container(
      width: eyeSize, height: eyeSize,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Center(child: CircleAvatar(radius: wide ? 6.0 : 5.0, backgroundColor: const Color(0xFF4E342E))),
    );
  }

  Widget _mouth(String e) => switch (e) {
    'happy' => Container(
      width: 28, height: 14,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white, width: 3)),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
      ),
    ),
    'sad' => Container(
      width: 28, height: 14,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white, width: 3)),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
      ),
    ),
    'angry' => Container(width: 24, height: 3, color: Colors.white),
    'fear'  => Container(
      width: 20, height: 20,
      decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), shape: BoxShape.circle),
    ),
    'surprise' => Container(
      width: 22, height: 22,
      decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), shape: BoxShape.circle),
    ),
    'confused' => Container(
      width: 22, height: 14,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white, width: 3)),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(14)),
      ),
    ),
    _ => Container(width: 22, height: 3, color: Colors.white), // neutral
  };

  Widget _cheek() => Container(
    width: 12, height: 7,
    decoration: BoxDecoration(
      color: Colors.pink.shade200.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}
