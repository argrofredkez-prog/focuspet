import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';

enum Animal { cerdo, unicornio, tigre, cocodrilo }

const animalColors = {
  Animal.cerdo: Color(0xFFFFB3C7),
  Animal.unicornio: Color(0xFFCDB4FF),
  Animal.tigre: Color(0xFFFFB347),
  Animal.cocodrilo: Color(0xFF7BD389),
};

class _Pal {
  final Color base, light, belly, line, accent;
  const _Pal(this.base, this.light, this.belly, this.line, this.accent);
}

const _pals = {
  Animal.cerdo: _Pal(Color(0xFFFFB3C7), Color(0xFFFFDCE6), Color(0xFFFFE6EE), Color(0xFFC2557A), Color(0xFFFF8FAB)),
  Animal.unicornio: _Pal(Color(0xFFF1EAFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF9C84D4), Color(0xFFFFB6D5)),
  Animal.tigre: _Pal(Color(0xFFFFA94D), Color(0xFFFFD08A), Color(0xFFFFF3D6), Color(0xFF9A5418), Color(0xFFFF8FAB)),
  Animal.cocodrilo: _Pal(Color(0xFF6CCB7A), Color(0xFFA6E8A8), Color(0xFFF5E6B8), Color(0xFF2F7D4F), Color(0xFF3FA062)),
};

