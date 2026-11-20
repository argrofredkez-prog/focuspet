import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';

enum Animal { cerdo, unicornio, tigre, cocodrilo }

const animalColors = {
  Animal.cerdo: Color(0xFFFFB3C7),
  Animal.unicornio: Color(0xFFFFB6D5),
  Animal.tigre: Color(0xFFFFB347),
  Animal.cocodrilo: Color(0xFF7BD389),
};

class _Pal {
  final Color base, light, belly, line, accent;
  const _Pal(this.base, this.light, this.belly, this.line, this.accent);
}

const _pals = {
  Animal.cerdo: _Pal(Color(0xFFFFB3C7), Color(0xFFFFDCE6), Color(0xFFFFE6EE), Color(0xFFC2557A), Color(0xFFFF8FAB)),
  Animal.unicornio: _Pal(Color(0xFFF1ECFF), Color(0xFFFFFFFF), Color(0xFFF7F2FF), Color(0xFF8A78B8), Color(0xFFFFB3D1)),
  Animal.tigre: _Pal(Color(0xFFFFA94D), Color(0xFFFFD08A), Color(0xFFFFF3D6), Color(0xFF9A5418), Color(0xFFFF8FAB)),
  Animal.cocodrilo: _Pal(Color(0xFF6CCB7A), Color(0xFFA6E8A8), Color(0xFFF5E6B8), Color(0xFF2F7D4F), Color(0xFFFF9F43)),
};

/// Animal de cuerpo completo. mode: -1 neutro, 0 estudiar, 1 entrenar, 2 dormir.
class FocusAnimal extends StatefulWidget {
  final Animal animal;
  final double size;
  final double scale; // etapa: bebé, joven, adulto
  final int mode;
  final List<String> acc; // ids de complementos puestos
  final String? emotion; // focus | sad | happy
  final bool aura;
  const FocusAnimal({
    super.key,
    required this.animal,
    this.size = 240,
    this.scale = 1.0,
    this.mode = -1,
    this.acc = const [],
    this.emotion,
    this.aura = true,
  });

  @override
  State<FocusAnimal> createState() => _FocusAnimalState();
}

class _FocusAnimalState extends State<FocusAnimal> with SingleTickerProviderStateMixin {
  Duration _dur(int m) => Duration(milliseconds: m == 1 ? 2000 : (m == 2 ? 6000 : 4000));
  late final AnimationController _c = AnimationController(vsync: this, duration: _dur(widget.mode))..repeat();

  @override
  void didUpdateWidget(FocusAnimal old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      _c.duration = _dur(widget.mode);
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _custom(String id, double sz) {
    final it = itemById(id);
    final b = it.img;
    if (b == null) return const SizedBox();
    const ws = {'eyes': 40.0, 'back': 52.0, 'head': 40.0, 'body': 46.0, 'neck': 32.0, 'feet': 50.0};
    final w = (ws[it.slot] ?? 28.0) * sz / 100;
    const ys = {'eyes': 33.0, 'neck': 54.0, 'face': 46.0, 'back': 70.0, 'hand': 62.0, 'body': 67.0, 'feet': 88.0};
    final cy = ys[it.slot] ?? 6.0;
    final cx = it.slot == 'hand' ? 78.0 : 50.0;
    return Positioned(
      left: 0.2 * sz + cx * sz / 100 - w / 2,
      top: 0.2 * sz + cy * sz / 100 - w / 2,
      child: Image.memory(b, width: w, height: w, filterQuality: FilterQuality.high),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = animalColors[widget.animal]!;
    final sz = widget.size;
    return RepaintBoundary(
        child: SizedBox(
      width: sz * 1.4,
      height: sz * 1.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final wave = sin(_c.value * 2 * pi);
          final blink = _c.value > 0.94;
          final clap = widget.emotion == 'happy' ? (DateTime.now().millisecondsSinceEpoch % 700) / 700.0 : -1.0;
          return Stack(alignment: Alignment.center, children: [
            if (widget.aura)
              CustomPaint(
                  size: Size.square(sz * 1.4),
                  painter: widget.animal == Animal.unicornio
                      ? _StarsPainter(_c.value)
                      : _AuraPainter(_c.value, color)),
            Transform.translate(
              offset: Offset(0, widget.mode == 1 ? -8 * wave.abs() : 0),
              child: Transform.scale(
                scale: widget.scale * (1 + 0.02 * wave),
                alignment: const Alignment(0, 0.6),
                child: SizedBox(
                  width: sz * 1.4,
                  height: sz * 1.4,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                        size: Size.square(sz),
                        painter: _AnimalPainter(
                            widget.animal, widget.mode, blink, widget.acc, widget.emotion, clap)),
                    for (final id in widget.acc)
                      if (id.startsWith('c_')) _custom(id, sz),
                  ]),
                ),
              ),
            ),
            if (widget.mode == 2)
              for (int i = 0; i < 3; i++) _zzz((_c.value + i / 3) % 1, color),
          ]);
        },
      ),
    ));
  }

  Widget _zzz(double p, Color color) => Positioned(
        right: widget.size * 0.12 + p * 20,
        top: widget.size * 0.45 - p * widget.size * 0.45,
        child: Opacity(
          opacity: sin(p * pi).clamp(0.0, 1.0).toDouble(),
          child: Text('Z',
              style: TextStyle(
                  fontSize: 14 + p * 16,
                  fontWeight: FontWeight.w800,
                  color: color.withAlpha(230))),
        ),
      );
}

// Estrellitas que parpadean alrededor del unicornio (sin halo)
class _StarsPainter extends CustomPainter {
  final double t;
  _StarsPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    const pos = [Offset(0.12, 0.3), Offset(0.88, 0.2), Offset(0.84, 0.62), Offset(0.2, 0.7)];
    for (int i = 0; i < pos.length; i++) {
      final k = 0.75 + 0.25 * sin((t + i / 4) * 2 * pi);
      final o = Offset(s.width * pos[i].dx, s.height * pos[i].dy);
      final r = s.width * 0.05 * k;
      final path = Path();
      for (int j = 0; j < 10; j++) {
        final rr = j.isEven ? r : r * 0.45;
        final an = -pi / 2 + j * pi / 5;
        final q = Offset(o.dx + rr * cos(an), o.dy + rr * sin(an));
        j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFFFE066));
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFD99A1E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.t != t;
}

class _AuraPainter extends CustomPainter {
  final double t;
  final Color color;
  _AuraPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    for (int i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      canvas.drawCircle(
          s.center(Offset.zero),
          s.width * (0.3 + 0.2 * p),
          Paint()
            ..color = color.withAlpha((255 * 0.22 * (1 - p)).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5);
    }
  }

  @override
  bool shouldRepaint(_AuraPainter o) => o.t != t;
}

class _AnimalPainter extends CustomPainter {
  final Animal a;
  final int mode;
  final bool blink;
  final List<String> acc;
  final String? emo;
  final double clap; // aplauso: -1 = no, 0..1 = ciclo
  _AnimalPainter(this.a, this.mode, this.blink, this.acc, this.emo, this.clap);

  _Pal get p => _pals[a]!;
  Color get _iris => a == Animal.cerdo
      ? const Color(0xFF7A4A33)
      : (a == Animal.unicornio
          ? const Color(0xFF6C8CD5)
          : (a == Animal.tigre ? const Color(0xFFD18B16) : const Color(0xFFF2A11B)));
  static const ink = Color(0xFF3B2A3A);

