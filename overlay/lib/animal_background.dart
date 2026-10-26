import 'dart:math';
import 'package:flutter/material.dart';
import 'focus_animal.dart';

const _skies = {
  Animal.cerdo: [Color(0xFF8ECDF5), Color(0xFFDFF3FF)],
  Animal.unicornio: [Color(0xFFB9CCF7), Color(0xFFDCCBF2)],
  Animal.tigre: [Color(0xFFBDE8E2), Color(0xFFE8F7E0)],
  Animal.cocodrilo: [Color(0xFF7CC8F5), Color(0xFF2B6BC4)],
};

/// Fondo animado por animal: granja, nubes kawaii, selva y fondo marino.
/// scene: 0 día, 1 atardecer, 2 noche.
class AnimalBackground extends StatefulWidget {
  final Animal animal;
  final Widget child;
  final int scene;
  const AnimalBackground(
      {super.key, required this.animal, required this.child, this.scene = 0});

  @override
  State<AnimalBackground> createState() => _AnimalBackgroundState();
}

class _AnimalBackgroundState extends State<AnimalBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 30))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(
                  painter: _BgPainter(widget.animal, _c.value, widget.scene)),
            ),
          ),
        ),
        widget.child,
      ]);
}

class _BgPainter extends CustomPainter {
  final Animal animal;
  final double t;
  final int scene;
  _BgPainter(this.animal, this.t, this.scene);

