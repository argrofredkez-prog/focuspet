import 'dart:math';
import 'package:flutter/material.dart';

enum Animal { cerdo, unicornio, tigre, pantera }

const animalColors = {
  Animal.cerdo: Color(0xFFFFB3C7),
  Animal.unicornio: Color(0xFFCDB4FF),
  Animal.tigre: Color(0xFFFFB347),
  Animal.pantera: Color(0xFF6C5CE7),
};

/// Animal dormido/meditando: respiración, aura expansiva y "Zzz" flotantes.
class FocusAnimal extends StatefulWidget {
  final Animal animal;
  final double size;
  const FocusAnimal({super.key, required this.animal, this.size = 240});

  @override
  State<FocusAnimal> createState() => _FocusAnimalState();
}

class _FocusAnimalState extends State<FocusAnimal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = animalColors[widget.animal]!;
    return SizedBox(
      width: widget.size * 1.4,
      height: widget.size * 1.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          CustomPaint(
              size: Size.square(widget.size * 1.4),
              painter: _AuraPainter(_c.value, color)),
          Transform.scale(
            scale: 1 + 0.04 * sin(_c.value * 2 * pi), // respirar
            child: CustomPaint(
                size: Size.square(widget.size),
                painter: _AnimalPainter(widget.animal, color)),
          ),
          for (int i = 0; i < 3; i++) _zzz((_c.value + i / 3) % 1, i),
        ]),
      ),
    );
  }

  Widget _zzz(double p, int i) => Positioned(
        right: widget.size * 0.15 + p * 20,
        top: widget.size * 0.55 - p * widget.size * 0.5,
        child: Opacity(
          opacity: sin(p * pi).clamp(0.0, 1.0),
          child: Text('Z',
              style: TextStyle(
                  fontSize: 14 + p * 16,
                  fontWeight: FontWeight.w800,
                  color: animalColors[widget.animal]!.withOpacity(0.9))),
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
            ..color = color.withOpacity(0.25 * (1 - p))
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
    final dark = Paint()
      ..color = const Color(0xFF4A3B5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Orejas / cuerno
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
      case Animal.pantera:
        for (final d in [-1, 1]) {
          canvas.drawPath(
              Path()
                ..moveTo(c.dx + d * r * 0.35, c.dy - r * 0.85)
                ..lineTo(c.dx + d * r * 0.8, c.dy - r * 1.35)
                ..lineTo(c.dx + d * r * 0.95, c.dy - r * 0.5),
              fill);
        }
        break;
      default:
        for (final d in [-1, 1]) {
          canvas.drawCircle(
              Offset(c.dx + d * r * 0.75, c.dy - r * 0.8), 20, fill);
        }
    }

    // Cuerpo + cabeza (cabeza redonda, cuerpo sentado en postura zen)
    canvas.drawOval(
        Rect.fromCenter(center: c.translate(0, r * 1.1), width: r * 2, height: r * 1.3),
        fill);
    canvas.drawCircle(c, r, fill);

    // Rayas del tigre
    if (animal == Animal.tigre) {
      for (final d in [-1, 0, 1]) {
        canvas.drawLine(Offset(c.dx + d * 18, c.dy - r), Offset(c.dx + d * 18, c.dy - r + 18), dark);
      }
    }

    // Ojos cerrados (arcos ^ ^ sonrientes) + mejillas + boquita
    for (final d in [-1, 1]) {
      final e = Offset(c.dx + d * r * 0.45, c.dy + 2);
      canvas.drawArc(Rect.fromCenter(center: e, width: 22, height: 14), 0, pi, false, dark);
      canvas.drawCircle(e.translate(d * 8, 20), 9,
          Paint()..color = const Color(0xFFFF8FAB).withOpacity(0.55));
    }
    canvas.drawArc(Rect.fromCenter(center: c.translate(0, 22), width: 14, height: 10), 0, pi, false, dark);

    // Hocico del cerdo
    if (animal == Animal.cerdo) {
      canvas.drawOval(Rect.fromCenter(center: c.translate(0, 14), width: 34, height: 22),
          Paint()..color = const Color(0xFFFF8FAB));
      for (final d in [-1, 1]) {
        canvas.drawCircle(c.translate(d * 6, 14), 2.5, dark..style = PaintingStyle.fill);
      }
      dark.style = PaintingStyle.stroke;
    }

    // Manitos juntas (meditación)
    canvas.drawCircle(c.translate(-14, r * 1.15), 12, fill);
    canvas.drawCircle(c.translate(14, r * 1.15), 12, fill);
  }

  @override
  bool shouldRepaint(_AnimalPainter o) => o.animal != animal;
}
