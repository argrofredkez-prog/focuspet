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
  Color get line => const {
        Animal.cerdo: Color(0xFF3A2A33),
        Animal.unicornio: Color(0xFF6E5C9E),
        Animal.tigre: Color(0xFF5A2A10),
        Animal.cocodrilo: Color(0xFF9A4A1E),
      }[a]!;
  Color get light => const {
        Animal.cerdo: Color(0xFFFFE1EA),
        Animal.unicornio: Color(0xFFFFFFFF),
        Animal.tigre: Color(0xFFFFB45A),
        Animal.cocodrilo: Color(0xFFFFD27A),
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
  Color _dk(Color c, [double k = .2]) => Color.lerp(c, Colors.black, k)!;

  void _leg(Canvas c, double hx, double hipY, double sw, double l1, double l2, double th, Color col, Color hoof,
      {bool far = false, bool stripe = false}) {
    final cc = far ? _dk(col) : col;
    final hip = Offset(hx, hipY);
    final knee = hip + Offset(sin(sw) * l1, cos(sw) * l1);
    final t2 = sw * .5 - .35;
    final foot = knee + Offset(sin(t2) * l2, cos(t2) * l2);
    final p = Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(knee.dx, knee.dy)
      ..lineTo(foot.dx, foot.dy);
    c.drawPath(p, _l(line, th + 1.8));
    c.drawPath(p, _l(cc, th));
    if (stripe) {
      c.drawLine(knee.translate(-th / 2, 0), knee.translate(th / 2, 0), _l(const Color(0xFF5A2A10), 1.6));
      c.drawLine(hip.translate(sin(sw) * l1 * .5 - th / 2, cos(sw) * l1 * .5), hip.translate(sin(sw) * l1 * .5 + th / 2, cos(sw) * l1 * .5), _l(const Color(0xFF5A2A10), 1.6));
    }
    final h = Rect.fromCenter(center: foot.translate(1.2, .8), width: th + 2.6, height: 4.4);
    c.drawOval(h, _f(far ? _dk(hoof) : hoof));
    c.drawOval(h, _l(line, .8));
  }

  void _eye(Canvas c, Offset o, double w, double h, {bool lash = false}) {
    if (sad) {
      c.drawLine(o.translate(-w / 2, -h * .1), o.translate(w / 2, h * .2), _l(ink, 1.5));
      return;
    }
    c.drawOval(Rect.fromCenter(center: o, width: w, height: h), _f(ink));
    c.drawCircle(o.translate(-w * .2, -h * .22), w * .26, _f(Colors.white));
    if (lash) {
      c.drawLine(o.translate(-w * .5, -h * .35), o.translate(-w * .95, -h * .6), _l(ink, 1.1));
      c.drawLine(o.translate(-w * .55, -h * .05), o.translate(-w * 1.05, -h * .12), _l(ink, 1.1));
    }
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100);
    c.drawOval(Rect.fromCenter(center: const Offset(48, 94), width: 60, height: 6), _f(const Color(0x22000000)));
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
    final sway = sin(ph * .5) * 4;
    switch (a) {
      case Animal.cerdo:
        _pig(c, f1, f2, h1, h2);
        break;
      case Animal.tigre:
        _tiger(c, f1, f2, h1, h2, sway);
        break;
      case Animal.unicornio:
        _unicorn(c, f1, f2, h1, h2, sway);
        break;
      default:
        _dragon(c, f1, f2, h1, h2, sway);
    }
    c.restore();
  }

  // ---------------- cerdo (rechoncho, orejas en punta, rabito rizado) ----------------
  void _pig(Canvas c, double f1, double f2, double h1, double h2) {
    const pink = Color(0xFFFFB3C7), dpink = Color(0xFFFF8FB0);
    _leg(c, 62, 64, f2, 7, 8, 5.4, pink, dpink, far: true);
    _leg(c, 30, 64, h2, 7, 8, 5.4, pink, dpink, far: true);
    c.drawPath(Path()..moveTo(15, 48)..cubicTo(8, 46, 5, 35, 12, 36)..cubicTo(19, 37, 16, 44, 11, 42), _l(line, 2.4));
    final body = Rect.fromCenter(center: const Offset(45, 52), width: 62, height: 40);
    c.drawOval(body, _g(body, light, pink));
    c.drawOval(body, _l(line, 1.8));
    for (final o in const [Offset(34, 44), Offset(47, 40), Offset(55, 60), Offset(30, 56)]) {
      c.drawLine(o, o.translate(3, 2), _l(line.withAlpha(150), 1));
    }
    _leg(c, 58, 64, f1, 7, 8, 5.4, pink, dpink);
    _leg(c, 26, 64, h1, 7, 8, 5.4, pink, dpink);
    final ear1 = Path()..moveTo(64, 40)..lineTo(66, 24)..lineTo(75, 36)..close();
    final ear2 = Path()..moveTo(74, 36)..quadraticBezierTo(82, 22, 93, 22)..quadraticBezierTo(87, 32, 83, 43)..close();
    for (final e in [ear1, ear2]) {
      c.drawPath(e, _f(pink));
      c.drawPath(e, _l(line, 1.5));
    }
    final head = Rect.fromCenter(center: const Offset(77, 50), width: 30, height: 28);
    c.drawOval(head, _g(head, light, pink));
    c.drawOval(head, _l(line, 1.8));
    final snout = Rect.fromCenter(center: const Offset(91, 55), width: 11, height: 10);
    c.drawOval(snout, _f(dpink));
    c.drawOval(snout, _l(line, 1.4));
    for (final dy in [-1.6, 1.6]) {
      c.drawOval(Rect.fromCenter(center: Offset(91.5, 55 + dy), width: 1.6, height: 2.6), _f(line));
    }
    _eye(c, const Offset(82, 46), 5.5, 4.2, lash: true);
    c.drawOval(Rect.fromCenter(center: const Offset(77, 55), width: 7, height: 4.5), _f(const Color(0x88FF6F9F)));
    c.drawArc(Rect.fromCenter(center: const Offset(85, 61), width: 9, height: 5), .2, 2.6, false, _l(line, 1.4));
  }

  // ---------------- tigre (alargado, muchas rayas, cola larga) ----------------
  void _tiger(Canvas c, double f1, double f2, double h1, double h2, double sway) {
    const org = Color(0xFFFF8A1E), cream = Color(0xFFFFE6BE), dark = Color(0xFF5A2A10);
    _leg(c, 62, 62, f2, 13, 13, 5.6, org, cream, far: true, stripe: true);
    _leg(c, 28, 62, h2, 13, 13, 5.6, org, cream, far: true, stripe: true);
    final tail = Path()..moveTo(14, 50)..cubicTo(3, 48 + sway * .3, -1, 66, 8, 76)..cubicTo(14, 83, 24, 76, 19, 68);
    c.drawPath(tail, _l(line, 5.8));
    c.drawPath(tail, _l(org, 4));
    for (final o in const [Offset(3, 58), Offset(4, 68)]) {
      c.drawLine(o.translate(-2.2, 0), o.translate(2.8, 0), _l(dark, 2));
    }
    c.drawPath(Path()..moveTo(8, 76)..cubicTo(14, 83, 24, 76, 19, 68), _l(dark, 4));
    final body = Rect.fromCenter(center: const Offset(44, 52), width: 68, height: 27);
    c.drawOval(body, _g(body, light, org));
    c.save();
    c.clipPath(Path()..addOval(body));
    c.drawOval(Rect.fromCenter(center: const Offset(46, 62), width: 56, height: 12), _f(cream));
    for (int i = 0; i < 12; i++) {
      final x = 14.0 + i * 5.0;
      c.drawPath(Path()..moveTo(x, 38)..quadraticBezierTo(x + 3, 50, x - 2, 62), _l(dark, 2.3));
    }
    c.restore();
    c.drawOval(body, _l(line, 1.6));
    _leg(c, 60, 62, f1, 13, 13, 5.6, org, cream, stripe: true);
    _leg(c, 31, 62, h1, 13, 13, 5.6, org, cream, stripe: true);
    final neck = Rect.fromCenter(center: const Offset(72, 47), width: 22, height: 22);
    c.drawOval(neck, _g(neck, light, org));
    final head = Rect.fromCenter(center: const Offset(82, 40), width: 22, height: 20);
    c.drawCircle(const Offset(76, 32), 4.4, _f(org));
    c.drawCircle(const Offset(76, 32), 4.4, _l(line, 1.1));
    c.drawCircle(const Offset(76, 32), 2, _f(const Color(0xFFFFC2C8)));
    c.drawOval(head, _g(head, light, org));
    c.drawOval(head, _l(line, 1.6));
    c.drawPath(Path()..moveTo(76, 47)..lineTo(80, 55)..lineTo(86, 50)..close(), _f(cream));
    final muz = Rect.fromCenter(center: const Offset(91, 44), width: 13, height: 9);
    c.drawOval(muz, _f(cream));
    c.drawOval(muz, _l(line, 1));
    c.drawCircle(const Offset(96, 42), 1.8, _f(const Color(0xFFE8788A)));
    for (final x in [78.0, 82.0, 86.0]) {
      c.drawLine(Offset(x, 31), Offset(x + 1, 35), _l(dark, 1.6));
    }
    _eye(c, const Offset(86, 39), 4.6, 3.6);
    c.drawArc(Rect.fromCenter(center: const Offset(90, 48), width: 8, height: 4), .2, 2.6, false, _l(line, 1.1));
  }

  // ---------------- unicornio (chibi, cuerno dorado, crin y cola arcoíris) ----------------
  void _unicorn(Canvas c, double f1, double f2, double h1, double h2, double sway) {
    const white = Color(0xFFF4F0FF), gold = Color(0xFFFFC93C);
    const rb = [Color(0xFFFF8FB8), Color(0xFF7ED6FF), Color(0xFFC9B3F5), Color(0xFFFFE27A)];
    _leg(c, 54, 68, f2, 11, 11, 4.2, white, gold, far: true);
    _leg(c, 26, 68, h2, 11, 11, 4.2, white, gold, far: true);
    for (int i = 0; i < 4; i++) {
      final tp = Path()
        ..moveTo(22, 54)
        ..cubicTo(8.0 - i, 50 + sway, 1, 66.0 + i * 2, 10.0 + i * 3, 80.0 - i)
        ..cubicTo(14.0 + i * 3, 86, 20.0 + i * 3, 80, 17.0 + i * 3, 76);
      c.drawPath(tp, _l(line, 6.4));
      c.drawPath(tp, _l(rb[(i + 2) % 4], 4.4));
    }
    final body = Rect.fromCenter(center: const Offset(42, 60), width: 44, height: 28);
    c.drawOval(body, _g(body, Colors.white, white));
    c.drawOval(body, _l(line, 1.5));
    c.drawPath(_heart(const Offset(30, 58), 2.6), _f(const Color(0xFFFF7EB6)));
    _leg(c, 58, 68, f1, 11, 11, 4.2, white, gold);
    _leg(c, 31, 68, h1, 11, 11, 4.2, white, gold);
    final neck = Rect.fromCenter(center: const Offset(62, 48), width: 18, height: 28);
    c.drawOval(neck, _g(neck, Colors.white, white));
    for (int i = 0; i < 4; i++) {
      final m = Path()
        ..moveTo(70, 27.0 + i * 1.4)
        ..cubicTo(58, 22.0 + i * 2, 47, 32.0 + i * 3, 50.0 - i, 52.0 + i * 3 + sway * .5);
      c.drawPath(m, _l(line, 6.2));
      c.drawPath(m, _l(rb[i], 4.2));
    }
    final head = Rect.fromCenter(center: const Offset(71, 40), width: 26, height: 24);
    final horn = Path()..moveTo(74, 29)..lineTo(93, 2)..lineTo(79, 31)..close();
    c.drawPath(horn, _f(const Color(0xFFFFE27A)));
    for (int i = 0; i < 5; i++) {
      final k = 1.0 + i * 4.8;
      c.drawLine(Offset(74.0 + k, 28.0 - k * 1.3), Offset(79.0 + k, 29.0 - k * 1.3), _l(const Color(0xFFB8964A), 1));
    }
    c.drawPath(horn, _l(const Color(0xFFB8964A), 1));
    final ear = Path()..moveTo(65, 31)..lineTo(66, 16)..lineTo(74, 29)..close();
    c.drawPath(ear, _f(white));
    c.drawPath(ear, _l(line, 1.2));
    c.drawPath(Path()..moveTo(67, 28)..lineTo(67.5, 20)..lineTo(72, 28)..close(), _f(const Color(0xFFFFC2DB)));
    c.drawOval(head, _g(head, Colors.white, white));
    c.drawOval(head, _l(line, 1.5));
    final muz = Rect.fromCenter(center: const Offset(80, 47), width: 12, height: 9);
    c.drawOval(muz, _f(Colors.white));
    c.drawOval(muz, _l(line, 1));
    c.drawOval(Rect.fromCenter(center: const Offset(82, 46), width: 1.6, height: 2.4), _f(line));
    _eye(c, const Offset(75, 38), 7, 9, lash: true);
    c.drawCircle(const Offset(73, 36), 1.4, _f(const Color(0xDDFFFFFF)));
    c.drawOval(Rect.fromCenter(center: const Offset(71, 47), width: 7, height: 4.5), _f(const Color(0x88FF6F9F)));
    c.drawArc(Rect.fromCenter(center: const Offset(79, 51), width: 6, height: 3.4), .2, 2.6, false, _l(line, 1));
  }

  Path _heart(Offset o, double r) => Path()
    ..moveTo(o.dx, o.dy + r * .9)
    ..cubicTo(o.dx - r * 1.6, o.dy - r * .2, o.dx - r * .7, o.dy - r * 1.2, o.dx, o.dy - r * .4)
    ..cubicTo(o.dx + r * .7, o.dy - r * 1.2, o.dx + r * 1.6, o.dy - r * .2, o.dx, o.dy + r * .9)
    ..close();

  // ---------------- dragón (cuello largo, cuernos, ala de murciélago, cola enroscada) ----------------
  void _dragon(Canvas c, double f1, double f2, double h1, double h2, double sway) {
    const org = Color(0xFFFFAA33), belly = Color(0xFFFFF0C8), rib = Color(0xFFC2502A), spike = Color(0xFFD9552A);
    final fl = sin(ph) * .2;
    // ala lejana y ala principal
    for (final big in [false, true]) {
      c.save();
      c.translate(big ? 46 : 54, 48);
      c.rotate(-fl * (big ? 1 : .6));
      final k = big ? 1.0 : .62;
      final w = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(6 * k, -30 * k, 34 * k, -44 * k)
        ..lineTo(30 * k, -30 * k)
        ..lineTo(38 * k, -18 * k)
        ..lineTo(26 * k, -12 * k)
        ..lineTo(24 * k, -2 * k)
        ..close();
      c.drawPath(w, _f(big ? const Color(0xFFFFB347) : const Color(0xFFE08A2E)));
      c.drawPath(w, _l(rib, 1.3));
      c.drawLine(Offset.zero, Offset(34 * k, -44 * k), _l(rib, 1.8));
      c.drawLine(Offset.zero, Offset(30 * k, -30 * k), _l(rib, 1.2));
      c.drawLine(Offset.zero, Offset(26 * k, -12 * k), _l(rib, 1.2));
      c.restore();
    }
    _leg(c, 60, 70, f2, 7, 8, 5.8, org, belly, far: true);
    _leg(c, 30, 70, h2, 7, 8, 5.8, org, belly, far: true);
    // cola enroscada con púas
    final tail = Path()..moveTo(20, 64)..cubicTo(6, 66, 0, 82, 12, 84)..cubicTo(21, 86, 25, 76, 19, 72);
    c.drawPath(tail, _l(line, 9));
    c.drawPath(tail, _l(org, 7));
    c.drawPath(tail, _l(const Color(0x55FFFFFF), 2));
    for (final o in const [Offset(14, 62), Offset(6, 70), Offset(5, 79)]) {
      c.drawPath(Path()..moveTo(o.dx - 2, o.dy)..lineTo(o.dx - 5, o.dy - 5)..lineTo(o.dx + 2, o.dy - 1)..close(), _f(spike));
    }
    final body = Rect.fromCenter(center: const Offset(44, 62), width: 56, height: 28);
    c.drawOval(body, _g(body, light, org));
    c.drawOval(Rect.fromCenter(center: const Offset(46, 70), width: 44, height: 11), _f(belly));
    c.drawOval(body, _l(line, 1.6));
    for (int i = 0; i < 5; i++) {
      final x = 26.0 + i * 7;
      c.drawPath(Path()..moveTo(x, 49)..lineTo(x + 3, 41)..lineTo(x + 7, 49)..close(), _f(spike));
    }
    _leg(c, 56, 70, f1, 7, 8, 5.8, org, belly);
    _leg(c, 27, 70, h1, 7, 8, 5.8, org, belly);
    // cuello
    final neck = Path()..moveTo(62, 62)..cubicTo(74, 62, 70, 44, 79, 34);
    c.drawPath(neck, _l(line, 14.5));
    c.drawPath(neck, _l(org, 12.5));
    c.drawPath(Path()..moveTo(66, 64)..cubicTo(77, 64, 73, 46, 82, 36), _l(belly, 4.5));
    for (final o in const [Offset(70, 56), Offset(72, 49), Offset(76, 42)]) {
      c.drawLine(o, o.translate(4, -1), _l(const Color(0xFFE6CC95), 1));
    }
    for (final o in const [Offset(66, 54), Offset(67, 46), Offset(71, 39)]) {
      c.drawPath(Path()..moveTo(o.dx, o.dy)..lineTo(o.dx - 5, o.dy - 3)..lineTo(o.dx - 1, o.dy + 3)..close(), _f(spike));
    }
    // cabeza
    for (final h in const [[79.0, 21.0, 71.0, 6.0], [84.0, 20.0, 79.0, 4.0]]) {
      c.drawPath(Path()..moveTo(h[0], h[1])..quadraticBezierTo(h[0] - 4, h[1] - 6, h[2], h[3])..quadraticBezierTo(h[0] + 1, h[1] - 6, h[0] + 4, h[1] + 1)..close(), _f(const Color(0xFFFFF0C8)));
      c.drawPath(Path()..moveTo(h[0], h[1])..quadraticBezierTo(h[0] - 4, h[1] - 6, h[2], h[3]), _l(line, 1));
    }
    final head = Rect.fromCenter(center: const Offset(85, 28), width: 20, height: 14);
    c.drawOval(head, _g(head, light, org));
    c.drawOval(head, _l(line, 1.5));
    final snout = Rect.fromCenter(center: const Offset(93, 31), width: 12, height: 9);
    c.drawOval(snout, _f(light));
    c.drawOval(snout, _l(line, 1.2));
    c.drawCircle(const Offset(97, 29), .9, _f(line));
    if (sad) {
      c.drawLine(const Offset(83, 26), const Offset(89, 27.5), _l(ink, 1.4));
    } else {
      c.drawCircle(const Offset(87, 26), 3, _f(Colors.white));
      c.drawCircle(const Offset(87, 26), 2.1, _f(const Color(0xFF3F8FE0)));
      c.drawCircle(const Offset(87.4, 26), 1.1, _f(ink));
      c.drawCircle(const Offset(86.4, 25.2), .7, _f(Colors.white));
    }
    c.drawArc(Rect.fromCenter(center: const Offset(92, 33), width: 9, height: 4.5), .2, 2.6, false, _l(line, 1.1));
    c.drawOval(Rect.fromCenter(center: const Offset(82, 31), width: 5, height: 3.4), _f(const Color(0x88FF6F9F)));
  }

  @override
  bool shouldRepaint(_RunnerPainter o) => true;
}
