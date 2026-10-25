import 'dart:math';
import 'package:flutter/material.dart';

enum Animal { cerdo, unicornio, tigre, cocodrilo }

const animalColors = {
  Animal.cerdo: Color(0xFFFFB3C7),
  Animal.unicornio: Color(0xFFCDB4FF),
  Animal.tigre: Color(0xFFFFB347),
  Animal.cocodrilo: Color(0xFF7BD389),
};

/// Animal dormido/meditando (o entrenando): respira, aura y "Zzz"/"💪".
class FocusAnimal extends StatefulWidget {
  final Animal animal;
  final double size;
  final double scale; // crece con la etapa (bebé, joven, adulto)
  final int mode; // 0 estudiar, 1 entrenar, 2 dormir
  final String accessory; // emoji o ''
  const FocusAnimal({
    super.key,
    required this.animal,
    this.size = 240,
    this.scale = 1.0,
    this.mode = 0,
    this.accessory = '',
  });

  @override
  State<FocusAnimal> createState() => _FocusAnimalState();
}

class _FocusAnimalState extends State<FocusAnimal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Duration(milliseconds: const [4000, 2000, 6000][widget.mode]))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
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
          return Stack(alignment: Alignment.center, children: [
            CustomPaint(size: Size.square(sz * 1.4), painter: _AuraPainter(_c.value, color)),
            Transform.translate(
              offset: Offset(0, widget.mode == 1 ? -8 * wave.abs() : 0),
              child: Transform.scale(
                scale: widget.scale * (1 + 0.04 * wave),
                child: SizedBox(
                  width: sz * 1.4,
                  height: sz * 1.4,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                        size: Size.square(sz), painter: _AnimalPainter(widget.animal, color)),
                    if (widget.accessory.isNotEmpty)
                      Positioned(
                          top: sz * 0.13,
                          child: Text(widget.accessory,
                              style: TextStyle(fontSize: sz * 0.24))),
                  ]),
                ),
              ),
            ),
            for (int i = 0; i < 3; i++) _zzz((_c.value + i / 3) % 1, color),
          ]);
        },
      ),
    );
  }

  Widget _zzz(double p, Color color) => Positioned(
        right: widget.size * 0.15 + p * 20,
        top: widget.size * 0.55 - p * widget.size * 0.5,
        child: Opacity(
          opacity: sin(p * pi).clamp(0.0, 1.0).toDouble(),
          child: Text(const ['✨', '💪', 'Z'][widget.mode],
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
            ..color = color.withAlpha((255 * 0.25 * (1 - p)).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6);
    }
  }

  @override
  bool shouldRepaint(_AuraPainter o) => o.t != t;
}

class _AnimalPainter extends CustomPainter {
  final Animal animal;
  final Color color;
  _AnimalPainter(this.animal, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.32;
    final fill = Paint()..color = color;
    final nose = Paint()..color = const Color(0xFF4A3B5C);
    final dark = Paint()
      ..color = const Color(0xFF4A3B5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Orejas / cuerno / pinchos
    switch (animal) {
      case Animal.unicornio:
        canvas.drawPath(
            Path()
              ..moveTo(c.dx - 12, c.dy - r + 6)
              ..lineTo(c.dx, c.dy - r - 42)
              ..lineTo(c.dx + 12, c.dy - r + 6),
            Paint()..color = const Color(0xFFFFE08A));
        for (final d in [-1, 1]) {
          canvas.drawCircle(Offset(c.dx + d * r * 0.7, c.dy - r * 0.75), 16, fill);
        }
        break;
      case Animal.cocodrilo:
        final spike = Paint()..color = const Color(0xFF4FA868);
        for (int i = -2; i <= 2; i++) {
          final x = c.dx + i * r * 0.3;
          final y = c.dy - r * 0.92 + i * i * r * 0.05;
          canvas.drawPath(
              Path()
                ..moveTo(x - 10, y + 8)
                ..lineTo(x, y - 18)
                ..lineTo(x + 10, y + 8),
              spike);
        }
        break;
      default:
        for (final d in [-1, 1]) {
          canvas.drawCircle(Offset(c.dx + d * r * 0.75, c.dy - r * 0.8), 20, fill);
        }
    }

    // Cuerpo + cabeza
    canvas.drawOval(
        Rect.fromCenter(center: c.translate(0, r * 1.1), width: r * 2, height: r * 1.3), fill);
    if (animal == Animal.cocodrilo) {
      canvas.drawOval(
          Rect.fromCenter(center: c.translate(0, r * 1.2), width: r * 1.1, height: r * 0.9),
          Paint()..color = const Color(0xFFF5E6B8));
    }
    canvas.drawCircle(c, r, fill);

    if (animal == Animal.tigre) {
      for (final d in [-1, 0, 1]) {
        canvas.drawLine(
            Offset(c.dx + d * 18, c.dy - r), Offset(c.dx + d * 18, c.dy - r + 18), dark);
      }
    }
    if (animal == Animal.cocodrilo) {
      canvas.drawOval(
          Rect.fromCenter(center: c.translate(0, r * 0.42), width: r * 1.3, height: r * 0.75),
          Paint()..color = const Color(0xFFA6E8A8));
      for (final d in [-1, 1]) {
        canvas.drawCircle(c.translate(d * r * 0.25, r * 0.2), 3, nose);
      }
    }

    // Ojos cerrados + mejillas + boquita
    for (final d in [-1, 1]) {
      final e = Offset(c.dx + d * r * 0.45, c.dy + 2);
      canvas.drawArc(Rect.fromCenter(center: e, width: 22, height: 14), 0, pi, false, dark);
      canvas.drawCircle(e.translate(d * 8.0, 20), 9,
          Paint()..color = const Color(0x8CFF8FAB));
    }
    canvas.drawArc(
        Rect.fromCenter(center: c.translate(0, 26), width: 14, height: 10), 0, pi, false, dark);

    if (animal == Animal.cerdo) {
      canvas.drawOval(Rect.fromCenter(center: c.translate(0, 14), width: 34, height: 22),
          Paint()..color = const Color(0xFFFF8FAB));
      for (final d in [-1, 1]) {
        canvas.drawCircle(c.translate(d * 6.0, 14), 2.5, nose);
      }
    }

    // Manitos juntas
    canvas.drawCircle(c.translate(-14, r * 1.15), 12, fill);
    canvas.drawCircle(c.translate(14, r * 1.15), 12, fill);
  }

  @override
  bool shouldRepaint(_AnimalPainter o) => o.animal != animal;
}
