import 'dart:math';
import 'package:flutter/material.dart';
import 'focus_animal.dart';

/// Animal de perfil corriendo (minijuego). `phase` avanza con la distancia recorrida.
class SideRunner extends StatelessWidget {
  final Animal animal;
  final double size, phase;
  final bool air, sad;
  const SideRunner({super.key, required this.animal, required this.size, required this.phase, this.air = false, this.sad = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size * 1.4,
        height: size * 1.4,
        child: CustomPaint(painter: _RunnerPainter(animal, phase, air, sad)),
      );
}

class _RunnerPainter extends CustomPainter {
  final Animal a;
  final double ph;
  final bool air, sad;
  _RunnerPainter(this.a, this.ph, this.air, this.sad);

  static const ink = Color(0xFF2B2140);
  Color get base => const {
        Animal.cerdo: Color(0xFFFFB3C7),
        Animal.unicornio: Color(0xFFF1ECFF),
        Animal.tigre: Color(0xFFFFA94D),
        Animal.cocodrilo: Color(0xFF6BCB77),
      }[a]!;
  Color get light => const {
        Animal.cerdo: Color(0xFFFFE1EA),
        Animal.unicornio: Color(0xFFFFFFFF),
        Animal.tigre: Color(0xFFFFE0A8),
        Animal.cocodrilo: Color(0xFFC6F2A6),
      }[a]!;
  Color get line => const {
        Animal.cerdo: Color(0xFFD77A9A),
        Animal.unicornio: Color(0xFF8A78B8),
        Animal.tigre: Color(0xFF8A4B12),
        Animal.cocodrilo: Color(0xFF2E7D4F),
      }[a]!;
  Color get accent => const {
        Animal.cerdo: Color(0xFFFF8FB0),
        Animal.unicornio: Color(0xFFFFB3D1),
        Animal.tigre: Color(0xFFFFFFFF),
        Animal.cocodrilo: Color(0xFFFFB04C),
      }[a]!;

