import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';
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
    if (scene >= 4) {
      _kawaii(canvas, s);
      return;
    }
    final rect = Offset.zero & s;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _skies[animal]!)
              .createShader(rect));
    if (scene == 0 || scene == 1) _sun(canvas, s);
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
    if (dimLevel > 0) {
      canvas.drawRect(rect, Paint()..color = Color.fromARGB((dimLevel * 255).round(), 0, 0, 0));
    }
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

  // Sol que recorre el cielo de 8:00 a 16:00 y se pone hasta las 20:00 (detrás de colinas y olas)
  void _sun(Canvas c, Size s) {
    final now = DateTime.now();
    final hf = now.hour + now.minute / 60;
    double x, y, r;
    Color core, glow;
    if (scene == 0) {
      final u = ((hf - 8) / 8).clamp(0.0, 1.0).toDouble();
      x = s.width * (0.1 + 0.8 * u);
      y = s.height * (0.2 - 0.1 * sin(pi * u));
      r = 20;
      core = const Color(0xFFFFE066);
      glow = const Color(0xFFFFD43B);
    } else {
      final u = ((hf - 16) / 4).clamp(0.0, 1.0).toDouble();
      x = s.width * (0.25 + 0.5 * u);
      y = s.height * (0.42 + 0.16 * u);
      r = 30;
      core = const Color(0xFFFF9A3D);
      glow = const Color(0xFFFF6B3D);
    }
    final o = Offset(x, y);
    c.drawCircle(o, r * 2.6, Paint()..color = glow.withAlpha(40));
    c.drawCircle(o, r * 1.8, Paint()..color = glow.withAlpha(70));
    if (scene == 0) {
      final ray = Paint()
        ..color = core
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 12; i++) {
        final a = i * pi / 6 + t * 2 * pi;
        final dir = Offset(cos(a), sin(a));
        c.drawLine(o + dir * (r + 5), o + dir * (r + 13), ray);
      }
    }
    c.drawCircle(o, r, Paint()..color = core);
  }

  // ---------- fondos kawaii (tienda) ----------
  Paint _p(Color c) => Paint()..color = c;

  Paint _st(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  void _gradBg(Canvas c, Size s, List<Color> cols) {
    final r = Offset.zero & s;
    c.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cols)
              .createShader(r));
  }

  void _kface(Canvas c, Offset o, double r) {
    final eye = _p(const Color(0xFF4A3B5C));
    c.drawCircle(o + Offset(-r * .32, -r * .05), r * .09 + .6, eye);
    c.drawCircle(o + Offset(r * .32, -r * .05), r * .09 + .6, eye);
    c.drawArc(Rect.fromCenter(center: o + Offset(0, r * .08), width: r * .26, height: r * .2), 0.2, pi - 0.4, false,
        _st(const Color(0xFF4A3B5C), max(1.0, r * .06)));
    final bl = _p(const Color(0x66FF8FB8));
    c.drawOval(Rect.fromCenter(center: o + Offset(-r * .55, r * .12), width: r * .3, height: r * .17), bl);
    c.drawOval(Rect.fromCenter(center: o + Offset(r * .55, r * .12), width: r * .3, height: r * .17), bl);
  }

  void _blob(Canvas c, Offset o, double r, Color col) {
    final p = _p(col);
    c.drawCircle(o, r, p);
    c.drawCircle(o + Offset(-r * .9, r * .25), r * .7, p);
    c.drawCircle(o + Offset(r * .9, r * .25), r * .7, p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(o.dx - r * 1.6, o.dy + r * .2, o.dx + r * 1.6, o.dy + r * .95), Radius.circular(r * .4)),
        p);
  }

  void _hill(Canvas c, Size s, Color col, double yf, double amp, double ph) {
    final p = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width; x += 6) {
      p.lineTo(x, s.height * yf + amp * sin(x / s.width * 2 * pi * 1.5 + ph));
    }
    p
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(p, _p(col));
  }

  Path _heartP(Offset o, double r) => Path()
    ..moveTo(o.dx, o.dy + r * .9)
    ..cubicTo(o.dx - r * 1.6, o.dy - r * .2, o.dx - r * .7, o.dy - r * 1.2, o.dx, o.dy - r * .4)
    ..cubicTo(o.dx + r * .7, o.dy - r * 1.2, o.dx + r * 1.6, o.dy - r * .2, o.dx, o.dy + r * .9);

  Path _sparkP(Offset o, double r) => Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r);

  void _sparkles(Canvas c, Size s, Color col, int n) {
    for (int i = 0; i < n; i++) {
      final tw = 0.5 + 0.5 * sin((t + _r(i, 7)) * 2 * pi);
      c.drawPath(_sparkP(Offset(s.width * _r(i, 5), s.height * .8 * _r(i, 6)), 3 + 4 * tw),
          _p(col.withAlpha((120 + 135 * tw).round())));
    }
  }

  void _kawaii(Canvas c, Size s) {
    final w = s.width, h = s.height;
    switch (scene) {
      case 4: // mundo de caramelo
        _gradBg(c, s, const [Color(0xFFFFD6EC), Color(0xFFD6F0FF), Color(0xFFD9FFEB)]);
        for (int i = 0; i < 4; i++) {
          final x = ((_r(i, 1) + t * (1 + i % 2)) % 1.0) * (w + 140) - 70;
          final y = h * (0.08 + 0.26 * _r(i, 3));
          final rr = 20 + 10 * _r(i, 4);
          _blob(c, Offset(x, y), rr, i.isEven ? const Color(0xFFFFB8DC) : const Color(0xFFBDE6FF));
          _kface(c, Offset(x, y + rr * .25), rr * .8);
        }
        const lc = [Color(0xFFFF7EB6), Color(0xFFFFD166), Color(0xFF7ED6FF), Color(0xFFB59CFF), Color(0xFF7DDFA8)];
        for (int i = 0; i < 5; i++) {
          final x = w * (0.1 + 0.2 * i) + 6 * sin(t * 2 * pi + i);
          final y = h * 0.52 + 6 * sin((t + i * .2) * 2 * pi);
          c.drawLine(Offset(x, y), Offset(x, h * 0.9), _st(Colors.white, 4));
          c.drawCircle(Offset(x, y), 17, _p(lc[i]));
          c.drawCircle(Offset(x, y), 11, _p(const Color(0x99FFFFFF)));
          c.drawCircle(Offset(x, y), 6, _p(lc[i]));
        }
        for (int i = 0; i < 24; i++) {
          final y = ((_r(i, 8) + t) % 1.0) * h;
          c.drawCircle(Offset(w * _r(i, 9) + 5 * sin(t * 2 * pi + i), y), 2.2, _p(lc[i % 5].withAlpha(190)));
        }
        _hill(c, s, const Color(0xFFBFF3DC), 0.86, 7, 0);
        _hill(c, s, const Color(0xFFFFC4E1), 0.92, 6, 2);
        break;
      case 5: // nubes de algodón
        _gradBg(c, s, const [Color(0xFF9BD8FF), Color(0xFFDDF3FF), Color(0xFFFFEFF8)]);
        const rb = [Color(0xFFFF8FA3), Color(0xFFFFC27A), Color(0xFFFFF29C), Color(0xFFA8E6A1), Color(0xFF9AD1FF), Color(0xFFC3A6FF)];
        for (int i = 0; i < rb.length; i++) {
          c.drawArc(Rect.fromCenter(center: Offset(w * .5, h * .8), width: w * .95 - i * 14, height: h * 1.0 - i * 14),
              pi, pi, false, _st(rb[i].withAlpha(210), 8));
        }
        for (int i = 0; i < 5; i++) {
          final x = ((_r(i, 1) + t * (1 + i % 2)) % 1.0) * (w + 160) - 80;
          final y = h * (0.1 + 0.55 * _r(i, 3));
          final rr = 22 + 12 * _r(i, 4);
          _blob(c, Offset(x, y), rr, Colors.white);
          _kface(c, Offset(x, y + rr * .25), rr * .8);
        }
        for (int i = 0; i < 8; i++) {
          final y = h - ((t + _r(i, 1)) % 1.0) * h * 1.1;
          c.drawPath(_heartP(Offset(w * _r(i, 2) + 8 * sin(t * 2 * pi + i), y), 5 + 3 * _r(i, 3)),
              _p(const Color(0xFFFF8FB8).withAlpha(190)));
        }
        _sparkles(c, s, Colors.white, 8);
        _hill(c, s, const Color(0xFFFFFFFF), 0.93, 5, 1);
        break;
      case 6: // galaxia kawaii
        _gradBg(c, s, const [Color(0xFF1B1048), Color(0xFF3F2A9E), Color(0xFF7A4FD0)]);
        for (int i = 0; i < 40; i++) {
          final tw = 0.5 + 0.5 * sin((t + _r(i, 1)) * 2 * pi);
          c.drawCircle(Offset(w * _r(i, 2), h * _r(i, 3)), 0.8 + 1.4 * _r(i, 4),
              _p(Colors.white.withAlpha((90 + 165 * tw).round())));
        }
        final pl = Offset(w * .78, h * .27);
        c.drawOval(Rect.fromCenter(center: pl, width: 112, height: 26), _st(const Color(0xFFFFE27A), 5));
        c.drawCircle(pl, 31, _p(const Color(0xFFFF9ACB)));
        c.drawCircle(pl.translate(-10, -12), 6, _p(const Color(0x44FFFFFF)));
        c.drawArc(Rect.fromCenter(center: pl, width: 112, height: 26), 0, pi, false, _st(const Color(0xFFFFE27A), 5));
        _kface(c, pl.translate(0, 4), 30);
        final mn = Offset(w * .2, h * .3 + 5 * sin(t * 2 * pi));
        c.drawCircle(mn, 23, _p(const Color(0xFFFFF3B0)));
        c.drawCircle(mn.translate(8, 8), 4, _p(const Color(0x33C9A93A)));
        _kface(c, mn.translate(0, 3), 22);
        c.drawCircle(Offset(w * .55, h * .13), 12, _p(const Color(0xFF7ED6FF)));
        c.drawCircle(Offset(w * .55 - 3, h * .13 - 2), 3, _p(const Color(0x66FFFFFF)));
        final u = (t * 2) % 1.0;
        if (u < 0.45) {
          final o = Offset(w * (0.9 - 0.8 * u / 0.45), h * (0.08 + 0.35 * u / 0.45));
          c.drawLine(o, o + const Offset(34, -14), _st(Colors.white.withAlpha(200), 2.2));
          c.drawPath(_sparkP(o, 5), _p(Colors.white));
        }
        _sparkles(c, s, const Color(0xFFFFE27A), 8);
        _hill(c, s, const Color(0xFF2B1B6B), 0.9, 6, 0.5);
        break;
      case 7: // fondo del mar
        _gradBg(c, s, const [Color(0xFF8FE9F7), Color(0xFF3FA0E6), Color(0xFF1B58B0)]);
        for (int i = 0; i < 3; i++) {
          c.drawPath(
              Path()
                ..moveTo(w * (0.15 + 0.3 * i), 0)
                ..lineTo(w * (0.25 + 0.3 * i), 0)
                ..lineTo(w * (0.4 + 0.3 * i), h * .8)
                ..lineTo(w * (0.1 + 0.3 * i), h * .8)
                ..close(),
              _p(const Color(0x14FFFFFF)));
        }
        for (int i = 0; i < 16; i++) {
          final y = h - ((t + _r(i, 1)) % 1.0) * h * 1.05;
          c.drawCircle(Offset(w * _r(i, 2) + 6 * sin(t * 2 * pi * 2 + i), y), 2 + 4 * _r(i, 3), _st(const Color(0xAAFFFFFF), 1.4));
        }
        const fc = [Color(0xFFFFA24C), Color(0xFFFF7EB6), Color(0xFFFFE066)];
        for (int i = 0; i < 3; i++) {
          final x = (((t * (1 + i % 2)) + _r(i, 1)) % 1.0) * (w + 90) - 45;
          final y = h * (0.2 + 0.18 * i) + 6 * sin((t + i * .3) * 2 * pi);
          final o = Offset(x, y);
          c.drawPath(Path()..moveTo(o.dx - 14, o.dy)..lineTo(o.dx - 28, o.dy - 9)..lineTo(o.dx - 28, o.dy + 9)..close(), _p(fc[i]));
          c.drawOval(Rect.fromCenter(center: o, width: 36, height: 26), _p(fc[i]));
          c.drawCircle(o.translate(8, -3), 3.4, _p(Colors.white));
          c.drawCircle(o.translate(9, -3), 1.8, _p(const Color(0xFF4A3B5C)));
          c.drawArc(Rect.fromCenter(center: o.translate(10, 4), width: 8, height: 5), 0.2, pi - 0.4, false, _st(const Color(0xFF4A3B5C), 1.2));
        }
        final jf = Offset(w * .78, h * .5 + 10 * sin(t * 2 * pi));
        for (int k = -2; k <= 2; k++) {
          c.drawPath(
              Path()
                ..moveTo(jf.dx + k * 6, jf.dy + 10)
                ..quadraticBezierTo(jf.dx + k * 6 + 5 * sin(t * 4 * pi + k), jf.dy + 24, jf.dx + k * 6, jf.dy + 36),
              _st(const Color(0xFFFFB6D5), 2.4));
        }
        c.drawArc(Rect.fromCenter(center: jf, width: 46, height: 40), pi, pi, true, _p(const Color(0xFFFFB6D5)));
        _kface(c, jf.translate(0, -2), 26);
        for (int i = 0; i < 5; i++) {
          final x = w * (0.08 + 0.2 * i);
          final p = Path()..moveTo(x, h);
          for (int k = 1; k <= 6; k++) {
            p.lineTo(x + 6 * sin(t * 2 * pi + i + k), h - k * 12);
          }
          c.drawPath(p, _st(const Color(0xFF4FD08E), 5));
        }
        _hill(c, s, const Color(0xFFF6E1A8), 0.94, 4, 0);
        break;
      case 8: // bosque de setas
        _gradBg(c, s, const [Color(0xFFE3F8D0), Color(0xFFB4EAA4), Color(0xFF8ED38A)]);
        _hill(c, s, const Color(0xFFA6E39C), 0.72, 10, 0);
        const cap = [Color(0xFFFF6B8B), Color(0xFFFFB04C), Color(0xFF8E7BFF)];
        for (int i = 0; i < 3; i++) {
          final x = w * (0.2 + 0.3 * i);
          final y = h * (0.82 + 0.03 * (i % 2));
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 10, y - 30, 20, 32), const Radius.circular(8)), _p(const Color(0xFFFFF4E0)));
          c.drawArc(Rect.fromCenter(center: Offset(x, y - 28), width: 62, height: 50), pi, pi, true, _p(cap[i]));
          for (final d in const [Offset(-16, -40), Offset(4, -48), Offset(18, -38)]) {
            c.drawCircle(Offset(x + d.dx, y + d.dy), 4.5, _p(Colors.white));
          }
          _kface(c, Offset(x, y - 14), 11);
        }
        for (int i = 0; i < 14; i++) {
          final a = (t + _r(i, 2)) * 2 * pi;
          final o = Offset(w * _r(i, 1) + 12 * sin(a), h * (0.2 + 0.5 * _r(i, 3)) + 8 * cos(a));
          final g = 0.5 + 0.5 * sin(a * 2);
          c.drawCircle(o, 9, _p(const Color(0xFFFFF29C).withAlpha((40 * g).round() + 20)));
          c.drawCircle(o, 2.4, _p(const Color(0xFFFFE066)));
        }
        for (int i = 0; i < 6; i++) {
          final o = Offset(w * (0.08 + 0.17 * i), h * .93);
          for (int k = 0; k < 5; k++) {
            c.drawCircle(o + Offset(4 * cos(k * 1.2566), 4 * sin(k * 1.2566)), 2.6, _p(const Color(0xFFFFB6D5)));
          }
          c.drawCircle(o, 2, _p(const Color(0xFFFFE066)));
        }
        break;
      case 9: // pastelería
        _gradBg(c, s, const [Color(0xFFFFF1DC), Color(0xFFFFD3E2)]);
        const fl = [Color(0xFFFF8FB8), Color(0xFFFFD166), Color(0xFF7ED6FF), Color(0xFFB59CFF), Color(0xFF7DDFA8)];
        c.drawPath(Path()..moveTo(0, 8)..quadraticBezierTo(w / 2, 34, w, 8), _st(const Color(0xFFB07A3C), 1.6));
        for (int i = 0; i < 8; i++) {
          final x = w * (0.06 + 0.125 * i);
          final y = 8 + 26 * (1 - pow(2 * (x / w) - 1, 2).toDouble());
          c.drawPath(Path()..moveTo(x - 8, y)..lineTo(x + 8, y)..lineTo(x, y + 16)..close(), _p(fl[i % 5]));
        }
        for (int i = 0; i < 3; i++) {
          final o = Offset(w * (0.2 + 0.3 * i), h * (0.34 + 0.12 * (i % 2)) + 6 * sin((t + i * .3) * 2 * pi));
          c.drawCircle(o, 24, _p(const Color(0xFFD9A066)));
          c.drawCircle(o, 21, _p(fl[(i * 2) % 5]));
          for (int k = 0; k < 8; k++) {
            c.drawLine(o + Offset(13 * cos(k * 0.785), 13 * sin(k * 0.785)), o + Offset(17 * cos(k * 0.785 + .3), 17 * sin(k * 0.785 + .3)), _st(Colors.white, 2));
          }
          c.drawCircle(o, 6, _p(const Color(0xFFFFF1DC)));
          _kface(c, o.translate(0, 26), 12);
        }
        for (int i = 0; i < 2; i++) {
          final o = Offset(w * (0.35 + 0.35 * i), h * (0.66 + 0.04 * i));
          c.drawPath(Path()..moveTo(o.dx - 14, o.dy)..lineTo(o.dx + 14, o.dy)..lineTo(o.dx + 10, o.dy + 20)..lineTo(o.dx - 10, o.dy + 20)..close(), _p(fl[(i + 2) % 5]));
          _blob(c, o.translate(0, -8), 12, const Color(0xFFFFFFFF));
          c.drawCircle(o.translate(0, -26), 4, _p(const Color(0xFFE8445A)));
          _kface(c, o.translate(0, -6), 14);
        }
        for (int i = 0; i < 24; i++) {
          final y = ((_r(i, 8) + t) % 1.0) * h;
          c.drawLine(Offset(w * _r(i, 9), y), Offset(w * _r(i, 9) + 5, y + 3), _st(fl[i % 5], 3));
        }
        _hill(c, s, const Color(0xFFFFE4C2), 0.93, 5, 0);
        break;
      default: // 10 invierno kawaii
        _gradBg(c, s, const [Color(0xFFCDE8FF), Color(0xFFEAF5FF), Color(0xFFF8FCFF)]);
        for (int i = 0; i < 3; i++) {
          final x = w * (0.18 + 0.32 * i);
          final y = h * 0.78;
          c.drawPath(Path()..moveTo(x, y - 62)..lineTo(x - 24, y)..lineTo(x + 24, y)..close(), _p(const Color(0xFF5DBB8A)));
          c.drawPath(Path()..moveTo(x, y - 62)..lineTo(x - 11, y - 38)..lineTo(x + 11, y - 38)..close(), _p(Colors.white));
          c.drawRect(Rect.fromLTWH(x - 3, y, 6, 8), _p(const Color(0xFF8B5A3C)));
        }
        final sm = Offset(w * .68, h * .84);
        c.drawCircle(sm, 24, _p(Colors.white));
        c.drawCircle(sm.translate(0, -30), 17, _p(Colors.white));
        c.drawPath(Path()..moveTo(sm.dx + 2, sm.dy - 30)..lineTo(sm.dx + 16, sm.dy - 27)..lineTo(sm.dx + 2, sm.dy - 24)..close(), _p(const Color(0xFFFF8A3D)));
        _kface(c, sm.translate(-2, -32), 17);
        c.drawLine(sm.translate(-22, -8), sm.translate(-38, -18), _st(const Color(0xFF8B5A3C), 2.4));
        c.drawLine(sm.translate(22, -8), sm.translate(38, -18), _st(const Color(0xFF8B5A3C), 2.4));
        c.drawRect(Rect.fromLTWH(sm.dx - 19, sm.dy - 15, 38, 5), _p(const Color(0xFFE8445A)));
        for (int i = 0; i < 40; i++) {
          final y = ((_r(i, 8) + t * (1 + i % 2)) % 1.0) * h;
          final x = (w * _r(i, 9) + 10 * sin(t * 2 * pi + i)) % w;
          c.drawCircle(Offset(x, y), 1.6 + 1.8 * _r(i, 4), _p(Colors.white));
        }
        _hill(c, s, const Color(0xFFFFFFFF), 0.88, 8, 0);
        _hill(c, s, const Color(0xFFE4F1FF), 0.95, 5, 2);
        break;
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
      final now = DateTime.now();
      final hf = now.hour + now.minute / 60;
      final u = ((hf >= 20 ? hf - 20 : hf + 4) / 12).clamp(0.0, 1.0).toDouble();
      final m = Offset(s.width * (0.12 + 0.76 * u), s.height * (0.2 - 0.1 * sin(pi * u)));
      c.drawCircle(m, 44, Paint()..color = const Color(0x22FFF3B0));
      c.drawCircle(m, 30, Paint()..color = const Color(0x33FFF3B0));
      c.drawCircle(m, 22, Paint()..color = const Color(0xFFFFF3B0));
      c.drawCircle(m.translate(8, -3), 19, Paint()..color = const Color(0xFF1A1F5C));
    }
  }

  @override
  bool shouldRepaint(_BgPainter o) => o.t != t || o.animal != animal || o.scene != scene;
}