/// Animal de cuerpo completo. mode: -1 neutro, 0 estudiar, 1 entrenar, 2 dormir.
class FocusAnimal extends StatefulWidget {
  final Animal animal;
  final double size;
  final double scale; // etapa: bebé, joven, adulto
  final int mode;
  final List<String> acc; // ids de complementos puestos
  final double eat; // animación de comer: -1 = no, 0..1 = progreso
  final Item? food;
  const FocusAnimal({
    super.key,
    required this.animal,
    this.size = 240,
    this.scale = 1.0,
    this.mode = -1,
    this.acc = const [],
    this.eat = -1,
    this.food,
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
    final w = (it.slot == 'eyes' ? 40.0 : (it.slot == 'back' ? 46.0 : 28.0)) * sz / 100;
    const ys = {'eyes': 33.0, 'neck': 54.0, 'face': 46.0, 'back': 70.0, 'hand': 62.0};
    final cy = ys[it.slot] ?? 6.0;
    final cx = it.slot == 'hand' ? 78.0 : 50.0;
    return Positioned(
      left: 0.2 * sz + cx * sz / 100 - w / 2,
      top: 0.2 * sz + cy * sz / 100 - w / 2,
      child: Image.memory(b, width: w, height: w),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = animalColors[widget.animal]!;
    final sz = widget.size;
    return SizedBox(
      width: sz * 1.4,
      height: sz * 1.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final wave = sin(_c.value * 2 * pi);
          final blink = _c.value > 0.94;
          return Stack(alignment: Alignment.center, children: [
            CustomPaint(size: Size.square(sz * 1.4), painter: _AuraPainter(_c.value, color)),
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
                            widget.animal, widget.mode, blink, widget.acc, widget.eat)),
                    for (final id in widget.acc)
                      if (id.startsWith('c_')) _custom(id, sz),
                    ..._eatWidgets(sz),
                  ]),
                ),
              ),
            ),
            if (widget.mode == 2)
              for (int i = 0; i < 3; i++) _zzz((_c.value + i / 3) % 1, color),
          ]);
        },
      ),
    );
  }

  // La comida cae a la boca y salen corazones al tragar
  List<Widget> _eatWidgets(double sz) {
    final e = widget.eat;
    final f = widget.food;
    if (e < 0 || f == null) return const [];
    final fs = 0.22 * sz;
    final out = <Widget>[];
    if (e < 0.42) {
      final k = e / 0.42;
      final y = (0.02 + 0.67 * k * k) * sz - fs / 2;
      final s = k > 0.8 ? 1 - (k - 0.8) / 0.2 * 0.7 : 1.0;
      out.add(Positioned(
        left: 0.7 * sz - fs / 2,
        top: y,
        child: Transform.scale(
          scale: s,
          child: f.img != null
              ? Image.memory(f.img!, width: fs, height: fs)
              : Text(f.emoji, style: TextStyle(fontSize: fs * 0.85)),
        ),
      ));
    }
    if (e >= 0.6) {
      final k = (e - 0.6) / 0.4;
      for (int i = 0; i < 3; i++) {
        out.add(Positioned(
          left: 0.7 * sz + (i - 1) * 0.22 * sz - 8,
          top: 0.3 * sz - k * 0.25 * sz * (1 + i * 0.25),
          child: Opacity(
              opacity: (1 - k).clamp(0.0, 1.0).toDouble(),
              child: Text('💖', style: TextStyle(fontSize: 0.1 * sz + 6))),
        ));
      }
    }
    return out;
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
  final double eat;
  _AnimalPainter(this.a, this.mode, this.blink, this.acc, this.eat);

  _Pal get p => _pals[a]!;
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

  Offset get _hl => mode == 1
      ? const Offset(23, 41)
      : (mode == 0
          ? const Offset(38, 74)
          : (mode == 2 ? const Offset(43, 76) : const Offset(28, 76)));

  Path _spark(Offset o, double r) => Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
    ..close();

  // bulto al tragar
  void _gulp(Canvas c) {
    if (eat < 0.5 || eat > 0.8) return;
    final k = (eat - 0.5) / 0.3;
    c.drawCircle(Offset(50, 54 + 12 * k), 3.6, _f(p.light));
    c.drawCircle(Offset(50, 54 + 12 * k), 3.6, _l(p.line, 0.7));
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
    if (a == Animal.unicornio) _mane(c);
    _back(c);
    _feet(c);
    _body(c);
    if (mode == 0) _book(c);
    _arms(c);
    _ears(c);
    _head(c);
    _face(c);
    _gulp(c);
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
        const cols = [
          Color(0xFFFF8FA3), Color(0xFFFFC27A), Color(0xFFFFF29C),
          Color(0xFFA8E6A1), Color(0xFF9AD1FF), Color(0xFFC3A6FF)
        ];
        for (int i = 0; i < cols.length; i++) {
          c.drawPath(
              Path()
                ..moveTo(66, 80)
                ..cubicTo(84.0 + i * 1.5, 84, 92, 66.0 - i * 1.5, 84.0 + i, 52.0 - i * 2),
              _l(cols[i], 3.2));
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
          final tp = Path()
            ..moveTo(66, 82)
            ..cubicTo(84, 88, 94, 74, 90, 60);
          c.drawPath(tp, _l(p.line, 11));
          c.drawPath(tp, _l(p.base, 9));
          final m = tp.computeMetrics().first;
          for (double d = 6; d < m.length - 2; d += 8) {
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
  void _mane(Canvas c) {
    const cols = [
      Color(0xFFFF8FA3), Color(0xFFFFC27A), Color(0xFFFFF29C),
      Color(0xFFA8E6A1), Color(0xFF9AD1FF), Color(0xFFC3A6FF)
    ];
    _both(c, () {
      for (int i = 0; i < cols.length; i++) {
        c.drawPath(
            Path()
              ..moveTo(48, 12.0 + i)
              ..cubicTo(26.0 - i, 4, 14.0 - i * 1.5, 30.0 + i * 2, 26.0 + i * 2, 54.0 + i * 3),
            _l(cols[i], 4.5));
      }
    });
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
    final hl = _hl;
    _both(c, () {
      c.drawLine(const Offset(34, 58), hl, _l(p.line, 10.5));
      c.drawLine(const Offset(34, 58), hl, _l(p.base, 8.5));
      if (a == Animal.tigre) {
        final mid = Offset.lerp(const Offset(34, 58), hl, 0.5)!;
        c.drawLine(mid.translate(-3.5, 0), mid.translate(3.5, 0), _l(const Color(0xFF3A2A1E), 1.8));
      }
      c.drawCircle(hl, 5.2, _f(p.base));
      c.drawCircle(hl, 5.2, _l(p.line, 1.1));
    });
    if (mode == 1) {
      _both(c, () {
        c.drawLine(hl.translate(-10, 0), hl.translate(10, 0), _l(const Color(0xFF8A8FA3), 2.4));
        for (final dx in [-10.0, 10.0]) {
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
          final path = Path()
            ..moveTo(33, 20)
            ..lineTo(29, 2)
            ..lineTo(44, 14)
            ..close();
          c.drawPath(path, _f(p.base));
          c.drawPath(path, _l(p.line, 1.1));
          c.drawPath(
              Path()
                ..moveTo(34, 17)
                ..lineTo(32, 7)
                ..lineTo(40, 14)
                ..close(),
              _f(p.accent));
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
          c.drawCircle(const Offset(37, 14), 7.5, _f(p.base));
          c.drawCircle(const Offset(37, 14), 7.5, _l(p.line, 1.1));
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
        ..moveTo(44, 13)
        ..lineTo(50, -6)
        ..lineTo(56, 13)
        ..close();
      c.drawPath(h, _g(h.getBounds(), const Color(0xFFFFF1A8), const Color(0xFFFFC94D)));
      c.drawPath(h, _l(const Color(0xFFD99A1E), 1));
      c.drawLine(const Offset(46.5, 10), const Offset(52, 8), _l(const Color(0xFFD99A1E), 0.8));
      c.drawLine(const Offset(47.5, 5.5), const Offset(52.5, 3.5), _l(const Color(0xFFD99A1E), 0.8));
      c.drawLine(const Offset(48.5, 1), const Offset(52, -0.5), _l(const Color(0xFFD99A1E), 0.8));
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
    _both(c, () => c.drawCircle(const Offset(33.5, 42), 4.6, _f(const Color(0x66FF6F9C))));
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
          final r = Rect.fromCenter(center: const Offset(50, 43), width: 18, height: 12);
          c.drawOval(r, _f(const Color(0xFFFFE4EF)));
          c.drawOval(r, _l(p.line, 0.9));
          _both(c, () => c.drawCircle(const Offset(46.5, 43), 1.1, _f(p.line)));
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
          final r = Rect.fromCenter(center: const Offset(50, 45), width: 34, height: 17);
          c.drawOval(r, _g(r, p.light, const Color(0xFF8EDC96)));
          c.drawOval(r, _l(p.line, 1.1));
          _both(c, () => c.drawCircle(const Offset(43, 41), 1.4, _f(p.line)));
        }
        break;
    }

    final closed = mode == 2 || blink;
    _both(c, () {
      const e = Offset(39, 31);
      if (eat >= 0.6) {
        c.drawArc(Rect.fromCenter(center: e, width: 11, height: 8), pi, pi, false, _l(ink, 1.8));
      } else if (closed) {
        c.drawArc(Rect.fromCenter(center: e, width: 11, height: 7), 0.15, pi - 0.3, false, _l(ink, 1.6));
      } else {
        c.drawOval(Rect.fromCenter(center: e, width: 11.5, height: 13), _f(Colors.white));
        c.drawOval(Rect.fromCenter(center: e.translate(0.4, 1), width: 8.2, height: 10.2), _f(ink));
        c.drawCircle(e.translate(-1.2, -1.6), 2.1, _f(Colors.white));
        c.drawCircle(e.translate(1.8, 2.8), 1, _f(const Color(0xCCFFFFFF)));
      }
      if (mode == 1) {
        c.drawLine(const Offset(33.5, 24.5), const Offset(43.5, 27), _l(ink, 1.8));
      }
    });

    final my = a == Animal.cocodrilo ? 50.0 : 49.0;
    if (eat >= 0 && eat < 0.42) {
      c.drawOval(Rect.fromCenter(center: Offset(50, my), width: 12, height: 10),
          _f(const Color(0xFF7A2E45)));
      c.drawOval(Rect.fromCenter(center: Offset(50, my + 2.4), width: 7, height: 3.4),
          _f(const Color(0xFFFF8FAB)));
    } else if (eat >= 0.42 && eat < 0.6) {
      c.drawOval(Rect.fromCenter(center: Offset(50, my), width: 8, height: 2 + 3 * sin(eat * 60).abs()),
          _f(const Color(0xFF7A2E45)));
    } else if (eat >= 0.6) {
      c.drawArc(Rect.fromCenter(center: Offset(50, my - 1.5), width: 13, height: 8), 0, pi, true,
          _f(const Color(0xFF7A2E45)));
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
        case 'a_balloon':
          final hr = Offset(100 - _hl.dx, _hl.dy);
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
        default:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(_AnimalPainter o) =>
      o.a != a || o.mode != mode || o.blink != blink || o.eat != eat || o.acc.join(',') != acc.join(',');
}