  Paint _f(Color c) => Paint()..color = c;
  Paint _l(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  Paint _g(Rect r, Color hi, Color lo) => Paint()
    ..shader = RadialGradient(center: const Alignment(-.35, -.5), radius: 1.0, colors: [hi, lo]).createShader(r);

  void _leg(Canvas c, double hx, double sw, bool far) {
    final col = far ? Color.lerp(base, Colors.black, .22)! : base;
    final hip = Offset(hx, 71);
    final knee = hip + Offset(sin(sw) * 8, cos(sw) * 9);
    final th2 = sw * .5 - .35;
    final foot = knee + Offset(sin(th2) * 8, cos(th2) * 8);
    final leg = Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(knee.dx, knee.dy)
      ..lineTo(foot.dx, foot.dy);
    c.drawPath(leg, _l(line, 6.6));
    c.drawPath(leg, _l(col, 4.8));
    final hoof = Rect.fromCenter(center: foot.translate(1.4, 1), width: 6.6, height: 4.2);
    c.drawOval(hoof, _f(a == Animal.tigre || a == Animal.cocodrilo ? col : accent));
    c.drawOval(hoof, _l(line, .8));
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100);
    c.drawOval(Rect.fromCenter(center: const Offset(48, 94), width: 56, height: 6), _f(const Color(0x22000000)));
    double f1, f2, h1, h2;
    if (air) {
      f1 = .95;
      f2 = .55;
      h1 = -.95;
      h2 = -.55;
    } else {
      f1 = sin(ph) * .8;
      f2 = sin(ph + 2.2) * .8;
      h1 = sin(ph + pi) * .8;
      h2 = sin(ph + pi + 2.2) * .8;
    }
    _leg(c, 62, f2, true);
    _leg(c, 31, h2, true);
    final sway = sin(ph * .5) * 4;
    // cola
    switch (a) {
      case Animal.cerdo:
        c.drawPath(Path()..moveTo(24, 58)..cubicTo(14, 54, 12, 42, 20, 44)..cubicTo(26, 46, 22, 52, 18, 50), _l(line, 2.6));
        break;
      case Animal.unicornio:
        const cols = [Color(0xFFFFA8CC), Color(0xFFFFE27A), Color(0xFF9AD1FF), Color(0xFFC9B3F5), Color(0xFFFFA8CC)];
        for (int i = 0; i < cols.length; i++) {
          final tp = Path()
            ..moveTo(24, 56)
            ..cubicTo(12.0 - i, 54 + sway, 4, 66.0 + i * 2 + sway, 8.0 + i * 2, 84.0 - i);
          c.drawPath(tp, _l(line, 6.4));
          c.drawPath(tp, _l(cols[i], 4.4));
        }
        break;
      case Animal.tigre:
        final tigerTail = Path()
          ..moveTo(24, 58)
          ..cubicTo(10, 58 + sway * .3, 4, 44, 12, 34);
        c.drawPath(tigerTail, _l(line, 7));
        c.drawPath(tigerTail, _l(base, 5));
        c.drawPath(Path()..moveTo(7, 42)..cubicTo(6, 38, 9, 36, 12, 34), _l(const Color(0xFF3A2A1E), 5));
        break;
      default:
        c.drawPath(
            Path()
              ..moveTo(28, 52)
              ..quadraticBezierTo(10, 56 + sway * .5, 2, 72)
              ..quadraticBezierTo(14, 68, 28, 68)
              ..close(),
            _f(base));
        c.drawPath(Path()..moveTo(28, 52)..quadraticBezierTo(10, 56 + sway * .5, 2, 72)..quadraticBezierTo(14, 68, 28, 68), _l(line, 1.3));
        c.drawPath(Path()..moveTo(2, 72)..lineTo(-2, 66)..lineTo(6, 70)..close(), _f(accent));
    }
    // cuerpo
    final body = Rect.fromCenter(center: const Offset(46, 60), width: 50, height: 30);
    if (a == Animal.cocodrilo) {
      for (int i = 0; i < 5; i++) {
        final x = 28.0 + i * 8;
        c.drawPath(Path()..moveTo(x, 47)..lineTo(x + 4, 38)..lineTo(x + 8, 47)..close(), _f(accent));
      }
      final fl = sin(ph) * .25;
      c.save();
      c.translate(42, 48);
      c.rotate(-fl);
      c.drawPath(Path()..moveTo(0, 0)..quadraticBezierTo(-10, -24, -26, -16)..quadraticBezierTo(-14, -8, -10, 2)..close(), _f(light));
      c.drawPath(Path()..moveTo(0, 0)..quadraticBezierTo(-10, -24, -26, -16)..quadraticBezierTo(-14, -8, -10, 2), _l(line, 1.1));
      c.restore();
    }
    c.drawOval(body, _g(body, light, base));
    c.save();
    c.clipPath(Path()..addOval(body));
    c.drawOval(Rect.fromCenter(center: const Offset(48, 68), width: 40, height: 16), _f(light.withAlpha(150)));
    if (a == Animal.tigre) {
      for (final x in [29.0, 36.0, 43.0, 50.0, 57.0]) {
        c.drawPath(Path()..moveTo(x, 44)..quadraticBezierTo(x + 3, 58, x - 1, 76), _l(const Color(0xFF3A2A1E), 3));
      }
    }
    c.restore();
    c.drawOval(body, _l(line, 1.4));
    _leg(c, 60, f1, false);
    _leg(c, 28, h1, false);
    // crin flamante del unicornio
    if (a == Animal.unicornio) {
      const mc = [Color(0xFFFF6B8B), Color(0xFFFFB04C), Color(0xFFFFE066), Color(0xFF7DDFA8), Color(0xFF7ED6FF), Color(0xFFB59CFF)];
      for (int i = 0; i < mc.length; i++) {
        final b = Offset(66.0 - i * 3.6, 40.0 + i * 1.6);
        final ang = -2.3 + .15 * sin(ph * 1.5 - i * .6) - i * .05;
        final d = Offset(cos(ang), sin(ang));
        final n = Offset(-d.dy, d.dx);
        final tip = b + d * 14;
        final fl = Path()
          ..moveTo(b.dx - n.dx * 3, b.dy - n.dy * 3)
          ..quadraticBezierTo(b.dx + d.dx * 8 - n.dx * 4, b.dy + d.dy * 8 - n.dy * 4, tip.dx, tip.dy)
          ..quadraticBezierTo(b.dx + d.dx * 7 + n.dx * 4, b.dy + d.dy * 7 + n.dy * 4, b.dx + n.dx * 3, b.dy + n.dy * 3)
          ..close();
        c.drawPath(fl, _f(mc[i]));
        c.drawPath(fl, _l(Color.lerp(mc[i], Colors.black, .35)!, .7));
      }
    }
    // cabeza
    final head = Rect.fromCenter(center: const Offset(74, 46), width: 27, height: 26);
    switch (a) {
      case Animal.cerdo:
        c.drawPath(Path()..moveTo(66, 37)..lineTo(69, 26)..lineTo(77, 36)..close(), _f(accent));
        c.drawPath(Path()..moveTo(66, 37)..lineTo(69, 26)..lineTo(77, 36)..close(), _l(line, 1));
        break;
      case Animal.unicornio:
        final horn = Path()..moveTo(73, 37)..lineTo(89, 15)..lineTo(80, 38)..close();
        c.drawPath(horn, _f(const Color(0xFFFFF3C4)));
        c.drawPath(horn, _l(const Color(0xFFB8964A), 1));
        c.drawPath(Path()..moveTo(66, 37)..lineTo(68, 24)..lineTo(75, 36)..close(), _f(base));
        c.drawPath(Path()..moveTo(66, 37)..lineTo(68, 24)..lineTo(75, 36)..close(), _l(line, 1));
        break;
      case Animal.tigre:
        c.drawCircle(const Offset(67, 36), 5, _f(base));
        c.drawCircle(const Offset(67, 36), 5, _l(line, 1));
        c.drawCircle(const Offset(67, 36), 2.4, _f(const Color(0xFFFFB6C8)));
        break;
      default:
        for (final x in [67.0, 74.0]) {
          c.drawPath(Path()..moveTo(x, 35)..lineTo(x + 2, 26)..lineTo(x + 5, 35)..close(), _f(accent));
        }
    }
    c.drawOval(head, _g(head, light, base));
    c.drawOval(head, _l(line, 1.4));
    final snout = Rect.fromCenter(center: Offset(a == Animal.cocodrilo ? 86 : 84.5, 51), width: a == Animal.cocodrilo ? 15 : 11, height: a == Animal.cocodrilo ? 10 : 9);
    c.drawOval(snout, _f(a == Animal.cerdo ? accent : (a == Animal.tigre ? const Color(0xFFFFFFFF) : light)));
    c.drawOval(snout, _l(line, 1));
    for (final dy in [-1.5, 1.5]) {
      c.drawCircle(Offset(a == Animal.cocodrilo ? 90 : 87.5, 51 + dy), .9, _f(line));
    }
    // ojo, mejilla y sonrisa
    if (sad) {
      c.drawLine(const Offset(74, 43), const Offset(80, 45), _l(ink, 1.6));
      c.drawLine(const Offset(74, 40), const Offset(80, 42.5), _l(ink, 1.3));
    } else {
      c.drawOval(Rect.fromCenter(center: const Offset(77, 43), width: 5.4, height: 7), _f(ink));
      c.drawCircle(const Offset(76.2, 41.2), 1.5, _f(Colors.white));
    }
    c.drawOval(Rect.fromCenter(center: const Offset(72, 52), width: 6, height: 4), _f(const Color(0x88FF6F9F)));
    c.drawArc(Rect.fromCenter(center: const Offset(80, 55), width: 6, height: 3.6), .2, 2.7, false, _l(ink, 1.1));
    c.restore();
  }

  @override
  bool shouldRepaint(_RunnerPainter o) => true;
}