  double _r(int i, int k) =>
      (sin(i * 12.9898 + k * 78.233) * 43758.5453).abs() % 1.0;

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _skies[animal]!)
              .createShader(rect));
    switch (animal) {
      case Animal.cerdo:
        _farm(canvas, s);
        break;
      case Animal.unicornio:
        _uni(canvas, s);
        break;
      case Animal.tigre:
        _jungle(canvas, s);
        break;
      case Animal.cocodrilo:
        _sea(canvas, s);
        break;
    }
    _tint(canvas, s);
  }

  // ---------- piezas comunes ----------
  void _cloud(Canvas c, Offset o, double k, Paint p) {
    c.drawCircle(o, 22 * k, p);
    c.drawCircle(o.translate(24 * k, -8 * k), 28 * k, p);
    c.drawCircle(o.translate(52 * k, 0), 22 * k, p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(o.dx - 22 * k, o.dy, 96 * k, 22 * k), Radius.circular(11 * k)),
        p);
  }

  void _clouds(Canvas c, Size s, int n, int alpha) {
    final p = Paint()..color = Colors.white.withAlpha(alpha);
    for (int i = 0; i < n; i++) {
      final x = ((_r(i, 1) + t * (1 + i % 2)) % 1.0) * (s.width + 240) - 120;
      _cloud(c, Offset(x, s.height * (0.07 + 0.1 * i)), 0.8 + 0.4 * _r(i, 2), p);
    }
  }

  Path _sparkle(Offset c, double r) {
    final p = Path();
    p.moveTo(c.dx, c.dy - r);
    p.quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy);
    p.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r);
    p.quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy);
    p.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
    p.close();
    return p;
  }

  void _leaf(Canvas c, Offset b, double len, double ang, Color col) {
    c.save();
    c.translate(b.dx, b.dy);
    c.rotate(ang);
    final p = Path()
      ..quadraticBezierTo(len * 0.3, -len * 0.28, len, 0)
      ..quadraticBezierTo(len * 0.3, len * 0.28, 0, 0);
    c.drawPath(p, Paint()..color = col);
    c.restore();
  }

  Path _wave(Size s, double y, double amp, double phase, double freq) {
    final p = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, y);
    for (double x = 0; x <= s.width; x += 8) {
      p.lineTo(x, y + sin((x / s.width * freq + phase) * 2 * pi) * amp);
    }
    p.lineTo(s.width, s.height);
    p.close();
    return p;
  }

  void _mountain(Canvas c, double cx, double baseY, double w, double h, Color col) {
    c.drawPath(
        Path()
          ..moveTo(cx - w / 2, baseY)
          ..lineTo(cx, baseY - h)
          ..lineTo(cx + w / 2, baseY)
          ..close(),
        Paint()..color = col);
  }

  // ---------- 🐷 Granja ----------
  void _farm(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _clouds(c, s, 3, 235);

    final bird = Paint()
      ..color = const Color(0xFF55606E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final x = ((_r(i, 8) + t * (1 + i % 2)) % 1.0) * (w + 80) - 40;
      final y = h * (0.1 + 0.07 * i) + sin((t * 3 + i) * 2 * pi) * 5;
      c.drawPath(
          Path()
            ..moveTo(x - 8, y)
            ..quadraticBezierTo(x - 4, y - 6, x, y)
            ..quadraticBezierTo(x + 4, y - 6, x + 8, y),
          bird);
    }

    c.drawOval(
        Rect.fromCenter(center: Offset(w * 0.7, h * 0.66), width: w * 1.5, height: h * 0.26),
        Paint()..color = const Color(0xFFB9E37E));

    // granero
    final bx = w * 0.7, by = h * 0.6, bw = w * 0.3, bh = h * 0.1;
    final red = Paint()
      ..color = const Color(0xFFE04B4B)
      ..strokeWidth = 2;
    c.drawRect(Rect.fromLTWH(bx - bw / 2, by - bh, bw, bh), red);
    c.drawPath(
        Path()
          ..moveTo(bx - bw / 2 - 6, by - bh)
          ..lineTo(bx - bw * 0.35, by - bh - h * 0.045)
          ..lineTo(bx + bw * 0.35, by - bh - h * 0.045)
          ..lineTo(bx + bw / 2 + 6, by - bh)
          ..close(),
        Paint()..color = const Color(0xFFB83232));
    c.drawRect(Rect.fromLTWH(bx - bw * 0.14, by - bh * 0.7, bw * 0.28, bh * 0.7),
        Paint()..color = Colors.white);
    c.drawLine(Offset(bx - bw * 0.14, by - bh * 0.7), Offset(bx + bw * 0.14, by), red);
    c.drawLine(Offset(bx + bw * 0.14, by - bh * 0.7), Offset(bx - bw * 0.14, by), red);

    c.drawOval(
        Rect.fromCenter(center: Offset(w * 0.2, h * 0.78), width: w * 1.5, height: h * 0.3),
        Paint()..color = const Color(0xFF8ED46B));
    c.drawOval(
        Rect.fromCenter(center: Offset(w * 0.8, h * 1.0), width: w * 1.6, height: h * 0.36),
        Paint()..color = const Color(0xFF6CC35C));

    // camino
    c.drawPath(
        Path()
          ..moveTo(w * 0.40, h)
          ..quadraticBezierTo(w * 0.5, h * 0.8, w * 0.64, h * 0.62)
          ..lineTo(w * 0.70, h * 0.62)
          ..quadraticBezierTo(w * 0.62, h * 0.82, w * 0.78, h)
          ..close(),
        Paint()..color = const Color(0xFFF3D9A4));

    // árboles con flores blancas
    void tree(double x, double y, double k) {
      c.drawRect(Rect.fromLTWH(x - 6 * k, y - 40 * k, 12 * k, 40 * k),
          Paint()..color = const Color(0xFF8B5A3C));
      final leaf = Paint()..color = const Color(0xFF9BD96A);
      c.drawCircle(Offset(x, y - 70 * k), 38 * k, leaf);
      c.drawCircle(Offset(x - 30 * k, y - 50 * k), 28 * k, leaf);
      c.drawCircle(Offset(x + 30 * k, y - 50 * k), 28 * k, leaf);
      final fl = Paint()..color = Colors.white;
      for (int i = 0; i < 7; i++) {
        c.drawCircle(
            Offset(x + (_r(i, 11) - 0.5) * 90 * k, y - 45 * k - _r(i, 12) * 50 * k),
            4 * k,
            fl);
      }
    }

    tree(w * 0.14, h * 0.62, 1.4);
    tree(w * 0.38, h * 0.56, 0.9);

    // ovejas
    final wool = Paint()..color = Colors.white;
    for (int i = 0; i < 2; i++) {
      final x = w * (0.45 + 0.22 * i);
      final y = h * (0.74 + 0.03 * i) + sin((t * 2 + i) * 2 * pi) * 1.5;
      c.drawCircle(Offset(x, y), 16, wool);
      c.drawCircle(Offset(x - 12, y + 2), 12, wool);
      c.drawCircle(Offset(x + 12, y + 2), 12, wool);
      c.drawCircle(Offset(x + 20, y - 4), 8, Paint()..color = const Color(0xFF55606E));
    }

    // valla y florecitas
    final fence = Paint()..color = Colors.white;
    for (double x = w * 0.58; x < w; x += 24) {
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, h * 0.9, 10, 46), const Radius.circular(3)),
          fence);
    }
    c.drawRect(Rect.fromLTWH(w * 0.58, h * 0.915, w * 0.42, 6), fence);
    c.drawRect(Rect.fromLTWH(w * 0.58, h * 0.945, w * 0.42, 6), fence);
    for (int i = 0; i < 10; i++) {
      final x = w * _r(i, 13);
      final y = h * (0.86 + 0.1 * _r(i, 14));
      c.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
      c.drawCircle(Offset(x, y), 1.8, Paint()..color = const Color(0xFFFFD166));
    }
  }

  // ---------- 🦄 Nubes kawaii pastel ----------
  void _kawaiiCloud(Canvas c, Offset o, double k, Color col) {
    _cloud(c, o, k, Paint()..color = col);
    final cx = o.dx + 26 * k, cy = o.dy + 4 * k;
    final line = Paint()
      ..color = const Color(0xFF6B5B95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * k
      ..strokeCap = StrokeCap.round;
    for (final d in [-1, 1]) {
      c.drawArc(Rect.fromCenter(center: Offset(cx + d * 13 * k, cy), width: 9 * k, height: 7 * k),
          0, pi, false, line);
      c.drawCircle(Offset(cx + d * 22 * k, cy + 8 * k), 5 * k,
          Paint()..color = const Color(0xFFFFA3C7).withAlpha(170));
    }
    c.drawArc(Rect.fromCenter(center: Offset(cx, cy + 6 * k), width: 8 * k, height: 6 * k),
        0, pi, false, line);
  }

  void _uni(Canvas c, Size s) {
    final w = s.width, h = s.height;
    for (int i = 0; i < 40; i++) {
      c.drawCircle(Offset(w * _r(i, 1), h * _r(i, 2)), 1.5 + 2 * _r(i, 3),
          Paint()..color = Colors.white.withAlpha(190));
    }
    for (int i = 0; i < 9; i++) {
      final tw = 0.5 + 0.5 * sin((t * 2 + _r(i, 4)) * 2 * pi);
      final base = i.isEven ? Colors.white : const Color(0xFFFFB6D5);
      c.drawPath(_sparkle(Offset(w * _r(i, 5), h * _r(i, 6)), 5 + 5 * _r(i, 7)),
          Paint()..color = base.withAlpha((120 + 135 * tw).round()));
    }
    for (int i = 0; i < 8; i++) {
      final x = w * (0.02 + 0.62 * ((i * 0.37) % 1.0)) + sin((t + _r(i, 8)) * 2 * pi) * 10;
      final y = h * (0.04 + 0.115 * i) + cos((t + _r(i, 9)) * 2 * pi) * 5;
      _kawaiiCloud(c, Offset(x, y), 0.8 + 0.4 * _r(i, 10),
          i % 3 == 1 ? const Color(0xFFFFC6DD) : Colors.white);
    }
  }

  // ---------- 🐯 Selva con río y montañas ----------
  void _jungle(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _clouds(c, s, 2, 210);
    _mountain(c, w * 0.30, h * 0.46, w * 0.7, h * 0.2, const Color(0xFF9AD6B0));
    _mountain(c, w * 0.72, h * 0.46, w * 0.8, h * 0.26, const Color(0xFF7CC59A));
    _mountain(c, w * 0.5, h * 0.5, w * 0.9, h * 0.16, const Color(0xFF4FA878));
    c.drawRect(Rect.fromLTWH(0, h * 0.48, w, h * 0.52), Paint()..color = const Color(0xFF58B36A));

    c.drawPath(
        Path()
          ..moveTo(w * 0.47, h * 0.48)
          ..quadraticBezierTo(w * 0.15, h * 0.62, w * 0.36, h * 0.76)
          ..quadraticBezierTo(w * 0.5, h * 0.9, w * 0.28, h)
          ..lineTo(w * 0.88, h)
          ..quadraticBezierTo(w * 0.62, h * 0.86, w * 0.72, h * 0.72)
          ..quadraticBezierTo(w * 0.84, h * 0.58, w * 0.53, h * 0.48)
          ..close(),
        Paint()..color = const Color(0xFF6EDCC8));
    final shine = Paint()
      ..color = Colors.white.withAlpha(150)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final p = (_r(i, 3) + t * (1 + i % 2)) % 1.0;
      final y = h * (0.52 + 0.46 * p);
      final x = w * (0.42 + 0.2 * _r(i, 4)) + p * w * 0.05;
      c.drawLine(Offset(x, y), Offset(x + 18 + 20 * p, y), shine);
    }

    final rock = Paint()..color = const Color(0xFF5C6F8A);
    c.drawOval(Rect.fromCenter(center: Offset(w * 0.2, h * 0.78), width: 80, height: 46), rock);
    c.drawOval(Rect.fromCenter(center: Offset(w * 0.7, h * 0.9), width: 100, height: 56), rock);

    void palm(double x, double y, double k, int seed) {
      final trunk = Paint()
        ..color = const Color(0xFF8B5E3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9 * k
        ..strokeCap = StrokeCap.round;
      final top = Offset(x + 14 * k, y - 150 * k);
      c.drawPath(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(x - 10 * k, y - 80 * k, top.dx, top.dy),
          trunk);
      for (int i = 0; i < 6; i++) {
        final ang = -pi * (0.1 + 0.16 * i) + sin((t + i * 0.1 + seed * 0.3) * 2 * pi) * 0.05;
        _leaf(c, top, 70 * k, ang,
            i.isEven ? const Color(0xFF2E9B5F) : const Color(0xFF3DB06E));
      }
    }

    palm(w * 0.82, h * 0.7, 1.0, 1);
    palm(w * 0.12, h * 0.6, 0.9, 2);
    palm(w * 0.93, h * 0.55, 0.7, 3);

    final dark = Paint()..color = const Color(0xFF2F8F52);
    c.drawCircle(Offset(w * 0.02, h * 0.1), 80, dark);
    c.drawCircle(Offset(w * 0.98, h * 0.08), 90, dark);

    for (int side = 0; side < 2; side++) {
      final b = Offset(side == 0 ? w * 0.08 : w * 0.92, h + 8);
      for (int i = 0; i < 4; i++) {
        final ang = -pi / 2 + (i - 1.5) * 0.4 + sin((t + i * 0.15 + side * 0.5) * 2 * pi) * 0.05;
        _leaf(c, b, 110.0 + 25 * (i % 2), ang,
            i.isEven ? const Color(0xFF3FA35F) : const Color(0xFF2E8B57));
      }
    }
    for (int i = 0; i < 6; i++) {
      final x = w * (0.04 + 0.16 * i);
      final y = h * (0.94 + 0.03 * sin(i * 2.1));
      c.drawCircle(Offset(x, y), 7,
          Paint()..color = i.isEven ? const Color(0xFFFF8A3D) : const Color(0xFFE8445A));
      c.drawCircle(Offset(x, y), 2.5, Paint()..color = const Color(0xFFFFE08A));
    }
  }

  // ---------- 🐊 Fondo marino ----------
  void _sea(Canvas c, Size s) {
    final w = s.width, h = s.height;
    const up = [Color(0xFF8AD3F7), Color(0xFF66BDF2), Color(0xFF47A2E6)];
    for (int i = 0; i < 3; i++) {
      c.drawPath(_wave(s, h * (0.05 + 0.09 * i), 9.0 + 3 * i, t * (1 + i % 2) + i * 0.3, 2.0),
          Paint()..color = up[i]);
    }
    c.drawPath(_wave(s, h * 0.40, 14, t + 0.6, 1.5), Paint()..color = const Color(0xFF3585D6));

    for (int i = 0; i < 7; i++) {
      final base = Offset(w * (0.05 + 0.15 * i), h * 0.9);
      final ang = -pi / 2 + (i.isEven ? -0.25 : 0.25) + sin((t + i * 0.2) * 2 * pi) * 0.1;
      _leaf(c, base, 120.0 + 60 * _r(i, 2), ang, const Color(0xFF2FA39F).withAlpha(210));
    }
    c.drawPath(_wave(s, h * 0.82, 12, t * 2 + 0.2, 2.0), Paint()..color = const Color(0xFF2A62C0));
    c.drawPath(_wave(s, h * 0.92, 10, t + 0.5, 2.5), Paint()..color = const Color(0xFF1F4FA0));

    for (int i = 0; i < 14; i++) {
      final p = (_r(i, 3) + t * (1 + i % 3)) % 1.0;
      final x = w * _r(i, 4) + sin((p + _r(i, 5)) * 2 * pi) * 8;
      final y = h * (1.05 - 1.1 * p);
      final r = 6 + 16 * _r(i, 6);
      c.drawCircle(Offset(x, y), r, Paint()..color = Colors.white.withAlpha(45));
      c.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = Colors.white.withAlpha(150)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      c.drawCircle(Offset(x - r * 0.35, y - r * 0.35), r * 0.2,
          Paint()..color = Colors.white.withAlpha(200));
    }
  }

  // ---------- Atardecer / noche ----------
  void _tint(Canvas c, Size s) {
    final r = Offset.zero & s;
    if (scene == 1) {
      c.drawRect(
          r,
          Paint()
            ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66FF7EB3), Color(0xAAFF9A3D)]).createShader(r));
    } else if (scene == 3) {
      c.drawRect(
          r,
          Paint()
            ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66FFD166), Color(0x88FF8FB8)]).createShader(r));
    } else if (scene == 2) {
      c.drawRect(r, Paint()..color = const Color(0xB00B1040));
      for (int i = 0; i < 26; i++) {
        final tw = 0.5 + 0.5 * sin((t * 2 + _r(i, 1)) * 2 * pi);
        c.drawCircle(Offset(s.width * _r(i, 2), s.height * 0.8 * _r(i, 3)), 1 + 1.6 * _r(i, 4),
            Paint()..color = Colors.white.withAlpha((90 + 165 * tw).round()));
      }
      final m = Offset(s.width * 0.82, s.height * 0.1);
      c.drawCircle(m, 26, Paint()..color = const Color(0xFFFFF3B0));
      c.drawCircle(m.translate(9, -4), 22, Paint()..color = const Color(0xFF1A1F5C));
    }
  }

  @override
  bool shouldRepaint(_BgPainter o) => o.t != t || o.animal != animal || o.scene != scene;
}