  Paint _f(Color c) => Paint()..color = c;
  Paint _l(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  Paint _g(Rect r, Color hi, Color lo) => Paint()
    ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.5), radius: 1.0, colors: [hi, lo])
        .createShader(r);

  Offset get _hl => clap >= 0
      ? Offset(50 - (3 + 11 * (0.5 + 0.5 * cos(clap * 2 * pi))), 62)
      : emo == 'fight'
      ? Offset(23 + 3 * sin(DateTime.now().millisecondsSinceEpoch / 140), 34)
      : mode == 1
      ? const Offset(23, 41)
      : (mode == 0
          ? const Offset(37, 62)
          : (mode == 2 ? const Offset(40, 73) : const Offset(22, 56)));

  // mano a una distancia corta del hombro (brazo de tamaño real)
  Offset get _hand {
    const sh = Offset(34, 58);
    final v = _hl - sh;
    final len = v.distance;
    return len <= 14 ? _hl : sh + v * (14 / len);
  }

  // zarpa con garras (tigre, cocodrilo) o pezuña (cerdo, unicornio)
  void _paw(Canvas c, Offset hand) {
    final ang = atan2(hand.dy - 58, hand.dx - 34);
    c.save();
    c.translate(hand.dx, hand.dy);
    c.rotate(ang);
    final blob = Rect.fromCenter(center: const Offset(1, 0), width: 8, height: 7);
    c.drawOval(blob, _f(p.base));
    c.drawOval(blob, _l(p.line, 1));
    switch (a) {
      case Animal.cerdo:
        for (final dy in [-1.9, 1.9]) {
          final hoofP = Rect.fromCenter(center: Offset(5.5, dy), width: 4.6, height: 3.6);
          c.drawOval(hoofP, _f(p.accent));
          c.drawOval(hoofP, _l(p.line, 0.8));
        }
        break;
      case Animal.unicornio:
        final hoofU = RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(6, 0), width: 5.5, height: 6.5),
            const Radius.circular(2));
        c.drawRRect(hoofU, _f(p.accent));
        c.drawRRect(hoofU, _l(const Color(0xFFD99AB5), 0.8));
        break;
      case Animal.tigre:
      case Animal.cocodrilo:
        for (final dy in [-2.4, 0.0, 2.4]) {
          final claw = Path()
            ..moveTo(4.5, dy - 1.1)
            ..lineTo(8.6, dy)
            ..lineTo(4.5, dy + 1.1)
            ..close();
          c.drawPath(claw, _f(a == Animal.tigre ? const Color(0xFFFFF3E0) : Colors.white));
          c.drawPath(claw, _l(p.line, 0.6));
        }
        break;
    }
    c.restore();
  }

  Path _spark(Offset o, double r) => Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
    ..close();

  // destellos cuando las manos chocan al aplaudir
  void _claps(Canvas c) {
    if (clap < 0 || 50 - _hand.dx > 6) return;
    final k = _l(const Color(0xFFFFD43B), 1.4);
    c.drawLine(const Offset(50, 54), const Offset(50, 48), k);
    c.drawLine(const Offset(45, 55), const Offset(40, 51), k);
    c.drawLine(const Offset(55, 55), const Offset(60, 51), k);
  }

  // relieve y detalles propios de cada animal: brillo, pelaje, pecas, flequillo, escamas
  void _extras(Canvas c) {
    c.drawOval(Rect.fromCenter(center: const Offset(42, 18), width: 14, height: 6), _f(const Color(0x40FFFFFF)));
    if (a != Animal.cocodrilo) {
      final fur = _l(Color.lerp(p.line, p.base, 0.45)!, 0.7);
      _both(c, () {
        c.drawLine(const Offset(26.5, 38), const Offset(24.5, 40), fur);
        c.drawLine(const Offset(27.5, 43), const Offset(25.2, 44.5), fur);
        c.drawLine(const Offset(30, 47), const Offset(28.2, 49.5), fur);
      });
    }
    switch (a) {
      case Animal.cerdo:
        for (final q in [const Offset(42, 37), const Offset(45, 36), const Offset(55, 37), const Offset(58, 36.5)]) {
          c.drawCircle(q, 0.7, _f(p.line));
        }
        break;
      case Animal.unicornio:
        _both(c, () {
          for (final q in const [[33.5, 27.5, 30.5, 25.5], [32.5, 30.5, 29.0, 29.5]]) {
            c.drawLine(Offset(q[0], q[1]), Offset(q[2], q[3]), _l(p.line, 1.1));
          }
          c.drawOval(Rect.fromCenter(center: const Offset(30.5, 41.5), width: 8.5, height: 5), _f(const Color(0x66FF8FB8)));
          c.drawPath(_spark(const Offset(27, 46.5), 2.4), _f(const Color(0xFFFFE27A)));
        });
        break;
      case Animal.tigre:
        c.drawLine(const Offset(50, 44), const Offset(50, 46.5), _l(p.line, 0.8));
        _both(c, () {
          c.drawPath(
              Path()
                ..moveTo(26, 41)
                ..lineTo(22.5, 43)
                ..lineTo(26.5, 44.5)
                ..lineTo(23.5, 47)
                ..lineTo(28, 47),
              _l(p.base, 1.6));
        });
        break;
      case Animal.cocodrilo:
        for (final cr in [const Offset(45, 10), const Offset(50, 7.5), const Offset(55, 10)]) {
          c.drawCircle(cr + const Offset(0, 1), 3.1, _f(p.accent));
          c.drawCircle(cr + const Offset(0, 1), 3.1, _l(p.line, 0.8));
        }
        break;
    }
  }

  // complementos que van detrás del cuerpo (capa y alas)
  void _back(Canvas c) {
    for (final id in acc) {
      if (id == 'a_cape') {
        final cape = Path()
          ..moveTo(34, 52)
          ..lineTo(19, 92)
          ..quadraticBezierTo(50, 101, 81, 92)
          ..lineTo(66, 52)
          ..close();
        c.drawPath(cape, _f(const Color(0xFFD32F2F)));
        c.drawPath(cape, _l(const Color(0xFF8E1B1B), 1.1));
        c.drawPath(
            Path()
              ..moveTo(40, 56)
              ..lineTo(32, 90)
              ..quadraticBezierTo(50, 96, 68, 90)
              ..lineTo(60, 56)
              ..close(),
            _f(const Color(0xFFB71C1C)));
      } else if (id == 'a_butterfly') {
        _both(c, () {
          final up = Path()
            ..moveTo(37, 60)
            ..cubicTo(8, 26, -4, 54, 16, 68)
            ..close();
          final lo = Path()
            ..moveTo(37, 66)
            ..cubicTo(8, 66, 6, 92, 30, 86)
            ..close();
          c.drawPath(up, _g(up.getBounds(), const Color(0xFFFFC2E0), const Color(0xFFFF7EB6)));
          c.drawPath(lo, _g(lo.getBounds(), const Color(0xFFB9E3FF), const Color(0xFF7EB6FF)));
          c.drawPath(up, _l(p.line, 1.1));
          c.drawPath(lo, _l(p.line, 1.1));
          c.drawCircle(const Offset(18, 52), 3, _f(const Color(0xAAFFFFFF)));
          c.drawCircle(const Offset(22, 80), 2.4, _f(const Color(0xAAFFFFFF)));
        });
      } else if (id == 'a_backpack') {
        final pk = RRect.fromRectAndRadius(const Rect.fromLTRB(25, 42, 75, 88), const Radius.circular(10));
        c.drawRRect(pk, _g(pk.outerRect, const Color(0xFFFFB46B), const Color(0xFFE5782A)));
        c.drawRRect(pk, _l(const Color(0xFFA9531A), 1.2));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(32, 70, 68, 86), const Radius.circular(5)), _f(const Color(0xFFFFC992)));
      } else if (id == 'a_wings') {
        _both(c, () {
          final wing = Path()
            ..moveTo(36, 58)
            ..cubicTo(10, 38, 2, 64, 14, 74)
            ..cubicTo(18, 70, 22, 76, 32, 72)
            ..close();
          c.drawPath(wing, _f(Colors.white));
          c.drawPath(wing, _l(const Color(0xFF9CC9F5), 1.2));
        });
      }
    }
  }

  // dibuja f y su reflejo (lado derecho)
  void _both(Canvas c, void Function() f) {
    f();
    c.save();
    c.translate(100, 0);
    c.scale(-1, 1);
    f();
    c.restore();
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100);
    c.drawOval(Rect.fromCenter(center: const Offset(50, 95), width: 54, height: 6),
        _f(const Color(0x22000000)));
    _tail(c);
    if (a == Animal.unicornio) _flameMane(c);
    _back(c);
    _feet(c);
    _boots(c);
    _body(c);
    _clothes(c);
    _skirts(c);
    _sleeves(c);
    if (mode == 2) _pillow(c);
    if (mode == 0 && clap < 0) {
      c.save();
      c.translate(0, -10);
      _book(c);
      c.restore();
    }
    _arms(c);
    _claps(c);
    _ears(c);
    _head(c);
    _face(c);
    _extras(c);
    _outfit(c);
    _accessories(c);
    c.restore();
  }

  // ---------------- cola ----------------
  void _tail(Canvas c) {
    switch (a) {
      case Animal.cerdo:
        c.drawPath(
            Path()
              ..moveTo(66, 80)
              ..cubicTo(80, 80, 86, 68, 78, 64)
              ..cubicTo(72, 61, 70, 69, 76, 70),
            _l(p.line, 3));
        break;
      case Animal.unicornio:
        const cols = [Color(0xFFFFA8CC), Color(0xFFFFE27A), Color(0xFF9AD1FF), Color(0xFFC9B3F5), Color(0xFFFFA8CC)];
        Path tp(int i) => Path()
          ..moveTo(66, 80)
          ..cubicTo(84.0 + i * 1.8, 86, 94, 68.0 - i * 1.6, 85.0 + i * 1.2, 50.0 - i * 2.2);
        for (int i = 0; i < cols.length; i++) {
          c.drawPath(tp(i), _l(p.line, 8.6));
        }
        for (int i = 0; i < cols.length; i++) {
          c.drawPath(tp(i), _l(cols[i], 6.2));
          c.drawCircle(Offset(85.0 + i * 1.2, 50.0 - i * 2.2), 3.4, _f(cols[i]));
        }
        break;
      case Animal.tigre:
        {
          final tp = Path()
            ..moveTo(66, 80)
            ..cubicTo(86, 82, 90, 62, 80, 54);
          c.drawPath(tp, _l(p.line, 9.5));
          c.drawPath(tp, _l(p.base, 7.5));
          final m = tp.computeMetrics().first;
          for (double d = 6; d < m.length - 3; d += 8) {
            final t = m.getTangentForOffset(d)!;
            final n = Offset(-t.vector.dy, t.vector.dx) * 3.4;
            c.drawLine(t.position - n, t.position + n, _l(const Color(0xFF3A2A1E), 2.2));
          }
        }
        break;
      case Animal.cocodrilo:
        {
          _both(c, () {
            final w = Path()
              ..moveTo(33, 60)
              ..cubicTo(26, 46, 14, 40, 6, 36)
              ..quadraticBezierTo(10, 44, 9, 50)
              ..quadraticBezierTo(14, 52, 15, 58)
              ..quadraticBezierTo(20, 58, 22, 66)
              ..quadraticBezierTo(28, 66, 33, 72)
              ..close();
            c.drawPath(w, _f(p.accent));
            c.drawPath(w, _l(p.line, 1.2));
            c.drawLine(const Offset(33, 60), const Offset(8, 38), _l(p.line, 1.2));
            c.drawLine(const Offset(30, 64), const Offset(14, 56), _l(p.line, 0.8));
          });
          final tp = Path()
            ..moveTo(66, 82)
            ..cubicTo(84, 88, 94, 74, 90, 60);
          final m = tp.computeMetrics().first;
          final lp = <Offset>[], rp = <Offset>[];
          for (double d = 0; d <= m.length; d += 1.5) {
            final t = m.getTangentForOffset(d)!;
            final w = 5.5 * (1 - d / m.length) + 0.2; // acaba en punta
            final n = Offset(-t.vector.dy, t.vector.dx);
            lp.add(t.position + n * w);
            rp.add(t.position - n * w);
          }
          final poly = Path()..moveTo(lp.first.dx, lp.first.dy);
          for (final q in lp.skip(1)) {
            poly.lineTo(q.dx, q.dy);
          }
          for (final q in rp.reversed) {
            poly.lineTo(q.dx, q.dy);
          }
          poly.close();
          c.drawPath(poly, _f(p.base));
          c.drawPath(poly, _l(p.line, 1.3));
          final te = m.getTangentForOffset(m.length - 0.5)!;
          final tn = Offset(-te.vector.dy, te.vector.dx);
          final spade = Path()
            ..moveTo(te.position.dx + te.vector.dx * 7, te.position.dy + te.vector.dy * 7)
            ..lineTo((te.position - tn * 5).dx, (te.position - tn * 5).dy)
            ..lineTo((te.position - te.vector * 2).dx, (te.position - te.vector * 2).dy)
            ..lineTo((te.position + tn * 5).dx, (te.position + tn * 5).dy)
            ..close();
          c.drawPath(spade, _f(p.accent));
          c.drawPath(spade, _l(p.line, 1));
          for (double d = 6; d < m.length * 0.8; d += 8) {
            final t = m.getTangentForOffset(d)!;
            final n = Offset(-t.vector.dy, t.vector.dx);
            final tip = t.position - n * 8;
            final b1 = t.position - n * 3 - t.vector * 2.5;
            final b2 = t.position - n * 3 + t.vector * 2.5;
            c.drawPath(
                Path()
                  ..moveTo(b1.dx, b1.dy)
                  ..lineTo(tip.dx, tip.dy)
                  ..lineTo(b2.dx, b2.dy)
                  ..close(),
                _f(p.accent));
          }
        }
        break;
    }
  }

  // ---------------- crin arcoíris (unicornio) ----------------
  // crin arcoíris flameante (solo en el lado derecho)
  void _flameMane(Canvas c) {
    const cols = [
      Color(0xFFFF6B8B), Color(0xFFFFB04C), Color(0xFFFFE066), Color(0xFF7DDFA8),
      Color(0xFF7ED6FF), Color(0xFFB59CFF), Color(0xFFFFA8CC)
    ];
    final tt = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (int i = 0; i < cols.length; i++) {
      final base = Offset(63.0 + i * 1.8, 13.0 + i * 6.2);
      final ang = -0.95 + i * 0.2 + 0.12 * sin(tt * 3 + i * 0.7);
      final len = 24.0 - i * 1.4 + 2.0 * sin(tt * 4 + i);
      final dir = Offset(cos(ang), sin(ang));
      final nrm = Offset(-dir.dy, dir.dx);
      final tip = base + dir * len;
      final fl = Path()
        ..moveTo(base.dx - nrm.dx * 3.4, base.dy - nrm.dy * 3.4)
        ..quadraticBezierTo(base.dx + dir.dx * len * .55 - nrm.dx * 6, base.dy + dir.dy * len * .55 - nrm.dy * 6, tip.dx, tip.dy)
        ..quadraticBezierTo(base.dx + dir.dx * len * .5 + nrm.dx * 5, base.dy + dir.dy * len * .5 + nrm.dy * 5, base.dx + nrm.dx * 3.4, base.dy + nrm.dy * 3.4)
        ..close();
      c.drawPath(fl, _f(cols[i]));
      c.drawPath(fl, _l(p.line, 0.9));
      c.drawPath(
          Path()
            ..moveTo(base.dx, base.dy)
            ..quadraticBezierTo(base.dx + dir.dx * len * .5, base.dy + dir.dy * len * .5 - 1, base.dx + dir.dx * len * .8, base.dy + dir.dy * len * .8),
          _l(const Color(0x88FFFFFF), 1.4));
    }
  }

  // ---------------- patas ----------------
  void _feet(Canvas c) {
    _both(c, () {
      final r = Rect.fromCenter(center: const Offset(38, 90), width: 19, height: 12);
      c.drawOval(r, _g(r, p.light, p.base));
      c.drawOval(r, _l(p.line, 1.1));
      switch (a) {
        case Animal.cerdo:
        case Animal.unicornio:
          c.drawArc(Rect.fromCenter(center: const Offset(38, 92), width: 15, height: 7), 0, pi, true,
              _f(p.accent));
          break;
        case Animal.tigre:
          for (final dx in [-4.0, 0.0, 4.0]) {
            c.drawLine(Offset(38 + dx, 88), Offset(38 + dx, 91), _l(p.line, 0.9));
          }
          break;
        case Animal.cocodrilo:
          for (final dx in [-5.0, 0.0, 5.0]) {
            c.drawPath(
                Path()
                  ..moveTo(38 + dx - 1.5, 95)
                  ..lineTo(38 + dx, 98)
                  ..lineTo(38 + dx + 1.5, 95)
                  ..close(),
                _f(Colors.white));
          }
          break;
      }
    });
  }

  // ---------------- cuerpo ----------------
  void _body(Canvas c) {
    final r = Rect.fromCenter(center: const Offset(50, 67), width: 42, height: 42);
    c.drawOval(r, _g(r, p.light, p.base));
    c.drawOval(r, _l(p.line, 1.2));
    c.drawOval(Rect.fromCenter(center: const Offset(50, 71), width: 25, height: 28), _f(p.belly));
    c.drawOval(Rect.fromCenter(center: const Offset(50, 57), width: 32, height: 9), _f(const Color(0x22000000)));
    c.drawOval(Rect.fromCenter(center: const Offset(44, 66), width: 8, height: 14), _f(const Color(0x22FFFFFF)));
    switch (a) {
      case Animal.tigre:
        _both(c, () {
          for (final y in [56.0, 63.0, 70.0]) {
            c.drawPath(
                Path()
                  ..moveTo(30.5, y)
                  ..quadraticBezierTo(36, y + 1, 39, y + 5),
                _l(const Color(0xFF3A2A1E), 2.2));
          }
        });
        break;
      case Animal.cocodrilo:
        for (final y in [62.0, 68.0, 74.0, 80.0]) {
          c.drawArc(Rect.fromCenter(center: Offset(50, y), width: 20, height: 5), 0.15, pi - 0.3,
              false, _l(p.line, 0.8));
        }
        break;
      default:
        break;
    }
  }

  // ---------------- almohada (dormir): queda entre los brazos ----------------
  void _pillow(Canvas c) {
    c.save();
    c.translate(50, 74);
    c.rotate(-0.06);
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 36, height: 21), const Radius.circular(9));
    c.drawRRect(r, _g(r.outerRect, const Color(0xFFEAF3FF), const Color(0xFF9CC4F5)));
    c.drawRRect(r, _l(const Color(0xFF5B8DC9), 1.1));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 30, height: 15), const Radius.circular(7)),
        _l(const Color(0x88FFFFFF), 0.8));
    c.drawPath(_spark(const Offset(-8, -1), 2.4), _f(const Color(0xFFFFE066)));
    c.drawPath(_spark(const Offset(7, 2), 1.8), _f(const Color(0xFFFFE066)));
    c.restore();
  }

  // ---------------- libro (estudiar) ----------------
  void _book(Canvas c) {
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(50, 72), width: 28, height: 18), const Radius.circular(2));
    c.drawRRect(r, _f(const Color(0xFF5B8DEF)));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(50, 72), width: 24, height: 14), const Radius.circular(1)),
        _f(Colors.white));
    c.drawLine(const Offset(50, 65), const Offset(50, 79), _l(const Color(0xFF9CB4F5), 0.9));
    for (final y in [69.0, 72.0, 75.0]) {
      c.drawLine(Offset(39, y), Offset(48, y), _l(const Color(0xFFB8C6EA), 0.6));
      c.drawLine(Offset(52, y), Offset(61, y), _l(const Color(0xFFB8C6EA), 0.6));
    }
    c.drawRRect(r, _l(const Color(0xFF2F4FA0), 1));
  }

  // ---------------- brazos ----------------
  void _arms(Canvas c) {
    final hl = _hand;
    _both(c, () {
      c.drawLine(const Offset(34, 58), hl, _l(p.line, 9));
      c.drawLine(const Offset(34, 58), hl, _l(p.base, 7));
      if (a == Animal.tigre) {
        final mid = Offset.lerp(const Offset(34, 58), hl, 0.5)!;
        c.drawLine(mid.translate(-3.5, 0), mid.translate(3.5, 0), _l(const Color(0xFF3A2A1E), 1.8));
      }
      _paw(c, hl);
    });
    if (mode == 1 && clap < 0) {
      _both(c, () {
        c.drawLine(hl.translate(-10, 0), hl.translate(10, 0), _l(const Color(0xFF8A8FA3), 2.4));
        for (final dx in [-6.5, 6.5]) {
          c.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(center: hl.translate(dx, 0), width: 5, height: 14),
                  const Radius.circular(1.5)),
              _f(const Color(0xFF4A4F66)));
        }
      });
    }
  }

  // ---------------- orejas ----------------
  void _ears(Canvas c) {
    switch (a) {
      case Animal.cerdo:
        _both(c, () {
          final path = Path()
            ..moveTo(31, 22)
            ..quadraticBezierTo(17, 12, 21, 31)
            ..quadraticBezierTo(29, 33, 37, 24)
            ..close();
          c.drawPath(path, _f(p.base));
          c.drawPath(path, _l(p.line, 1.1));
          c.drawPath(
              Path()
                ..moveTo(30, 24)
                ..quadraticBezierTo(23, 19, 25, 29)
                ..quadraticBezierTo(29, 30, 33, 26)
                ..close(),
              _f(p.accent));
        });
        break;
      case Animal.unicornio:
        _both(c, () {
          final ear = Path()
            ..moveTo(31, 24)
            ..quadraticBezierTo(24, 12, 29, 1)
            ..quadraticBezierTo(38, 10, 41, 21)
            ..close();
          c.drawPath(ear, _f(p.base));
          c.drawPath(ear, _l(p.line, 1.1));
          c.drawPath(
              Path()
                ..moveTo(32, 20)
                ..quadraticBezierTo(28, 12, 30, 6)
                ..quadraticBezierTo(35, 12, 37, 19)
                ..close(),
              _f(const Color(0xFFFFC2DB)));
        });
        break;
      case Animal.tigre:
        _both(c, () {
          c.drawCircle(const Offset(30, 17), 8, _f(p.base));
          c.drawCircle(const Offset(30, 17), 8, _l(p.line, 1.1));
          c.drawCircle(const Offset(30, 17), 4.5, _f(p.accent));
        });
        break;
      case Animal.cocodrilo:
        _both(c, () {
          final horn = Path()
            ..moveTo(34, 19)
            ..cubicTo(30, 15, 29, 10, 25, 7)
            ..cubicTo(32, 7, 38, 11, 41, 17)
            ..close();
          c.drawPath(horn, _f(const Color(0xFFF5E6B8)));
          c.drawPath(horn, _l(p.line, 1.1));
          
        });
        break;
    }
  }

  // ---------------- cabeza ----------------
  void _head(Canvas c) {
    final r = Rect.fromCenter(center: const Offset(50, 33), width: 52, height: 46);
    c.drawOval(r, _g(r, p.light, p.base));
    c.drawOval(r, _l(p.line, 1.3));
    if (a == Animal.unicornio) {
      final h = Path()
        ..moveTo(45, 14)
        ..cubicTo(46, 7, 48.5, 0, 50, -11)
        ..cubicTo(51.5, 0, 54, 7, 55, 14)
        ..close();
      c.drawPath(h, _g(h.getBounds(), const Color(0xFFFFFBEA), const Color(0xFFE9D59A)));
      c.save();
      c.clipPath(h);
      for (int i = 0; i < 6; i++) {
        final y0 = 13.0 - i * 3.6;
        c.drawLine(Offset(43, y0 + 3), Offset(57, y0 - 3), _l(const Color(0x66B8964A), 1.0));
      }
      c.restore();
      c.drawPath(h, _l(const Color(0xFFB8964A), 1.0));
    }
    if (a == Animal.tigre) {
      final st = _l(const Color(0xFF3A2A1E), 2.4);
      c.drawLine(const Offset(50, 12), const Offset(50, 19), st);
      c.drawLine(const Offset(43, 14), const Offset(45.5, 20), st);
      c.drawLine(const Offset(57, 14), const Offset(54.5, 20), st);
      _both(c, () {
        c.drawLine(const Offset(26, 34), const Offset(32, 35), st);
        c.drawLine(const Offset(26.5, 39), const Offset(32, 38), st);
      });
    }
  }

  // ---------------- cara ----------------
  void _face(Canvas c) {
    _both(c, () {
      final cr = Rect.fromCircle(center: const Offset(33.5, 42), radius: 6);
      c.drawCircle(
          const Offset(33.5, 42),
          6,
          Paint()
            ..shader = const RadialGradient(colors: [Color(0x99FF6F9C), Color(0x00FF6F9C)])
                .createShader(cr));
    });
    switch (a) {
      case Animal.cerdo:
        {
          final r = Rect.fromCenter(center: const Offset(50, 43), width: 18, height: 12);
          c.drawOval(r, _f(p.accent));
          c.drawOval(r, _l(p.line, 1));
          _both(c, () => c.drawOval(
              Rect.fromCenter(center: const Offset(46.5, 43), width: 2.6, height: 4.2), _f(p.line)));
        }
        break;
      case Animal.unicornio:
        {
          final r = Rect.fromCenter(center: const Offset(50, 43.5), width: 22, height: 14);
          c.drawOval(r, _g(r, const Color(0xFFFFF1F6), const Color(0xFFF3DCE8)));
          c.drawOval(r, _l(p.line, 0.9));
          _both(c, () => c.drawOval(Rect.fromCenter(center: const Offset(45.5, 42.5), width: 2.2, height: 3.4), _f(p.line)));
        }
        break;
      case Animal.tigre:
        _both(c, () => c.drawOval(
            Rect.fromCenter(center: const Offset(45, 44), width: 12, height: 10), _f(p.belly)));
        c.drawPath(
            Path()
              ..moveTo(47, 40)
              ..lineTo(53, 40)
              ..lineTo(50, 44)
              ..close(),
            _f(p.accent));
        _both(c, () {
          c.drawLine(const Offset(37, 43), const Offset(27, 41), _l(p.line, 0.6));
          c.drawLine(const Offset(37, 45), const Offset(27, 46), _l(p.line, 0.6));
        });
        break;
      case Animal.cocodrilo:
        {
          final r = Rect.fromCenter(center: const Offset(50, 46), width: 28, height: 18);
          c.drawOval(r, _g(r, p.light, const Color(0xFF8EDC96)));
          c.drawOval(r, _l(p.line, 1.1));
          _both(c, () => c.drawCircle(const Offset(45, 43.2), 1.3, _f(p.line)));
        }
        break;
    }

    final closed = (mode == 2 && emo == null) || blink;
    _both(c, () {
      const e = Offset(39, 31);
      if (emo == 'happy') {
        c.drawArc(Rect.fromCenter(center: e, width: 11, height: 8), pi, pi, false, _l(ink, 1.8));
      } else if (closed) {
        c.drawArc(Rect.fromCenter(center: e, width: 11, height: 7), 0.15, pi - 0.3, false, _l(ink, 1.6));
      } else if (a == Animal.unicornio) {
        c.drawOval(Rect.fromCenter(center: e.translate(0, 0.8), width: 12, height: 14.5), _f(const Color(0xFF2B2140)));
        c.drawCircle(e.translate(-2.2, -2.2), 3.2, _f(Colors.white));
        c.drawCircle(e.translate(2.3, 3.4), 1.6, _f(const Color(0xDDFFFFFF)));
        c.drawLine(e.translate(-5.4, -4.6), e.translate(-8.2, -6.8), _l(ink, 1.1));
        c.drawLine(e.translate(-5.8, -2.4), e.translate(-8.8, -3.4), _l(ink, 1.1));
      } else {
        c.drawOval(Rect.fromCenter(center: e, width: 11.5, height: 13), _f(const Color(0xFFFDFBFF)));
        final iris = Rect.fromCenter(center: e.translate(0.3, 1), width: 9, height: 11);
        c.drawOval(
            iris,
            Paint()
              ..shader = RadialGradient(colors: [Color.lerp(_iris, Colors.white, 0.35)!, _iris])
                  .createShader(iris));
        c.drawOval(Rect.fromCenter(center: e.translate(0.3, 1.2), width: 5, height: 6.6), _f(ink));
        c.drawCircle(e.translate(-1.6, -1.8), 2.2, _f(Colors.white));
        c.drawCircle(e.translate(2, 3.2), 1.1, _f(const Color(0xCCFFFFFF)));
        c.drawArc(Rect.fromCenter(center: e, width: 12, height: 13.4), pi * 1.05, pi * 0.9, false,
            _l(const Color(0x55000000), 1.0));
        if (a == Animal.cerdo || a == Animal.unicornio) {
          c.drawLine(e.translate(-5, -5), e.translate(-7.4, -7), _l(ink, 0.9));
          c.drawLine(e.translate(-4, -6), e.translate(-5.8, -8.4), _l(ink, 0.9));
        }
      }
      if ((mode == 1 || emo == 'focus' || emo == 'fight') && emo != 'happy' && emo != 'sad') {
        c.drawLine(const Offset(33.5, 24.5), const Offset(43.5, 27), _l(ink, 1.8));
      } else if (emo == 'sad') {
        c.drawLine(const Offset(34, 26.5), const Offset(43.5, 22.5), _l(ink, 1.8));
      }
    });

    final my = a == Animal.cocodrilo ? 50.0 : 49.0;
    if (emo == 'sad') {
      final dy = (DateTime.now().millisecondsSinceEpoch % 1200) / 1200 * 8;
      _both(c, () {
        c.drawPath(
            Path()
              ..moveTo(35, 36 + dy)
              ..quadraticBezierTo(32.5, 40 + dy, 35, 42 + dy)
              ..quadraticBezierTo(37.5, 40 + dy, 35, 36 + dy),
            _f(const Color(0xFF6EC6FF)));
      });
    }
    if (emo == 'happy') {
      c.drawArc(Rect.fromCenter(center: Offset(50, my - 1.5), width: 13, height: 8), 0, pi, true,
          _f(const Color(0xFF7A2E45)));
    } else if (emo == 'talk') {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(50, my),
              width: 8,
              height: 2 + 4 * sin(DateTime.now().millisecondsSinceEpoch / 110).abs()),
          _f(const Color(0xFF7A2E45)));
    } else if (emo == 'sad') {
      c.drawArc(Rect.fromCenter(center: Offset(50, my + 2.5), width: 9, height: 5), pi + 0.2, pi - 0.4,
          false, _l(ink, 1.4));
    } else if (emo == 'fight') {
      c.drawArc(Rect.fromCenter(center: Offset(50, my + 1.5), width: 11, height: 6), 0.2, pi - 0.4,
          false, _l(ink, 1.5));
    } else if (emo == 'focus') {
      c.drawLine(Offset(46.5, my), Offset(53.5, my), _l(ink, 1.5));
    } else if (mode == 1) {
      c.drawOval(Rect.fromCenter(center: Offset(50, my), width: 8, height: 5.5),
          _f(const Color(0xFF7A2E45)));
      c.drawOval(Rect.fromCenter(center: Offset(50, my + 1.2), width: 4.5, height: 2.4),
          _f(const Color(0xFFFF8FAB)));
    } else {
      c.drawArc(Rect.fromCenter(center: Offset(50, my - 1), width: 9, height: 5), 0.2, pi - 0.4,
          false, _l(ink, 1.3));
    }
    if (a == Animal.cocodrilo) {
      for (final dx in [-10.0, 10.0]) {
        c.drawPath(
            Path()
              ..moveTo(50 + dx - 1.6, 52.4)
              ..lineTo(50 + dx, 55)
              ..lineTo(50 + dx + 1.6, 52.4)
              ..close(),
            _f(Colors.white));
      }
    }
  }

  // ---------------- prendas de cada estado ----------------
  void _outfit(Canvas c) {
    if (mode == 0) {
      // gafas de estudio transparentes
      _both(c, () {
        c.drawCircle(const Offset(39, 31), 9.2, _f(const Color(0x33BFE3FF)));
        c.drawCircle(const Offset(39, 31), 9.2, _l(const Color(0xFF4A5A78), 1.3));
        c.drawArc(Rect.fromCenter(center: const Offset(35, 27.5), width: 7, height: 5), pi * 1.05,
            pi * 0.6, false, _l(const Color(0xAAFFFFFF), 1));
        c.drawLine(const Offset(30, 30), const Offset(26.5, 29), _l(const Color(0xFF4A5A78), 1.1));
      });
      c.drawArc(Rect.fromCenter(center: const Offset(50, 31), width: 6, height: 4), pi, pi, false,
          _l(const Color(0xFF4A5A78), 1.2));
    } else if (mode == 1) {
      // cinta elástica en la frente
      final band = Path()
        ..moveTo(26.5, 26)
        ..quadraticBezierTo(50, 14, 73.5, 26);
      c.drawPath(band, _l(const Color(0xFFE8445A), 6));
      c.drawPath(band, _l(const Color(0x66FFFFFF), 1.4));
      c.drawCircle(const Offset(70, 24.5), 3, _f(const Color(0xFFB82E44)));
      c.drawPath(
          Path()
            ..moveTo(70, 24.5)
            ..lineTo(78, 20)
            ..lineTo(77, 28)
            ..close(),
          _f(const Color(0xFFE8445A)));
    } else if (mode == 2) {
      // antifaz
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(50, 31), width: 42, height: 15), const Radius.circular(7.5));
      c.drawRRect(r, _f(const Color(0xFF5B4B8A)));
      c.drawRRect(r, _l(const Color(0xFF3A2E63), 1.1));
      _both(c, () => c.drawArc(
          Rect.fromCenter(center: const Offset(39, 31.5), width: 10, height: 6), 0.2, pi - 0.4, false,
          _l(const Color(0xCCFFFFFF), 1.3)));
      _both(c, () => c.drawLine(const Offset(29, 30), const Offset(25, 28.5), _l(const Color(0xFF5B4B8A), 1.6)));
    }
  }

  // ---------------- botas y zapatos ----------------
  void _boot(Canvas c, Color col, Color edge, double top) {
    _both(c, () {
      final foot = Rect.fromCenter(center: const Offset(38, 90), width: 23, height: 14);
      final shaft = RRect.fromRectAndRadius(Rect.fromLTRB(31, top, 45, 91), const Radius.circular(3.5));
      c.drawOval(foot, _l(edge, 2));
      c.drawRRect(shaft, _l(edge, 2));
      c.drawOval(foot, _f(col));
      c.drawRRect(shaft, _f(col));
    });
  }

  void _boots(Canvas c) {
    for (final id in acc) {
      switch (id) {
        case 'a_rainboots':
          _boot(c, const Color(0xFFFFD43B), const Color(0xFFC99A00), 79);
          _both(c, () {
            c.drawLine(const Offset(33, 82), const Offset(43, 82), _l(const Color(0xAAFFFFFF), 1.6));
            c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(27, 94, 23, 3), const Radius.circular(1.5)),
                _f(const Color(0xFF3A3A4E)));
          });
          break;
        case 'a_cowboots':
          _boot(c, const Color(0xFFA9622B), const Color(0xFF6B3F1D), 78);
          _both(c, () {
            c.drawRect(const Rect.fromLTWH(31, 78, 14, 3.5), _f(const Color(0xFF6B3F1D)));
            c.drawPath(_spark(const Offset(38, 86), 2.6), _f(const Color(0xFFFFD43B)));
            c.drawRect(const Rect.fromLTWH(30, 95, 8, 3), _f(const Color(0xFF3A2A1E)));
          });
          break;
        case 'a_sneakers':
          _boot(c, Colors.white, const Color(0xFFB7B7C9), 86);
          _both(c, () {
            c.drawArc(Rect.fromCenter(center: const Offset(40, 91), width: 12, height: 8), pi, pi, false,
                _l(const Color(0xFFE8445A), 2));
            for (final y in [86.5, 88.5]) {
              c.drawLine(Offset(34, y), Offset(40, y), _l(const Color(0xFFB7B7C9), 0.9));
            }
            c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(27, 94.5, 23, 3), const Radius.circular(1.5)),
                _f(const Color(0xFFE8445A)));
          });
          break;
        case 'a_snowboots':
          _boot(c, const Color(0xFF7FB7E8), const Color(0xFF3F7FB8), 80);
          _both(c, () {
            c.drawOval(Rect.fromCenter(center: const Offset(38, 81), width: 18, height: 6), _f(Colors.white));
            c.drawCircle(const Offset(35, 87), 1.2, _f(Colors.white));
            c.drawCircle(const Offset(41, 86), 1.2, _f(Colors.white));
          });
          break;
        case 'a_shoes':
          _boot(c, const Color(0xFF1F1B2E), const Color(0xFF0F0C18), 88);
          _both(c, () {
            c.drawArc(Rect.fromCenter(center: const Offset(35, 89), width: 9, height: 6), pi * 1.1, pi * 0.7, false,
                _l(const Color(0xAAFFFFFF), 1));
            c.drawCircle(const Offset(41, 87.5), 1.7, _f(const Color(0xFFE8445A)));
          });
          break;
        default:
          break;
      }
    }
  }

  // ---------------- ropa ----------------
  static const _clothIds = [
    'a_tshirt', 'a_dress', 'a_sweater', 'a_hoodie', 'a_overalls', 'a_kimono', 'a_tux',
    'a_tee_heart', 'a_tee_star', 'a_tee_rainbow', 'a_tee_berry',
    'a_dress_princess', 'a_dress_flower', 'a_dress_tutu', 'a_dress_party'
  ];

  void _clothes(Canvas c) {
    final body = Rect.fromCenter(center: const Offset(50, 67), width: 42, height: 42);
    for (final id in acc) {
      if (!_clothIds.contains(id)) continue;
      c.save();
      // holgada: más grande que el cuerpo
      c.translate(50, 68);
      c.scale(1.2, 1.1);
      c.translate(-50, -68);
      c.save();
      c.clipPath(Path()..addOval(body));
      switch (id) {
        case 'a_tshirt':
          c.drawRect(body, _f(Colors.white));
          for (double y = 54; y < 90; y += 7) {
            c.drawRect(Rect.fromLTRB(28, y, 72, y + 3.4), _f(const Color(0xFF3F9BE0)));
          }
          c.drawArc(Rect.fromCenter(center: const Offset(50, 51), width: 15, height: 11), 0, pi, false,
              _l(const Color(0xFF2F78BD), 2.4));
          break;
        case 'a_dress':
          c.drawRect(const Rect.fromLTRB(28, 52, 72, 90), _f(const Color(0xFFFF8FB8)));
          c.drawRect(const Rect.fromLTRB(28, 65, 72, 70), _f(const Color(0xFFE8587F)));
          c.drawPath(Path()..moveTo(50, 67.5)..lineTo(43, 62.5)..lineTo(43, 72.5)..close(), _f(const Color(0xFFFFD6E6)));
          c.drawPath(Path()..moveTo(50, 67.5)..lineTo(57, 62.5)..lineTo(57, 72.5)..close(), _f(const Color(0xFFFFD6E6)));
          c.drawCircle(const Offset(50, 67.5), 2, _f(const Color(0xFFE8587F)));
          for (final x in [38.0, 46.0, 54.0, 62.0]) {
            c.drawCircle(Offset(x, 59), 1.3, _f(Colors.white));
          }
          for (final x in [44.0, 56.0]) {
            c.drawOval(Rect.fromCenter(center: Offset(x, 53), width: 9, height: 6), _f(Colors.white));
          }
          break;
        case 'a_sweater':
          c.drawRect(const Rect.fromLTRB(28, 52, 72, 90), _f(const Color(0xFF4FA765)));
          c.drawRect(const Rect.fromLTRB(28, 83, 72, 90), _f(const Color(0xFFE8445A)));
          final zz = Path()..moveTo(28, 72);
          for (double x = 28; x < 72; x += 6) {
            zz.lineTo(x + 3, 66);
            zz.lineTo(x + 6, 72);
          }
          zz..lineTo(72, 74)..lineTo(28, 74)..close();
          c.drawPath(zz, _f(Colors.white));
          for (final x in [34.0, 46.0, 58.0]) {
            c.drawCircle(Offset(x, 79), 1.3, _f(Colors.white));
          }
          c.drawArc(Rect.fromCenter(center: const Offset(50, 51), width: 18, height: 12), 0, pi, false,
              _l(const Color(0xFF2F7D4F), 3));
          break;
        case 'a_hoodie':
          c.drawRect(const Rect.fromLTRB(28, 54, 72, 90), _f(const Color(0xFF8E5BD9)));
          c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(37, 73, 26, 10), const Radius.circular(3)),
              _f(const Color(0xFF6F42B8)));
          c.drawArc(Rect.fromCenter(center: const Offset(50, 53), width: 30, height: 12), 0, pi, false,
              _l(const Color(0xFF6F42B8), 4));
          for (final x in [46.0, 54.0]) {
            c.drawLine(Offset(x, 57), Offset(x, 67), _l(Colors.white, 1.2));
            c.drawCircle(Offset(x, 67.5), 1.1, _f(Colors.white));
          }
          break;
        case 'a_overalls':
          c.drawRect(body, _f(const Color(0xFFFFF4E0)));
          c.drawRect(const Rect.fromLTRB(28, 66, 72, 90), _f(const Color(0xFF3F7FD0)));
          c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(40, 58, 20, 12), const Radius.circular(2)),
              _f(const Color(0xFF3F7FD0)));
          for (final x in [42.0, 58.0]) {
            c.drawLine(Offset(x, 50), Offset(x, 60), _l(const Color(0xFF3F7FD0), 3));
            c.drawCircle(Offset(x, 61), 1.6, _f(const Color(0xFFFFD43B)));
          }
          c.drawRect(const Rect.fromLTWH(45, 63, 10, 5), _l(const Color(0xFF6FA2EA), 0.8));
          break;
        case 'a_kimono':
          c.drawRect(const Rect.fromLTRB(28, 50, 72, 92), _f(const Color(0xFFE8445A)));
          c.drawPath(Path()..moveTo(57, 50)..lineTo(50, 72)..lineTo(54, 92)..lineTo(72, 92)..lineTo(72, 50)..close(),
              _f(const Color(0xFFF0586F)));
          c.drawPath(Path()..moveTo(39, 50)..lineTo(44, 50)..lineTo(54, 71)..lineTo(49.5, 71)..close(),
              _f(const Color(0xFFFFF4E0)));
          c.drawPath(Path()..moveTo(61, 50)..lineTo(56, 50)..lineTo(46, 71)..lineTo(50.5, 71)..close(),
              _f(Colors.white));
          for (final o in const [Offset(36, 60), Offset(63, 58), Offset(35, 85), Offset(46, 87), Offset(60, 83), Offset(67, 87)]) {
            for (int k = 0; k < 5; k++) {
              c.drawCircle(o + Offset(1.9 * cos(k * 1.2566), 1.9 * sin(k * 1.2566)), 1.5, _f(const Color(0xFFFFD6E6)));
            }
            c.drawCircle(o, 0.9, _f(const Color(0xFFFFD43B)));
          }
          c.drawRect(const Rect.fromLTRB(28, 89, 72, 92), _f(const Color(0xFFFFF4E0)));
          c.drawRect(const Rect.fromLTRB(28, 70, 72, 81), _f(const Color(0xFFF2B134)));
          c.drawRect(const Rect.fromLTRB(28, 70, 72, 72), _f(const Color(0xFFC98A1E)));
          c.drawRect(const Rect.fromLTRB(28, 79, 72, 81), _f(const Color(0xFFC98A1E)));
          for (final x in [34.0, 42.0, 58.0, 66.0]) {
            c.drawLine(Offset(x, 72.5), Offset(x, 78.5), _l(const Color(0x66FFFFFF), 1.2));
          }
          c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(46, 69, 8, 13), const Radius.circular(2)),
              _f(const Color(0xFFE8445A)));
          break;
        case 'a_tux':
          c.drawRect(const Rect.fromLTRB(28, 52, 72, 90), _f(const Color(0xFF1F1B2E)));
          c.drawPath(Path()..moveTo(43, 52)..lineTo(57, 52)..lineTo(50, 76)..close(), _f(Colors.white));
          c.drawLine(const Offset(43, 52), const Offset(47.5, 70), _l(const Color(0xFF3A3A4E), 1.2));
          c.drawLine(const Offset(57, 52), const Offset(52.5, 70), _l(const Color(0xFF3A3A4E), 1.2));
          for (final y in [64.0, 69.0]) {
            c.drawCircle(Offset(50, y), 1, _f(const Color(0xFF1F1B2E)));
          }
          c.drawPath(Path()..moveTo(50, 57)..lineTo(43.5, 53.5)..lineTo(43.5, 60.5)..close(), _f(const Color(0xFFE8445A)));
          c.drawPath(Path()..moveTo(50, 57)..lineTo(56.5, 53.5)..lineTo(56.5, 60.5)..close(), _f(const Color(0xFFE8445A)));
          c.drawCircle(const Offset(50, 57), 1.8, _f(const Color(0xFFB82E44)));
          break;
        case 'a_tee_heart':
          c.drawRect(body, _f(Colors.white));
          c.drawPath(_heartP(const Offset(50, 68), 9), _f(const Color(0xFFFF4F86)));
          c.drawPath(_heartP(const Offset(47, 65), 2.2), _f(const Color(0x99FFFFFF)));
          c.drawArc(Rect.fromCenter(center: const Offset(50, 51), width: 15, height: 11), 0, pi, false,
              _l(const Color(0xFFFF8FB8), 2.4));
          break;
        case 'a_tee_star':
          c.drawRect(body, _f(const Color(0xFF5BA8F0)));
          c.drawPath(_starP(const Offset(50, 68), 11), _f(const Color(0xFFFFE066)));
          c.drawPath(_starP(const Offset(50, 68), 11), _l(const Color(0xFFD99A1E), 1));
          c.drawArc(Rect.fromCenter(center: const Offset(50, 51), width: 15, height: 11), 0, pi, false,
              _l(const Color(0xFF2F78BD), 2.4));
          break;
        case 'a_tee_rainbow':
          c.drawRect(body, _f(Colors.white));
          const rbw = [Color(0xFFFF6B8B), Color(0xFFFFB04C), Color(0xFFFFE066), Color(0xFF7DDFA8), Color(0xFF7ED6FF), Color(0xFFB59CFF)];
          for (int i = 0; i < 6; i++) {
            c.drawArc(Rect.fromCircle(center: const Offset(50, 80), radius: 20.0 - i * 2.6), pi, pi, false, _l(rbw[i], 2.8));
          }
          c.drawArc(Rect.fromCenter(center: const Offset(50, 51), width: 15, height: 11), 0, pi, false,
              _l(const Color(0xFFB59CFF), 2.4));
          break;
        case 'a_tee_berry':
          c.drawRect(body, _f(const Color(0xFFFFE9F0)));
          final bp = Path()
            ..moveTo(50, 83)
            ..cubicTo(34, 74, 37, 59, 50, 62)
            ..cubicTo(63, 59, 66, 74, 50, 83)
            ..close();
          c.drawPath(bp, _f(const Color(0xFFFF4F6E)));
          c.drawPath(Path()..moveTo(50, 62)..lineTo(44, 58)..lineTo(48, 62)..lineTo(50, 56)..lineTo(52, 62)..lineTo(56, 58)..close(),
              _f(const Color(0xFF4FA765)));
          for (final o in const [Offset(46, 68), Offset(54, 68), Offset(50, 73), Offset(45, 75), Offset(55, 75)]) {
            c.drawCircle(o, 0.9, _f(const Color(0xFFFFE066)));
          }
          c.drawArc(Rect.fromCenter(center: const Offset(50, 51), width: 15, height: 11), 0, pi, false,
              _l(const Color(0xFFFF8FB8), 2.4));
          break;
        case 'a_dress_princess':
          c.drawRect(const Rect.fromLTRB(28, 52, 72, 90), _f(const Color(0xFF9B7BFF)));
          c.drawRect(const Rect.fromLTRB(28, 65, 72, 70), _f(const Color(0xFFFFD84D)));
          c.drawPath(_starP(const Offset(50, 67.5), 3.4), _f(Colors.white));
          c.drawPath(Path()..moveTo(38, 52)..lineTo(50, 63)..lineTo(62, 52)..close(), _f(const Color(0xFFFFE9F6)));
          for (final o in const [Offset(40, 59), Offset(60, 59)]) {
            c.drawPath(_spark(o, 2), _f(Colors.white));
          }
          break;
        case 'a_dress_flower':
          c.drawRect(const Rect.fromLTRB(28, 52, 72, 90), _f(const Color(0xFFFFE066)));
          c.drawRect(const Rect.fromLTRB(28, 66, 72, 69.5), _f(const Color(0xFF4FA765)));
          for (final x in [41.0, 59.0]) {
            c.drawLine(Offset(x, 49), Offset(x, 62), _l(const Color(0xFF4FA765), 2.6));
          }
          for (final o in const [Offset(36, 59), Offset(50, 58), Offset(64, 59), Offset(44, 76), Offset(58, 78)]) {
            for (int k = 0; k < 5; k++) {
              c.drawCircle(o + Offset(2.2 * cos(k * 1.2566), 2.2 * sin(k * 1.2566)), 1.6, _f(const Color(0xFFFF8FB8)));
            }
            c.drawCircle(o, 1.2, _f(Colors.white));
          }
          break;
        case 'a_dress_tutu':
          c.drawRect(const Rect.fromLTRB(28, 52, 72, 90), _f(const Color(0xFFFFB6D5)));
          c.drawRect(const Rect.fromLTRB(28, 66, 72, 70), _f(const Color(0xFFFF7EB6)));
          c.drawPath(Path()..moveTo(40, 52)..lineTo(50, 66)..lineTo(60, 52)..close(), _f(Colors.white));
          c.drawCircle(const Offset(50, 68), 2.4, _f(const Color(0xFFFF7EB6)));
          for (final o in const [Offset(36, 76), Offset(64, 78), Offset(50, 82)]) {
            c.drawPath(_spark(o, 2), _f(Colors.white));
          }
          break;
        case 'a_dress_party':
          c.drawRect(const Rect.fromLTRB(28, 52, 72, 90), _f(const Color(0xFF3A3F8F)));
          c.drawRect(const Rect.fromLTRB(28, 65, 72, 68.5), _f(const Color(0xFFFFD84D)));
          c.drawArc(Rect.fromCenter(center: const Offset(50, 52), width: 24, height: 14), 0, pi, false,
              _l(const Color(0xFFFFD84D), 2));
          for (int i = 0; i < 14; i++) {
            c.drawCircle(Offset(31.0 + (i * 7) % 38, 56.0 + (i * 5) % 32), 1, _f(const Color(0xFFFFE27A)));
          }
          break;
      }
      c.restore();
      c.drawOval(body, _l(p.line, 1.2));
      // arrugas de tela suelta
      c.drawPath(Path()..moveTo(36, 80)..quadraticBezierTo(40, 84, 38, 90), _l(p.line.withAlpha(70), 0.8));
      c.drawPath(Path()..moveTo(64, 78)..quadraticBezierTo(60, 83, 63, 89), _l(p.line.withAlpha(70), 0.8));
      c.restore();
    }
  }

  // faldas de vestidos (por fuera del cuerpo)
  void _skirts(Canvas c) {
    for (final id in acc) {
      Color? m;
      Color? d;
      double hem = 88;
      switch (id) {
        case 'a_dress':
          m = const Color(0xFFFF8FB8);
          d = const Color(0xFFE8587F);
          break;
        case 'a_dress_princess':
          m = const Color(0xFF8FB8FF);
          d = const Color(0xFF5A82D6);
          hem = 90;
          break;
        case 'a_dress_flower':
          m = const Color(0xFFFFE066);
          d = const Color(0xFFD9A81E);
          break;
        case 'a_dress_tutu':
          m = const Color(0xFFFFB6D5);
          d = const Color(0xFFE880AB);
          break;
        case 'a_dress_party':
          m = const Color(0xFF3A3F8F);
          d = const Color(0xFFFFD84D);
          hem = 84;
          break;
        default:
          break;
      }
      if (m == null || d == null) continue;
      final w2 = id == 'a_dress_party' ? 26.0 : 33.0;
      final sk = Path()
        ..moveTo(31, 70)
        ..quadraticBezierTo(50 - w2 * .65, 78, 50 - w2, hem)
        ..quadraticBezierTo(50, hem + 8, 50 + w2, hem)
        ..quadraticBezierTo(50 + w2 * .65, 78, 69, 70)
        ..close();
      if (id == 'a_dress_tutu') {
        for (final k in [4.0, 0.0]) {
          final tl = Rect.fromCenter(center: Offset(50, hem - 3 + k), width: w2 * 2 + 8, height: 12);
          c.drawOval(tl, _f(const Color(0xFFFFC9E0)));
          c.drawOval(tl, _l(d, 0.9));
        }
      }
      c.drawPath(sk, _g(sk.getBounds(), Color.lerp(m, Colors.white, .35)!, m));
      c.drawPath(sk, _l(d, 1.2));
      for (int i = 0; i < 5; i++) {
        c.drawLine(Offset(50 + (i - 2) * 7.0, 74), Offset(50 + (i - 2) * w2 * .62, hem + 3), _l(d.withAlpha(110), 0.9));
      }
      if (id == 'a_dress') {
        for (final o in const [Offset(38, 80), Offset(50, 84), Offset(62, 80), Offset(30, 86), Offset(70, 86)]) {
          c.drawCircle(o, 1.6, _f(Colors.white));
        }
      } else if (id == 'a_dress_princess') {
        for (final o in const [Offset(36, 82), Offset(52, 86), Offset(66, 80), Offset(28, 88)]) {
          c.drawPath(_spark(o, 2.6), _f(Colors.white));
        }
        c.drawArc(Rect.fromCenter(center: Offset(50, hem), width: w2 * 2, height: 14), 0.15, pi - 0.3, false,
            _l(const Color(0xFFFFD84D), 1.6));
      } else if (id == 'a_dress_flower') {
        for (final o in const [Offset(36, 82), Offset(52, 85), Offset(66, 81)]) {
          for (int k = 0; k < 5; k++) {
            c.drawCircle(o + Offset(2.4 * cos(k * 1.2566), 2.4 * sin(k * 1.2566)), 1.7, _f(const Color(0xFFFF8FB8)));
          }
          c.drawCircle(o, 1.3, _f(Colors.white));
        }
      } else if (id == 'a_dress_party') {
        for (int i = 0; i < 9; i++) {
          c.drawCircle(Offset(34.0 + (i * 7) % 32, 76.0 + (i * 5) % 8), 1, _f(const Color(0xFFFFE27A)));
        }
      }
    }
  }

  static const _sleeveCol = {
    'a_tshirt': 0xFFFFFFFF,
    'a_tee_heart': 0xFFFFFFFF,
    'a_tee_star': 0xFF5BA8F0,
    'a_tee_rainbow': 0xFFFFFFFF,
    'a_tee_berry': 0xFFFFE9F0,
    'a_sweater': 0xFF4FA765,
    'a_hoodie': 0xFF8E5BD9,
    'a_dress': 0xFFFF8FB8,
    'a_dress_princess': 0xFFB9D0FF,
    'a_dress_party': 0xFF3A3F8F,
    'a_tux': 0xFF1F1B2E,
  };

  // mangas y lazo del kimono (por fuera del cuerpo)
  void _sleeves(Canvas c) {
    for (final id in acc) {
      if (id == 'a_kimono') {
        _both(c, () {
          final sl = Path()
            ..moveTo(31, 55)
            ..lineTo(15, 60)
            ..lineTo(13, 86)
            ..quadraticBezierTo(21, 91, 29, 84)
            ..close();
          c.drawPath(sl, _f(const Color(0xFFE8445A)));
          c.drawPath(
              Path()..moveTo(13.4, 79)..lineTo(29.4, 77.5)..lineTo(29, 84)..quadraticBezierTo(21, 91, 13, 86)..close(),
              _f(const Color(0xFFFFF4E0)));
          c.drawPath(sl, _l(const Color(0xFFB82E44), 1.1));
          c.drawCircle(const Offset(20, 67), 1.8, _f(const Color(0xFFFFB6D5)));
          c.drawCircle(const Offset(25, 73), 1.5, _f(const Color(0xFFFFB6D5)));
        });
        final gold = _f(const Color(0xFFF2B134));
        for (final dx in [-1.0, 1.0]) {
          c.save();
          c.translate(69, 76);
          c.rotate(dx * 0.5);
          c.drawOval(Rect.fromCenter(center: const Offset(6, 0), width: 11, height: 7), gold);
          c.drawOval(Rect.fromCenter(center: const Offset(6, 0), width: 11, height: 7), _l(const Color(0xFFC98A1E), 0.9));
          c.restore();
        }
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 74, 5, 5), const Radius.circular(1.5)),
            _f(const Color(0xFFE8445A)));
        continue;
      }
      final v = _sleeveCol[id];
      if (v == null) continue;
      final col = Color(v);
      final long = id == 'a_sweater' || id == 'a_hoodie' || id == 'a_tux';
      _both(c, () {
        c.save();
        c.translate(29.5, long ? 63 : 60);
        c.rotate(0.35);
        final r = Rect.fromCenter(center: Offset.zero, width: 15, height: long ? 26 : 17);
        c.drawOval(r, _f(col));
        c.drawOval(r, _l(p.line, 1));
        c.restore();
      });
    }
  }

  Path _heartP(Offset o, double r) => Path()
    ..moveTo(o.dx, o.dy + r * .9)
    ..cubicTo(o.dx - r * 1.6, o.dy - r * .2, o.dx - r * .7, o.dy - r * 1.2, o.dx, o.dy - r * .4)
    ..cubicTo(o.dx + r * .7, o.dy - r * 1.2, o.dx + r * 1.6, o.dy - r * .2, o.dx, o.dy + r * .9)
    ..close();

  Path _starP(Offset o, double ro) {
    final sp = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? ro : ro * .45;
      final an = -pi / 2 + i * pi / 5;
      final q = Offset(o.dx + r * cos(an), o.dy + r * sin(an));
      i == 0 ? sp.moveTo(q.dx, q.dy) : sp.lineTo(q.dx, q.dy);
    }
    return sp..close();
  }

  // punto de la curva de las diademas (de oreja a oreja)
  Offset _bz(double u) => Offset(
      (1 - u) * (1 - u) * 27 + 2 * u * (1 - u) * 50 + u * u * 73,
      (1 - u) * (1 - u) * 27 + 2 * u * (1 - u) * 2 + u * u * 27);

  void _band(Canvas c, Color col) {
    final bp = Path()
      ..moveTo(27, 27)
      ..quadraticBezierTo(50, 2, 73, 27);
    c.drawPath(bp, _l(Color.lerp(col, Colors.black, 0.3)!, 5.6));
    c.drawPath(bp, _l(col, 4));
    c.drawPath(bp, _l(const Color(0x66FFFFFF), 1.2));
  }

  void _capGen(Canvas c, Color m, Color d, [void Function()? deco]) {
    final dm = Path()
      ..moveTo(32, 18)
      ..cubicTo(31, -5, 69, -5, 68, 18)
      ..close();
    c.drawPath(dm, _g(dm.getBounds(), Color.lerp(m, Colors.white, 0.45)!, m));
    if (deco != null) {
      c.save();
      c.clipPath(dm);
      deco();
      c.restore();
    }
    c.drawPath(dm, _l(d, 1));
    c.drawLine(const Offset(50, 0), const Offset(50, 16), _l(const Color(0x33FFFFFF), 1));
    c.drawCircle(const Offset(50, 0.5), 2, _f(d));
    c.drawOval(Rect.fromCenter(center: const Offset(50, 18), width: 40, height: 7), _f(d));
    c.drawOval(Rect.fromCenter(center: const Offset(50, 20.5), width: 28, height: 5),
        _f(Color.lerp(d, Colors.black, 0.18)!));
  }

  // ---------------- complementos de la tienda ----------------
  void _accessories(Canvas c) {
    for (final id in acc) {
      switch (id) {
        case 'a_glasses':
          _both(c, () {
            c.drawRRect(
                RRect.fromRectAndRadius(
                    Rect.fromCenter(center: const Offset(39, 31), width: 17, height: 12),
                    const Radius.circular(4.5)),
                _f(const Color(0xFF1F1B2E)));
            c.drawLine(const Offset(33, 27.5), const Offset(37, 26.5), _l(const Color(0x88FFFFFF), 1.2));
            c.drawLine(const Offset(30.5, 30), const Offset(26.5, 29), _l(const Color(0xFF1F1B2E), 1.4));
          });
          c.drawLine(const Offset(46.5, 30), const Offset(53.5, 30), _l(const Color(0xFF1F1B2E), 1.6));
          break;
        case 'a_hat':
          c.drawOval(Rect.fromCenter(center: const Offset(50, 13), width: 38, height: 8),
              _f(const Color(0xFF2B2B3A)));
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(38, -4, 62, 12), const Radius.circular(3)),
              _f(const Color(0xFF2B2B3A)));
          c.drawRect(Rect.fromLTRB(38, 6, 62, 10), _f(const Color(0xFFE8445A)));
          c.drawOval(Rect.fromCenter(center: const Offset(50, -4), width: 24, height: 5),
              _f(const Color(0xFF3A3A4E)));
          break;
        case 'a_crown':
          final cr = Path()
            ..moveTo(37, 14)
            ..lineTo(36, -1)
            ..lineTo(43, 7)
            ..lineTo(50, -4)
            ..lineTo(57, 7)
            ..lineTo(64, -1)
            ..lineTo(63, 14)
            ..close();
          c.drawPath(cr, _f(const Color(0xFFFFD43B)));
          c.drawPath(cr, _l(const Color(0xFFC99A00), 1.1));
          for (final x in [43.0, 50.0, 57.0]) {
            c.drawCircle(Offset(x, 9), 1.6, _f(const Color(0xFFE8445A)));
          }
          break;
        case 'a_bow':
          final col = _f(const Color(0xFFFF5C8A));
          c.drawPath(
              Path()
                ..moveTo(68, 16)
                ..lineTo(78, 9)
                ..lineTo(78, 23)
                ..close(),
              col);
          c.drawPath(
              Path()
                ..moveTo(68, 16)
                ..lineTo(58, 9)
                ..lineTo(58, 23)
                ..close(),
              col);
          c.drawCircle(const Offset(68, 16), 3, _f(const Color(0xFFD63A6B)));
          break;
        case 'a_flower':
          for (int i = 0; i < 5; i++) {
            final ang = i * 2 * pi / 5;
            c.drawCircle(Offset(66 + cos(ang) * 4.3, 15 + sin(ang) * 4.3), 3.3, _f(const Color(0xFFFF8FB8)));
          }
          c.drawCircle(const Offset(66, 15), 2.6, _f(const Color(0xFFFFD43B)));
          break;
        case 'a_headphones':
          c.drawArc(Rect.fromCenter(center: const Offset(50, 33), width: 58, height: 54), pi * 1.08,
              pi * 0.84, false, _l(const Color(0xFF3B3F5C), 3.2));
          _both(c, () {
            final r = RRect.fromRectAndRadius(
                Rect.fromCenter(center: const Offset(23, 33), width: 8, height: 16), const Radius.circular(4));
            c.drawRRect(r, _f(const Color(0xFFE8445A)));
            c.drawRRect(r, _l(const Color(0xFF3B3F5C), 1.2));
          });
          break;
        case 'a_scarf':
          final scarfR = RRect.fromRectAndRadius(
              Rect.fromCenter(center: const Offset(50, 53), width: 40, height: 9), const Radius.circular(4.5));
          c.drawRRect(scarfR, _f(const Color(0xFFE8445A)));
          c.drawRRect(scarfR, _l(const Color(0xFFB82E44), 1));
          for (final x in [38.0, 46.0, 54.0, 62.0]) {
            c.drawLine(Offset(x, 49.5), Offset(x + 1.5, 56.5), _l(const Color(0x66FFFFFF), 1.6));
          }
          final tail = RRect.fromRectAndRadius(Rect.fromLTWH(58, 55, 8, 15), const Radius.circular(3));
          c.drawRRect(tail, _f(const Color(0xFFE8445A)));
          c.drawRRect(tail, _l(const Color(0xFFB82E44), 1));
          break;
        case 'a_bowtie':
          final tieCol = _f(const Color(0xFF3F51B5));
          c.drawPath(
              Path()
                ..moveTo(50, 55)
                ..lineTo(60, 49)
                ..lineTo(60, 61)
                ..close(),
              tieCol);
          c.drawPath(
              Path()
                ..moveTo(50, 55)
                ..lineTo(40, 49)
                ..lineTo(40, 61)
                ..close(),
              tieCol);
          c.drawCircle(const Offset(50, 55), 3, _f(const Color(0xFF2A3790)));
          break;
        case 'a_wizard':
          final wz = Path()
            ..moveTo(36, 13)
            ..lineTo(51, -24)
            ..lineTo(64, 13)
            ..close();
          c.drawOval(Rect.fromCenter(center: const Offset(50, 13), width: 42, height: 7),
              _f(const Color(0xFF4B3FA0)));
          c.drawPath(wz, _f(const Color(0xFF5B4BC8)));
          c.drawPath(wz, _l(const Color(0xFF3A2E8A), 1));
          c.drawRect(Rect.fromLTRB(40, 6, 61, 10), _f(const Color(0xFFFFD43B)));
          c.drawPath(_spark(const Offset(50, -6), 3.2), _f(const Color(0xFFFFE066)));
          c.drawPath(_spark(const Offset(46, 1), 2.2), _f(const Color(0xFFFFE066)));
          break;
        case 'a_chef':
          final chefP = _f(Colors.white);
          for (final x in [42.0, 50.0, 58.0]) {
            c.drawCircle(Offset(x, x == 50.0 ? -3.0 : 1.0), 8, chefP);
            c.drawCircle(Offset(x, x == 50.0 ? -3.0 : 1.0), 8, _l(const Color(0xFFC9CED8), 0.8));
          }
          final chefBase = RRect.fromRectAndRadius(Rect.fromLTRB(41, 4, 59, 14), const Radius.circular(2));
          c.drawRRect(chefBase, chefP);
          c.drawRRect(chefBase, _l(const Color(0xFFC9CED8), 0.8));
          break;
        case 'a_antlers':
          _both(c, () {
            final br = _l(const Color(0xFF8B5A3C), 2.4);
            c.drawLine(const Offset(40, 13), const Offset(34, -6), br);
            c.drawLine(const Offset(37, 4), const Offset(29, 0), br);
            c.drawLine(const Offset(35, -1), const Offset(35, -10), br);
          });
          break;
        case 'a_halo':
          final haloR = Rect.fromCenter(center: const Offset(50, 2), width: 30, height: 8);
          c.drawOval(haloR, _l(const Color(0x66FFD43B), 5));
          c.drawOval(haloR, _l(const Color(0xFFFFD43B), 2.4));
          break;
        case 'a_pirate':
          c.drawLine(const Offset(27, 25), const Offset(73, 33), _l(const Color(0xFF1F1B2E), 1.4));
          c.drawCircle(const Offset(61, 31), 7, _f(const Color(0xFF1F1B2E)));
          break;
        case 'a_mustache':
          _both(c, () {
            final ms = Path()
              ..moveTo(50, 44)
              ..quadraticBezierTo(46, 39.5, 37, 44.5)
              ..quadraticBezierTo(44, 47, 50, 46)
              ..close();
            c.drawPath(ms, _f(const Color(0xFF4A2E1F)));
          });
          break;
        case 'a_beanie':
          {
            final dm = Path()
              ..moveTo(33, 17)
              ..cubicTo(33, -6, 67, -6, 67, 17)
              ..close();
            c.drawPath(dm, _f(const Color(0xFF5BA8E8)));
            c.drawPath(dm, _l(const Color(0xFF2F78BD), 1));
            c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(31, 12, 38, 7), const Radius.circular(3.5)),
                _f(const Color(0xFFA8D4FA)));
            for (final x in [40.0, 50.0, 60.0]) {
              c.drawLine(Offset(x, 12), Offset(x, 3 + (x - 50).abs() * 0.35), _l(const Color(0x552F78BD), 1));
            }
            c.drawCircle(const Offset(50, -2), 5.5, _f(Colors.white));
            c.drawCircle(const Offset(50, -2), 5.5, _l(const Color(0xFFB7C7D8), 0.8));
          }
          break;
        case 'a_cap':
          {
            final dm = Path()
              ..moveTo(34, 16)
              ..cubicTo(34, -2, 66, -2, 66, 16)
              ..close();
            c.drawPath(dm, _f(const Color(0xFFE8445A)));
            c.drawPath(dm, _l(const Color(0xFFB82E44), 1));
            c.drawOval(Rect.fromCenter(center: const Offset(50, 16.5), width: 36, height: 7), _f(const Color(0xFFB82E44)));
            c.drawCircle(const Offset(50, 1.5), 2, _f(const Color(0xFFB82E44)));
            c.drawLine(const Offset(50, 3), const Offset(50, 13), _l(const Color(0x44FFFFFF), 1));
          }
          break;
        case 'a_santa':
          {
            final dm = Path()
              ..moveTo(33, 16)
              ..cubicTo(33, 2, 50, -9, 68, -3)
              ..quadraticBezierTo(65, 6, 67, 16)
              ..close();
            c.drawPath(dm, _f(const Color(0xFFE8445A)));
            c.drawPath(dm, _l(const Color(0xFFB82E44), 1));
            c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 12, 40, 7), const Radius.circular(3.5)), _f(Colors.white));
            c.drawCircle(const Offset(69, -3), 4.5, _f(Colors.white));
          }
          break;
        case 'a_cowboy':
          {
            c.drawOval(Rect.fromCenter(center: const Offset(50, 13), width: 50, height: 8), _f(const Color(0xFFB07A3C)));
            final cr = RRect.fromRectAndRadius(const Rect.fromLTWH(39, -3, 22, 16), const Radius.circular(5));
            c.drawRRect(cr, _f(const Color(0xFFB07A3C)));
            c.drawRRect(cr, _l(const Color(0xFF7A4F1F), 1));
            c.drawRect(const Rect.fromLTWH(39, 7, 22, 3.5), _f(const Color(0xFF6B3F1D)));
            c.drawPath(_spark(const Offset(50, 8.8), 2.4), _f(const Color(0xFFFFD43B)));
            c.drawOval(Rect.fromCenter(center: const Offset(50, -2), width: 14, height: 4), _f(const Color(0xFF8E5E2B)));
          }
          break;
        case 'a_sunhat':
          {
            c.drawOval(Rect.fromCenter(center: const Offset(50, 12.5), width: 54, height: 11), _f(const Color(0xFFF4D58D)));
            c.drawOval(Rect.fromCenter(center: const Offset(50, 12.5), width: 54, height: 11), _l(const Color(0xFFD9B35E), 1));
            final dm = Path()
              ..moveTo(37, 12)
              ..cubicTo(37, -4, 63, -4, 63, 12)
              ..close();
            c.drawPath(dm, _f(const Color(0xFFF8E3A8)));
            c.drawPath(dm, _l(const Color(0xFFD9B35E), 1));
            c.drawRect(const Rect.fromLTWH(37.5, 6, 25, 3.5), _f(const Color(0xFFFF8FB8)));
            c.drawCircle(const Offset(63, 8), 2.6, _f(const Color(0xFFFF8FB8)));
            c.drawCircle(const Offset(66, 11), 2, _f(const Color(0xFFFF8FB8)));
          }
          break;
        case 'a_bunny':
          _both(c, () {
            c.save();
            c.translate(41.5, 6);
            c.rotate(-0.2);
            final ear = Rect.fromCenter(center: Offset.zero, width: 9.5, height: 28);
            c.drawOval(ear, _f(Colors.white));
            c.drawOval(ear, _l(const Color(0xFFD6C2D8), 1));
            c.drawOval(Rect.fromCenter(center: const Offset(0, 1), width: 4.5, height: 20), _f(const Color(0xFFFFB6D5)));
            c.restore();
          });
          break;
        case 'a_graduate':
          {
            c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(39, 7, 22, 9), const Radius.circular(3)), _f(const Color(0xFF2B2B3A)));
            final bd = Path()
              ..moveTo(50, -2)
              ..lineTo(73, 5)
              ..lineTo(50, 12)
              ..lineTo(27, 5)
              ..close();
            c.drawPath(bd, _f(const Color(0xFF3A3A4E)));
            c.drawPath(bd, _l(const Color(0xFF1F1B2E), 1));
            c.drawLine(const Offset(50, 5), const Offset(68, 7.5), _l(const Color(0xFFFFD43B), 1.2));
            c.drawLine(const Offset(68, 7.5), const Offset(68, 17), _l(const Color(0xFFFFD43B), 1.5));
            c.drawCircle(const Offset(68, 18), 1.8, _f(const Color(0xFFFFD43B)));
            c.drawCircle(const Offset(50, 5), 1.6, _f(const Color(0xFFFFD43B)));
          }
          break;
        case 'a_balloon':
          final hr = Offset(100 - _hand.dx, _hand.dy);
          c.drawLine(hr, const Offset(82, 30), _l(const Color(0xFF7A7A8C), 0.8));
          final bl = Rect.fromCenter(center: const Offset(82, 21), width: 15, height: 19);
          c.drawOval(bl, _g(bl, const Color(0xFFFF8A8A), const Color(0xFFE8445A)));
          c.drawOval(bl, _l(const Color(0xFFB82E44), 0.9));
          c.drawCircle(const Offset(79, 16), 1.8, _f(const Color(0x99FFFFFF)));
          c.drawPath(
              Path()
                ..moveTo(82, 30.5)
                ..lineTo(80.5, 33)
                ..lineTo(83.5, 33)
                ..close(),
              _f(const Color(0xFFB82E44)));
          break;
        case 'a_hb_star':
          {
            _band(c, const Color(0xFFB59CFF));
            for (final u in [0.2, 0.5, 0.8]) {
              final sp = _starP(_bz(u).translate(0, -1.5), u == 0.5 ? 5.4 : 4.2);
              c.drawPath(sp, _f(const Color(0xFFFFD84D)));
              c.drawPath(sp, _l(const Color(0xFFD99A1E), 0.8));
            }
          }
          break;
        case 'a_hb_heart':
          {
            _band(c, const Color(0xFFFF8FB8));
            for (final u in [0.2, 0.5, 0.8]) {
              final hp = _heartP(_bz(u).translate(0, -3), u == 0.5 ? 4.2 : 3.2);
              c.drawPath(hp, _f(const Color(0xFFFF4F86)));
              c.drawPath(hp, _l(const Color(0xFFB82E5E), 0.8));
            }
          }
          break;
        case 'a_hb_flower':
          {
            _band(c, const Color(0xFF5DB86A));
            for (final u in [0.15, 0.38, 0.62, 0.85]) {
              final o = _bz(u).translate(0, -1.5);
              for (int k = 0; k < 5; k++) {
                c.drawCircle(o + Offset(2.6 * cos(k * 1.2566), 2.6 * sin(k * 1.2566)), 2.1,
                    _f(u < 0.5 ? const Color(0xFFFF8FB8) : Colors.white));
              }
              c.drawCircle(o, 1.8, _f(const Color(0xFFFFD84D)));
            }
          }
          break;
        case 'a_hb_cat':
          {
            _band(c, const Color(0xFF3B3B4E));
            _both(c, () {
              c.drawPath(Path()..moveTo(31, 22)..lineTo(32, 3)..lineTo(44, 13)..close(), _f(const Color(0xFF3B3B4E)));
              c.drawPath(Path()..moveTo(34, 18)..lineTo(34.5, 8)..lineTo(41, 13.5)..close(), _f(const Color(0xFFFF8FB8)));
            });
          }
          break;
        case 'a_hb_rainbow':
          {
            const rbh = [Color(0xFFFF6B8B), Color(0xFFFFB04C), Color(0xFFFFE066), Color(0xFF7DDFA8), Color(0xFF7ED6FF), Color(0xFFB59CFF)];
            for (int i = 0; i < rbh.length; i++) {
              final bp = Path()
                ..moveTo(27, 27 + i * 0.9)
                ..quadraticBezierTo(50, 2 + i * 0.9, 73, 27 + i * 0.9);
              c.drawPath(bp, _l(rbh[i], 1.1));
            }
          }
          break;
        case 'a_tiara':
          {
            final tp = Path()
              ..moveTo(35, 16)
              ..lineTo(37, 7)
              ..lineTo(43, 12)
              ..lineTo(50, 2)
              ..lineTo(57, 12)
              ..lineTo(63, 7)
              ..lineTo(65, 16)
              ..close();
            c.drawPath(tp, _g(tp.getBounds(), const Color(0xFFFFF3B0), const Color(0xFFE8B52E)));
            c.drawPath(tp, _l(const Color(0xFFC99A00), 1));
            c.drawCircle(const Offset(50, 8), 2.2, _f(const Color(0xFFFF5C9A)));
            for (final x in [42.0, 58.0]) {
              c.drawCircle(Offset(x, 12), 1.5, _f(const Color(0xFF6CC6FF)));
            }
            for (final x in [37.0, 63.0]) {
              c.drawCircle(Offset(x, 7), 1.3, _f(Colors.white));
            }
          }
          break;
        case 'a_cap_pink':
          _capGen(c, const Color(0xFFFF8FB8), const Color(0xFFD9578A));
          c.drawPath(_heartP(const Offset(50, 8), 3.4), _f(Colors.white));
          break;
        case 'a_cap_blue':
          _capGen(c, const Color(0xFF4FA3FF), const Color(0xFF2B72C9));
          c.drawPath(_starP(const Offset(50, 8), 4.6), _f(const Color(0xFFFFE066)));
          break;
        case 'a_cap_rainbow':
          _capGen(c, Colors.white, const Color(0xFF8A78B8), () {
            const rbc = [Color(0xFFFF6B8B), Color(0xFFFFB04C), Color(0xFFFFE066), Color(0xFF7DDFA8), Color(0xFF7ED6FF), Color(0xFFB59CFF)];
            for (int i = 0; i < 6; i++) {
              c.drawRect(Rect.fromLTWH(31 + i * 6.2, -8, 6.3, 30), _f(rbc[i]));
            }
          });
          break;
        case 'a_pompom':
          {
            final dm = Path()
              ..moveTo(32, 17)
              ..cubicTo(31, -8, 69, -8, 68, 17)
              ..close();
            c.drawPath(dm, _f(const Color(0xFFFF8FB8)));
            c.save();
            c.clipPath(dm);
            for (final y in [2.0, 8.0]) {
              c.drawRect(Rect.fromLTWH(30, y, 40, 3), _f(Colors.white));
            }
            c.restore();
            c.drawPath(dm, _l(const Color(0xFFD9578A), 1));
            final cuff = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 12, 40, 8), const Radius.circular(4));
            c.drawRRect(cuff, _f(Colors.white));
            c.drawRRect(cuff, _l(const Color(0xFFD6C2D8), 0.9));
            c.drawCircle(const Offset(50, -3), 6.5, _f(Colors.white));
            c.drawCircle(const Offset(50, -3), 6.5, _l(const Color(0xFFD6C2D8), 0.9));
          }
          break;
        case 'a_beret':
          {
            c.save();
            c.translate(54, 8);
            c.rotate(-0.12);
            final bp = Rect.fromCenter(center: Offset.zero, width: 44, height: 17);
            c.drawOval(bp, _g(bp, const Color(0xFFFF6F7F), const Color(0xFFC93A4E)));
            c.drawOval(bp, _l(const Color(0xFF9A2A3A), 1));
            c.drawLine(const Offset(0, -8.5), const Offset(0.5, -12), _l(const Color(0xFF9A2A3A), 2));
            c.restore();
          }
          break;
        case 'a_bucket':
          {
            c.drawOval(Rect.fromCenter(center: const Offset(50, 17), width: 50, height: 9), _f(const Color(0xFFF2C84B)));
            final bk = Path()
              ..moveTo(36, 17)
              ..lineTo(38, 2)
              ..quadraticBezierTo(50, -1, 62, 2)
              ..lineTo(64, 17)
              ..close();
            c.drawPath(bk, _f(const Color(0xFFFFDC6B)));
            c.drawPath(bk, _l(const Color(0xFFC99A1E), 1));
            c.drawRect(const Rect.fromLTWH(37.5, 9, 25, 3.2), _f(const Color(0xFF4FA3FF)));
            c.drawOval(Rect.fromCenter(center: const Offset(50, 17), width: 50, height: 9), _l(const Color(0xFFC99A1E), 1));
          }
          break;
        case 'a_necklace':
          for (int i = 0; i < 9; i++) {
            final an = pi * (0.12 + i * 0.095);
            final o = Offset(50 + 15 * cos(an), 46 + 12 * sin(an));
            c.drawCircle(o, 2, _f(const Color(0xFFFFF8F0)));
            c.drawCircle(o, 2, _l(const Color(0xFFD6C2D8), 0.7));
          }
          break;
        case 'a_neck_heart':
          c.drawArc(Rect.fromCenter(center: const Offset(50, 46), width: 30, height: 24), 0.2, pi - 0.4, false,
              _l(const Color(0xFFE8B52E), 1.1));
          c.drawPath(_heartP(const Offset(50, 60), 3.4), _f(const Color(0xFFFF4F86)));
          c.drawPath(_heartP(const Offset(50, 60), 3.4), _l(const Color(0xFFB82E5E), 0.7));
          break;
        case 'a_neck_bell':
          {
            final bd = RRect.fromRectAndRadius(const Rect.fromLTWH(37, 50, 26, 5), const Radius.circular(2.5));
            c.drawRRect(bd, _f(const Color(0xFFE8445A)));
            for (final x in [42.0, 50.0, 58.0]) {
              c.drawCircle(Offset(x, 52.5), 0.9, _f(Colors.white));
            }
            c.drawCircle(const Offset(50, 58), 3.4, _f(const Color(0xFFFFD84D)));
            c.drawCircle(const Offset(50, 58), 3.4, _l(const Color(0xFFC99A1E), 0.8));
            c.drawLine(const Offset(46.8, 58.5), const Offset(53.2, 58.5), _l(const Color(0xFFC99A1E), 0.8));
          }
          break;
        case 'a_gl_heart':
          _both(c, () {
            c.drawPath(_heartP(const Offset(39, 30.5), 6.4), _f(const Color(0x88FF5C8A)));
            c.drawPath(_heartP(const Offset(39, 30.5), 6.4), _l(const Color(0xFFD9336E), 1.5));
            c.drawLine(const Offset(30, 30), const Offset(26.5, 29), _l(const Color(0xFFD9336E), 1.2));
          });
          c.drawLine(const Offset(46, 29), const Offset(54, 29), _l(const Color(0xFFD9336E), 1.4));
          break;
        case 'a_wand':
          {
            final hnd = Offset(100 - _hand.dx, _hand.dy);
            final tip = hnd + const Offset(12, -20);
            c.drawLine(hnd, tip, _l(const Color(0xFFE8B8FF), 2.4));
            c.drawLine(hnd, tip, _l(const Color(0x66FFFFFF), 0.8));
            c.drawPath(_starP(tip, 6.5), _f(const Color(0xFFFFE066)));
            c.drawPath(_starP(tip, 6.5), _l(const Color(0xFFD99A1E), 0.9));
            c.drawPath(_spark(tip + const Offset(8, -3), 2.4), _f(Colors.white));
          }
          break;
        case 'a_lolli':
          {
            final hnd = Offset(100 - _hand.dx, _hand.dy);
            final ctr = hnd + const Offset(5, -16);
            c.drawLine(hnd, ctr, _l(const Color(0xFFF2EEF8), 2));
            c.drawCircle(ctr, 8.5, _f(const Color(0xFFFF8FB8)));
            for (int i = 0; i < 3; i++) {
              c.drawArc(Rect.fromCircle(center: ctr, radius: 2.4 + i * 2.4), i * 1.2, 4.2, false, _l(Colors.white, 1.3));
            }
            c.drawCircle(ctr, 8.5, _l(const Color(0xFFD9578A), 1));
          }
          break;
        case 'a_backpack':
          _both(c, () {
            c.drawLine(const Offset(38, 52), const Offset(36, 76), _l(const Color(0xFFC96A1E), 3));
            c.drawLine(const Offset(38, 52), const Offset(36, 76), _l(const Color(0x55FFFFFF), 0.8));
          });
          break;
        case 'a_stickers':
          _both(c, () {
            c.drawPath(_starP(const Offset(29.5, 40), 3.2), _f(const Color(0xFFFFE066)));
            c.drawPath(_heartP(const Offset(34, 47), 1.8), _f(const Color(0xFFFF4F86)));
          });
          break;
        case 'a_freckles':
          _both(c, () {
            for (final o in const [Offset(32, 38.5), Offset(35.5, 40), Offset(30.5, 41.8), Offset(34.5, 43.5)]) {
              c.drawCircle(o, 0.8, _f(const Color(0xFFB9784A)));
            }
          });
          break;
        default:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(_AnimalPainter o) => true;
}
