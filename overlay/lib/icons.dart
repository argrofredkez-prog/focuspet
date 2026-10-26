import 'dart:math';
import 'package:flutter/material.dart';

/// Plantilla de icono completo (relleno + contorno) que se usa para "reconocer" siluetas.
class IconTpl {
  final String name, kind, slot; // kind: acc | food
  final Path body;
  final Path? accent, line;
  final Color accentColor;
  final bool accentTop;
  IconTpl(this.name, this.kind, this.slot, this.body,
      {this.accent,
      this.accentColor = const Color(0xFFE8445A),
      this.line,
      this.accentTop = true});

  late final Path sil =
      accent == null ? body : Path.combine(PathOperation.union, body, accent!);
  late final Rect box = sil.getBounds();
  late final double aspect = box.width / box.height;
  // silueta muestreada en una rejilla de 32x32
  late final List<bool> mask = [
    for (int j = 0; j < 32; j++)
      for (int i = 0; i < 32; i++)
        sil.contains(Offset(box.left + (i + 0.5) / 32 * box.width,
            box.top + (j + 0.5) / 32 * box.height))
  ];
}

Path _poly(List<double> v) {
  final p = Path()..moveTo(v[0], v[1]);
  for (int i = 2; i < v.length; i += 2) {
    p.lineTo(v[i], v[i + 1]);
  }
  return p..close();
}

Path _oval(double cx, double cy, double rx, double ry) =>
    Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));

Path _rr(double l, double t, double r, double b, double rad) =>
    Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(rad)));

Path _u(List<Path> ps) =>
    ps.reduce((a, b) => Path.combine(PathOperation.union, a, b));

Path _star(double cx, double cy, double ro, double ri) {
  final p = Path();
  for (int i = 0; i < 10; i++) {
    final r = i.isEven ? ro : ri;
    final a = -pi / 2 + i * pi / 5;
    final x = cx + cos(a) * r, y = cy + sin(a) * r;
    if (i == 0) {
      p.moveTo(x, y);
    } else {
      p.lineTo(x, y);
    }
  }
  return p..close();
}

const _tan = Color(0xFFE0A458);
const _green = Color(0xFF4FA765);

final List<IconTpl> templates = [
  // ---------- complementos ----------
  IconTpl('Sombrero de copa', 'acc', 'head', _u([_rr(26, 10, 74, 78, 4), _rr(4, 74, 96, 90, 6)]),
      accent: _rr(26, 60, 74, 74, 0)),
  IconTpl('Gorro de lana', 'acc', 'head',
      _u([
        Path()
          ..moveTo(14, 72)
          ..cubicTo(14, 18, 86, 18, 86, 72)
          ..close(),
        _oval(50, 16, 9, 9)
      ]),
      accent: _rr(10, 66, 90, 90, 6),
      accentColor: const Color(0xFFF5F5F5),
      line: Path()
        ..moveTo(26, 68)..lineTo(26, 88)
        ..moveTo(42, 68)..lineTo(42, 88)
        ..moveTo(58, 68)..lineTo(58, 88)
        ..moveTo(74, 68)..lineTo(74, 88)),
  IconTpl('Corona', 'acc', 'head', _poly([10, 82, 10, 28, 32, 52, 50, 16, 68, 52, 90, 28, 90, 82]),
      accent: _u([_oval(10, 26, 5, 5), _oval(50, 12, 5, 5), _oval(90, 26, 5, 5)]),
      line: Path()
        ..moveTo(10, 68)
        ..lineTo(90, 68)),
  IconTpl('Lazo', 'acc', 'head',
      _u([_poly([50, 50, 6, 20, 6, 80]), _poly([50, 50, 94, 20, 94, 80]), _oval(50, 50, 11, 11)])),
  IconTpl('Gafas', 'acc', 'eyes', _u([_oval(27, 50, 22, 22), _oval(73, 50, 22, 22), _rr(44, 44, 56, 54, 2)]),
      line: Path()
        ..moveTo(14, 40)..quadraticBezierTo(18, 32, 27, 30)
        ..moveTo(60, 40)..quadraticBezierTo(64, 32, 73, 30)),
  IconTpl('Bufanda', 'acc', 'neck', _u([_rr(4, 22, 96, 52, 14), _rr(62, 46, 84, 94, 6)]),
      line: Path()
        ..moveTo(22, 24)..lineTo(22, 50)
        ..moveTo(40, 24)..lineTo(40, 50)
        ..moveTo(58, 24)..lineTo(58, 50)
        ..moveTo(70, 70)..lineTo(78, 70)),
  IconTpl('Flor', 'acc', 'head',
      _u([for (int i = 0; i < 5; i++) _oval(50 + cos(-pi / 2 + i * 2 * pi / 5) * 26, 50 + sin(-pi / 2 + i * 2 * pi / 5) * 26, 20, 20)]),
      accent: _oval(50, 50, 13, 13), accentColor: const Color(0xFFFFD43B)),
  IconTpl('Estrella', 'acc', 'head', _star(50, 52, 48, 20)),
  IconTpl('Corazón', 'acc', 'face',
      Path()
        ..moveTo(50, 92)
        ..cubicTo(-8, 48, 14, 6, 50, 32)
        ..cubicTo(86, 6, 108, 48, 50, 92)
        ..close()),
  IconTpl('Globo', 'acc', 'hand', _u([_oval(50, 36, 28, 34), _poly([50, 68, 43, 78, 57, 78])]),
      line: Path()
        ..moveTo(50, 78)..quadraticBezierTo(42, 88, 50, 98)),
  IconTpl('Alas', 'acc', 'back',
      Path()
        ..moveTo(50, 72)
        ..cubicTo(10, 62, 0, 25, 15, 8)
        ..cubicTo(30, 35, 45, 35, 50, 30)
        ..cubicTo(55, 35, 70, 35, 85, 8)
        ..cubicTo(100, 25, 90, 62, 50, 72)
        ..close(),
      line: Path()
        ..moveTo(50, 32)..lineTo(50, 68)),
  IconTpl('Capa', 'acc', 'back',
      Path()
        ..moveTo(28, 10)
        ..lineTo(72, 10)
        ..lineTo(96, 92)
        ..quadraticBezierTo(50, 78, 4, 92)
        ..close(),
      accent: _rr(26, 5, 74, 17, 5),
      accentColor: const Color(0xFFFFD43B),
      line: Path()
        ..moveTo(40, 18)..lineTo(30, 82)
        ..moveTo(60, 18)..lineTo(70, 82)),
  IconTpl('Bigote', 'acc', 'face',
      Path()
        ..moveTo(50, 45)
        ..cubicTo(40, 20, 10, 30, 5, 50)
        ..cubicTo(20, 48, 35, 58, 50, 55)
        ..cubicTo(65, 58, 80, 48, 95, 50)
        ..cubicTo(90, 30, 60, 20, 50, 45)
        ..close()),
  // ---------- comida ----------
  IconTpl('Manzana', 'food', '',
      Path()
        ..moveTo(50, 28)
        ..cubicTo(70, 10, 95, 30, 90, 60)
        ..cubicTo(85, 90, 65, 96, 50, 88)
        ..cubicTo(35, 96, 15, 90, 10, 60)
        ..cubicTo(5, 30, 30, 10, 50, 28)
        ..close(),
      accent: Path()
        ..moveTo(52, 22)
        ..cubicTo(55, 6, 72, 2, 80, 6)
        ..cubicTo(76, 18, 62, 24, 52, 22)
        ..close(),
      accentColor: _green,
      line: Path()
        ..moveTo(50, 28)..quadraticBezierTo(52, 16, 56, 8)),
  IconTpl('Fresa', 'food', '',
      Path()
        ..moveTo(50, 95)
        ..cubicTo(10, 70, 5, 35, 25, 25)
        ..cubicTo(40, 18, 60, 18, 75, 25)
        ..cubicTo(95, 35, 90, 70, 50, 95)
        ..close(),
      accent: _poly([30, 24, 40, 10, 50, 22, 60, 10, 70, 24, 50, 32]),
      accentColor: _green,
      line: Path()
        ..addOval(Rect.fromCenter(center: const Offset(38, 48), width: 3, height: 5))
        ..addOval(Rect.fromCenter(center: const Offset(60, 46), width: 3, height: 5))
        ..addOval(Rect.fromCenter(center: const Offset(50, 62), width: 3, height: 5))
        ..addOval(Rect.fromCenter(center: const Offset(36, 68), width: 3, height: 5))
        ..addOval(Rect.fromCenter(center: const Offset(64, 66), width: 3, height: 5))),
  IconTpl('Cupcake', 'food', '', _u([_oval(50, 48, 42, 18), _oval(50, 30, 26, 20)]),
      accent: _poly([20, 56, 80, 56, 72, 96, 28, 96]),
      accentColor: _tan,
      accentTop: false,
      line: Path()
        ..moveTo(36, 60)..lineTo(40, 92)
        ..moveTo(50, 60)..lineTo(50, 92)
        ..moveTo(64, 60)..lineTo(60, 92)),
  IconTpl('Helado', 'food', '', _u([_oval(50, 36, 26, 24), _rr(24, 44, 76, 56, 6)]),
      accent: _poly([26, 54, 74, 54, 50, 98]), accentColor: _tan, accentTop: false),
  IconTpl('Pescado', 'food', '', _u([_oval(40, 50, 32, 24), _poly([66, 50, 96, 24, 96, 76])]),
      accent: _oval(26, 44, 4.5, 4.5),
      accentColor: Colors.white,
      line: Path()
        ..moveTo(52, 34)..quadraticBezierTo(46, 50, 52, 66)),
  IconTpl('Pizza', 'food', '',
      Path()
        ..moveTo(50, 96)
        ..lineTo(6, 20)
        ..quadraticBezierTo(50, 0, 94, 20)
        ..close(),
      accent: Path()
        ..moveTo(6, 20)
        ..quadraticBezierTo(50, 0, 94, 20)
        ..lineTo(90, 30)
        ..quadraticBezierTo(50, 12, 10, 30)
        ..close(),
      accentColor: _tan,
      line: Path()
        ..addOval(Rect.fromCenter(center: const Offset(50, 46), width: 12, height: 12))
        ..addOval(Rect.fromCenter(center: const Offset(36, 32), width: 10, height: 10))
        ..addOval(Rect.fromCenter(center: const Offset(62, 32), width: 10, height: 10))
        ..addOval(Rect.fromCenter(center: const Offset(50, 70), width: 10, height: 10))),
  IconTpl('Zanahoria', 'food', '',
      Path()
        ..moveTo(50, 96)
        ..lineTo(28, 32)
        ..quadraticBezierTo(50, 20, 72, 32)
        ..close(),
      accent: _u([_poly([50, 28, 36, 6, 46, 4, 54, 22]), _poly([50, 28, 64, 6, 54, 4, 46, 22])]),
      accentColor: _green,
      line: Path()
        ..moveTo(40, 50)..lineTo(48, 50)
        ..moveTo(52, 66)..lineTo(60, 66)
        ..moveTo(44, 78)..lineTo(50, 78)),
  IconTpl('Piruleta', 'food', '', _oval(50, 34, 30, 30),
      accent: _rr(47, 60, 53, 98, 2),
      accentColor: const Color(0xFFD9D9E3),
      accentTop: false,
      line: Path()
        ..addArc(Rect.fromCenter(center: const Offset(50, 34), width: 40, height: 40), 0, 4.5)
        ..addArc(Rect.fromCenter(center: const Offset(50, 34), width: 18, height: 18), 1, 4.5)),
];

/// Dibuja la plantilla rellena, con degradado, brillo y contorno.
void paintTpl(Canvas c, Size s, IconTpl t, Color main) {
  final b = t.box;
  final k = min(s.width / b.width, s.height / b.height) * 0.9;
  c.save();
  c.translate(s.width / 2, s.height / 2);
  c.scale(k);
  c.translate(-b.center.dx, -b.center.dy);

  Paint stroke(Color col, double w) => Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  final dark = Color.lerp(main, Colors.black, 0.4)!;
  final light = Color.lerp(main, Colors.white, 0.4)!;

  void accent() {
    final a = t.accent;
    if (a == null) return;
    c.drawPath(a, Paint()..color = t.accentColor);
    c.drawPath(a, stroke(Color.lerp(t.accentColor, Colors.black, 0.4)!, 2.4));
  }

  if (!t.accentTop) accent();
  final bb = t.body.getBounds();
  c.drawPath(
      t.body,
      Paint()
        ..shader = LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, main])
            .createShader(bb));
  c.save();
  c.clipPath(t.body);
  c.drawOval(
      Rect.fromLTWH(bb.left + bb.width * 0.1, bb.top + bb.height * 0.08, bb.width * 0.35, bb.height * 0.18),
      Paint()..color = const Color(0x55FFFFFF));
  c.restore();
  c.drawPath(t.body, stroke(dark, 2.8));
  if (t.accentTop) accent();
  final l = t.line;
  if (l != null) c.drawPath(l, stroke(dark, 2));
  c.restore();
}

/// Plantillas más parecidas a la silueta (rejilla 32x32 y proporción).
List<IconTpl> bestMatches(List<bool> user, double aspect, {int n = 4}) {
  final scored = <MapEntry<IconTpl, double>>[];
  for (final t in templates) {
    int inter = 0, uni = 0;
    final m = t.mask;
    for (int i = 0; i < 1024; i++) {
      if (user[i] && m[i]) inter++;
      if (user[i] || m[i]) uni++;
    }
    final iou = uni == 0 ? 0.0 : inter / uni;
    scored.add(MapEntry(t, iou - 0.15 * log(aspect / t.aspect).abs()));
  }
  scored.sort((a, b) => b.value.compareTo(a.value));
  return [for (final e in scored.take(n)) e.key];
}
