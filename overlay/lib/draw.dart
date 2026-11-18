import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'data.dart';

// ---------- plantillas: objetos en una cuadrícula de 100x100 (se dibujan a 512 px) ----------
Color _dk(Color c) => Color.lerp(c, Colors.black, 0.33)!;
Color _lt(Color c) => Color.lerp(c, Colors.white, 0.42)!;

// detalle que se pinta sobre el objeto (letra, estrellas, rayas…)
class _Deco {
  final String? letter, kind;
  final Color col;
  final bool big;
  const _Deco({this.letter, this.kind, required this.col, this.big = false});
}

_Deco? _deco;

void _sh(Canvas c, Path p, Color col, bool solid) {
  if (solid) {
    c.drawPath(p, Paint()..color = Colors.black);
    return;
  }
  final r = p.getBounds();
  c.drawPath(
      p,
      Paint()
        ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight,
            [Color.lerp(col, Colors.white, .38)!, col, Color.lerp(col, Colors.black, .28)!], [0.0, .5, 1.0]));
  c.save();
  c.clipPath(p);
  c.drawRect(Rect.fromLTWH(r.left, r.bottom - r.height * .2, r.width, r.height * .3), Paint()..color = const Color(0x16000000));
  c.drawOval(Rect.fromLTWH(r.left + r.width * .08, r.top + r.height * .05, r.width * .5, r.height * .2),
      Paint()..color = const Color(0x30FFFFFF));
  c.restore();
  c.drawPath(
      p,
      Paint()
        ..color = _dk(col)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round);
}

void _stroke(Canvas c, Path p, Color col, double w) => c.drawPath(
    p,
    Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round);

Path _rrp(double x, double y, double w, double h, double r) =>
    Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)));

void _rr(Canvas c, double x, double y, double w, double h, double r, Color col, bool s) =>
    _sh(c, _rrp(x, y, w, h, r), col, s);

void _ci(Canvas c, double x, double y, double r, Color col, bool s) =>
    _sh(c, Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r)), col, s);

Path _poly(List<double> v) {
  final p = Path()..moveTo(v[0], v[1]);
  for (int i = 2; i < v.length; i += 2) {
    p.lineTo(v[i], v[i + 1]);
  }
  return p..close();
}

Path _star(double cx, double cy, double ro, double ri) {
  final p = Path();
  for (int i = 0; i < 10; i++) {
    final r = i.isEven ? ro : ri;
    final a = -pi / 2 + i * pi / 5;
    final o = Offset(cx + r * cos(a), cy + r * sin(a));
    i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

Path _heartPath(double cx, double cy, double r) => Path()
  ..moveTo(cx, cy + r * .9)
  ..cubicTo(cx - r * 1.6, cy - r * .2, cx - r * .7, cy - r * 1.2, cx, cy - r * .4)
  ..cubicTo(cx + r * .7, cy - r * 1.2, cx + r * 1.6, cy - r * .2, cx, cy + r * .9)
  ..close();

void _line(Canvas c, double x1, double y1, double x2, double y2, Color col, double w) => c.drawLine(
    Offset(x1, y1),
    Offset(x2, y2),
    Paint()
      ..color = col
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round);

void _text(Canvas c, String t, Offset ctr, double fs, Color col) {
  for (final pass in [0, 1]) {
    final tp = TextPainter(
        text: TextSpan(
            text: t,
            style: TextStyle(
                fontSize: fs,
                fontWeight: FontWeight.w900,
                foreground: pass == 0
                    ? (Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = fs * .16
                      ..strokeJoin = StrokeJoin.round
                      ..color = _dk(col))
                    : (Paint()..color = col))),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, ctr - Offset(tp.width / 2, tp.height / 2));
  }
}

// pinta el detalle elegido dentro de la silueta `clip`
void _dec(Canvas c, Path clip, Offset ctr, double sz) {
  final d = _deco;
  if (d == null) return;
  final col = d.col, edge = _dk(d.col);
  final b = clip.getBounds();
  c.save();
  c.clipPath(clip);
  void fill(Path p) {
    c.drawPath(p, Paint()..color = col);
    c.drawPath(
        p,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..strokeJoin = StrokeJoin.round);
  }

  void flower(Offset o, double r) {
    for (int k = 0; k < 5; k++) {
      c.drawCircle(o + Offset(r * .62 * cos(k * 1.2566), r * .62 * sin(k * 1.2566)), r * .42, Paint()..color = col);
    }
    c.drawCircle(o, r * .32, Paint()..color = const Color(0xFFFFD84D));
  }

  final k = d.kind;
  if (k == 'stripes') {
    for (double y = b.top + 3; y < b.bottom; y += 11) {
      c.drawRect(Rect.fromLTWH(b.left - 2, y, b.width + 4, 5), Paint()..color = col);
    }
  } else if (k == 'dots') {
    int r = 0;
    for (double y = b.top + 6; y < b.bottom; y += 11) {
      for (double x = b.left + (r.isEven ? 6 : 11.5); x < b.right; x += 11) {
        c.drawCircle(Offset(x, y), 2.8, Paint()..color = col);
      }
      r++;
    }
  } else if (k == 'checks') {
    for (int i = 0; i < 14; i++) {
      for (int j = 0; j < 14; j++) {
        if ((i + j).isEven) c.drawRect(Rect.fromLTWH(b.left + i * 8, b.top + j * 8, 8, 8), Paint()..color = col.withAlpha(235));
      }
    }
  } else if (k == 'star') {
    if (d.big) {
      fill(_star(ctr.dx, ctr.dy, sz * .66, sz * .29));
    } else {
      for (final o in [Offset(-sz * .5, sz * .18), Offset(0, -sz * .22), Offset(sz * .5, sz * .18)]) {
        fill(_star(ctr.dx + o.dx, ctr.dy + o.dy, sz * .3, sz * .13));
      }
    }
  } else if (k == 'heart') {
    if (d.big) {
      fill(_heartPath(ctr.dx, ctr.dy, sz * .6));
    } else {
      for (final o in [Offset(-sz * .5, sz * .15), Offset(0, -sz * .2), Offset(sz * .5, sz * .15)]) {
        fill(_heartPath(ctr.dx + o.dx, ctr.dy + o.dy, sz * .27));
      }
    }
  } else if (k == 'flower') {
    if (d.big) {
      flower(ctr, sz * .7);
    } else {
      for (final o in [Offset(-sz * .5, sz * .18), Offset(0, -sz * .22), Offset(sz * .5, sz * .18)]) {
        flower(ctr + o, sz * .36);
      }
    }
  } else if (k == 'rainbow') {
    const rb = [Color(0xFFFF6B8B), Color(0xFFFFB04C), Color(0xFFFFE066), Color(0xFF7DDFA8), Color(0xFF7ED6FF), Color(0xFFB59CFF)];
    for (int i = 0; i < rb.length; i++) {
      c.drawArc(Rect.fromCircle(center: ctr + Offset(0, sz * .4), radius: sz * (.75 - i * .1)), pi, pi, false,
          Paint()
            ..color = rb[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = sz * .11);
    }
  } else if (k == 'moon') {
    fill(Path.combine(
        ui.PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: ctr, radius: sz * .55)),
        Path()..addOval(Rect.fromCircle(center: ctr + Offset(sz * .25, -sz * .1), radius: sz * .45))));
  } else if (k == 'bolt') {
    const pts = [.15, -.65, -.35, .08, -.02, .08, -.15, .65, .38, -.12, .05, -.12];
    final bp = Path();
    for (int i = 0; i < pts.length; i += 2) {
      final o = Offset(ctr.dx + pts[i] * sz * 1.2, ctr.dy + pts[i + 1] * sz * 1.2);
      i == 0 ? bp.moveTo(o.dx, o.dy) : bp.lineTo(o.dx, o.dy);
    }
    fill(bp..close());
  } else if (k == 'paw') {
    c.drawOval(Rect.fromCenter(center: ctr + Offset(0, sz * .18), width: sz * .8, height: sz * .6), Paint()..color = col);
    for (final o in const [Offset(-.42, -.14), Offset(-.15, -.4), Offset(.15, -.4), Offset(.42, -.14)]) {
      c.drawCircle(ctr + o * sz, sz * .15, Paint()..color = col);
    }
  }
  if (d.letter != null) _text(c, d.letter!, ctr, sz * (d.big ? 1.7 : 1.0), col);
  c.restore();
}

class _Tpl {
  final String id, name, kind, slot;
  final void Function(Canvas c, Color b, bool s) draw;
  const _Tpl(this.id, this.name, this.kind, this.slot, this.draw);
}

void _beanie(Canvas c, Color b, bool s) {
  final bp = Path()
    ..moveTo(14, 66)
    ..cubicTo(10, 8, 90, 8, 86, 66)
    ..close();
  _sh(c, bp, b, s);
  if (!s) {
    for (final x in [28.0, 38.0, 50.0, 62.0, 72.0]) {
      _line(c, x, 22 + (x - 50).abs() * .5, x + (x - 50) * .1, 62, _dk(b).withAlpha(70), 1.6);
    }
    _dec(c, bp, const Offset(50, 42), 24);
  }
  _rr(c, 8, 60, 84, 26, 9, _lt(b), s);
  if (!s) {
    for (double x = 16; x < 92; x += 8) {
      _line(c, x, 63, x, 83, _dk(b).withAlpha(60), 1.6);
    }
  }
  _ci(c, 50, 10, 11, _lt(b), s);
}

void _cap(Canvas c, Color b, bool s) {
  final dome = Path()
    ..moveTo(14, 62)
    ..cubicTo(12, 4, 88, 4, 86, 62)
    ..close();
  _sh(c, dome, b, s);
  if (!s) {
    _line(c, 50, 10, 50, 60, _dk(b).withAlpha(80), 1.8);
    _line(c, 31, 16, 27, 58, _dk(b).withAlpha(60), 1.6);
    _line(c, 69, 16, 73, 58, _dk(b).withAlpha(60), 1.6);
    _dec(c, dome, const Offset(50, 36), 28);
  }
  _ci(c, 50, 8, 4.5, _dk(b), s);
  _sh(
      c,
      Path()
        ..moveTo(8, 62)
        ..quadraticBezierTo(50, 98, 92, 62)
        ..quadraticBezierTo(50, 52, 8, 62)
        ..close(),
      _dk(b),
      s);
}

void _topHat(Canvas c, Color b, bool s) {
  _rr(c, 6, 62, 88, 16, 8, b, s);
  final bp = _rrp(28, 10, 44, 56, 6);
  _sh(c, bp, b, s);
  if (!s) {
    _rr(c, 28, 50, 44, 10, 2, _dk(b), false);
    _dec(c, bp, const Offset(50, 32), 22);
  }
}

void _wizard(Canvas c, Color b, bool s) {
  _sh(c, Path()..addOval(const Rect.fromLTWH(6, 66, 88, 24)), _dk(b), s);
  final cone = Path()
    ..moveTo(20, 80)
    ..quadraticBezierTo(44, 44, 56, 4)
    ..quadraticBezierTo(64, 44, 80, 80)
    ..quadraticBezierTo(50, 90, 20, 80)
    ..close();
  _sh(c, cone, b, s);
  if (!s) {
    _stroke(c, Path()..moveTo(23, 72)..quadraticBezierTo(50, 82, 77, 72), const Color(0xFFFFD84D), 5);
    _dec(c, cone, const Offset(50, 48), 20);
  }
}

void _crown(Canvas c, Color b, bool s) {
  final bp = _poly([10, 78, 10, 28, 30, 50, 50, 20, 70, 50, 90, 28, 90, 78]);
  _sh(c, bp, b, s);
  if (!s) {
    _dec(c, bp, const Offset(50, 56), 18);
    _rr(c, 10, 66, 80, 12, 3, _lt(b), false);
    for (final x in [30.0, 50.0, 70.0]) {
      _ci(c, x, 72, 4, const Color(0xFFE8445A), false);
    }
    for (final o in const [Offset(10, 28), Offset(50, 20), Offset(90, 28)]) {
      _ci(c, o.dx, o.dy, 4.5, _lt(b), false);
    }
  }
}

void _headband(Canvas c, Color b, bool s) {
  final bp = Path()
    ..moveTo(6, 74)
    ..quadraticBezierTo(50, -6, 94, 74)
    ..lineTo(85, 74)
    ..quadraticBezierTo(50, 14, 15, 74)
    ..close();
  _sh(c, bp, b, s);
  if (!s) {
    _dec(c, bp, const Offset(50, 16), 9);
    _ci(c, 50, 12, 7, _lt(b), false);
  }
}

void _shirt(Canvas c, Color b, bool s) {
  final bp = _poly([30, 10, 8, 30, 20, 46, 32, 38, 32, 90, 68, 90, 68, 38, 80, 46, 92, 30, 70, 10, 50, 22]);
  _sh(c, bp, b, s);
  if (!s) {
    _dec(c, bp, const Offset(50, 60), 30);
    _stroke(c, Path()..moveTo(32, 10)..quadraticBezierTo(50, 34, 68, 10), _dk(b), 3.2);
    _line(c, 10, 33, 22, 49, _dk(b).withAlpha(120), 2);
    _line(c, 90, 33, 78, 49, _dk(b).withAlpha(120), 2);
  }
}

void _hoodie(Canvas c, Color b, bool s) {
  final bp = _poly([30, 14, 6, 40, 14, 66, 28, 60, 30, 92, 70, 92, 72, 60, 86, 66, 94, 40, 70, 14, 50, 26]);
  _sh(c, bp, b, s);
  if (!s) {
    _dec(c, bp, const Offset(50, 52), 22);
    _stroke(c, Path()..moveTo(30, 14)..quadraticBezierTo(50, 42, 70, 14), _dk(b), 4.4);
    _rr(c, 36, 68, 28, 16, 5, _lt(b), false);
    _line(c, 44, 30, 43, 48, Colors.white, 2);
    _line(c, 56, 30, 57, 48, Colors.white, 2);
  }
}

void _dress(Canvas c, Color b, bool s) {
  final bp = Path()
    ..moveTo(34, 8)
    ..lineTo(66, 8)
    ..lineTo(62, 38)
    ..quadraticBezierTo(80, 62, 88, 92)
    ..quadraticBezierTo(50, 100, 12, 92)
    ..quadraticBezierTo(20, 62, 38, 38)
    ..close();
  _sh(c, bp, b, s);
  if (!s) {
    _dec(c, bp, const Offset(50, 68), 26);
    _rr(c, 36, 36, 28, 7, 3, _dk(b), false);
    _stroke(c, Path()..moveTo(38, 8)..quadraticBezierTo(50, 24, 62, 8), _lt(b), 3);
    for (int i = 0; i < 6; i++) {
      c.drawArc(Rect.fromLTWH(12 + i * 12.6, 88, 12.6, 9), 0, pi, false,
          Paint()
            ..color = _dk(b).withAlpha(150)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
  }
}

void _glasses(Canvas c, Color b, bool s) {
  if (s) {
    _ci(c, 27, 50, 22, Colors.black, true);
    _ci(c, 73, 50, 22, Colors.black, true);
    _rr(c, 40, 44, 20, 8, 3, Colors.black, true);
    return;
  }
  for (final x in [27.0, 73.0]) {
    c.drawCircle(Offset(x, 50), 20, Paint()..color = const Color(0x55BFE6FF));
    c.drawCircle(
        Offset(x, 50),
        20,
        Paint()
          ..color = b
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
    c.drawArc(Rect.fromCircle(center: Offset(x, 50), radius: 14), 3.6, 1.2, false,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round);
  }
  _line(c, 46, 46, 54, 46, b, 5);
  _line(c, 7, 46, 1, 40, b, 4);
  _line(c, 93, 46, 99, 40, b, 4);
}

void _bow(Canvas c, Color b, bool s) {
  _sh(c, _poly([50, 50, 10, 24, 10, 76]), b, s);
  _sh(c, _poly([50, 50, 90, 24, 90, 76]), b, s);
  _rr(c, 40, 38, 20, 24, 6, _lt(b), s);
}

void _scarf(Canvas c, Color b, bool s) {
  final bp = _rrp(4, 26, 92, 28, 12);
  _sh(c, bp, b, s);
  _rr(c, 58, 46, 24, 50, 8, b, s);
  if (!s) {
    for (final x in [20.0, 38.0, 56.0, 74.0]) {
      _line(c, x, 28, x, 52, _lt(b), 4);
    }
    _line(c, 60, 78, 80, 78, _lt(b), 4);
    _dec(c, bp, const Offset(30, 40), 16);
  }
}

void _necklace(Canvas c, Color b, bool s) {
  final ch = Path()
    ..moveTo(12, 16)
    ..quadraticBezierTo(50, 92, 88, 16);
  if (s) {
    _stroke(c, ch, Colors.black, 6);
  } else {
    _stroke(c, ch, _dk(b), 5);
    _stroke(c, ch, b, 3);
  }
  _sh(c, _heartPath(50, 66, 12), _lt(b), s);
}

void _cape(Canvas c, Color b, bool s) {
  final bp = Path()
    ..moveTo(30, 6)
    ..quadraticBezierTo(50, 0, 70, 6)
    ..lineTo(96, 94)
    ..quadraticBezierTo(50, 80, 4, 94)
    ..close();
  _sh(c, bp, b, s);
  if (!s) {
    _dec(c, bp, const Offset(50, 56), 24);
    _ci(c, 50, 10, 5, _lt(b), false);
  }
}

void _wing(Canvas c, Color b, bool s) {
  _sh(
      c,
      Path()
        ..moveTo(46, 70)
        ..cubicTo(34, 34, 8, 18, 4, 40)
        ..cubicTo(2, 56, 10, 64, 16, 66)
        ..cubicTo(14, 74, 22, 80, 30, 78)
        ..cubicTo(34, 84, 42, 82, 46, 76)
        ..close(),
      b,
      s);
}

void _wings(Canvas c, Color b, bool s) {
  _wing(c, b, s);
  c.save();
  c.translate(100, 0);
  c.scale(-1, 1);
  _wing(c, b, s);
  c.restore();
}

void _pack(Canvas c, Color b, bool s) {
  final bp = _rrp(20, 12, 60, 78, 22);
  _sh(c, bp, b, s);
  _rr(c, 30, 54, 40, 28, 10, _lt(b), s);
  if (!s) {
    _line(c, 34, 36, 66, 36, _dk(b), 3);
    _dec(c, bp, const Offset(50, 30), 16);
  }
}

void _wand(Canvas c, Color b, bool s) {
  _sh(c, _poly([16, 86, 22, 94, 72, 44, 66, 38]), b, s);
  _sh(c, _star(76, 24, 20, 9), s ? Colors.black : const Color(0xFFFFD43B), s);
}

void _bootShape(Canvas c, Color b, bool s, double x) {
  final bp = Path()
    ..moveTo(x - 9, 14)
    ..lineTo(x + 9, 14)
    ..lineTo(x + 9, 54)
    ..quadraticBezierTo(x + 31, 58, x + 31, 78)
    ..lineTo(x + 31, 90)
    ..lineTo(x - 11, 90)
    ..lineTo(x - 11, 72)
    ..close();
  _sh(c, bp, b, s);
  if (!s) {
    _dec(c, bp, Offset(x, 40), 12);
    _rr(c, x - 11, 10, 22, 9, 3, _lt(b), false);
    _rr(c, x - 11, 84, 43, 8, 3, _dk(b), false);
    for (final y in [28.0, 38.0, 48.0]) {
      _line(c, x - 4, y, x + 4, y, Colors.white70, 1.6);
    }
  }
}

void _boots(Canvas c, Color b, bool s) {
  _bootShape(c, b, s, 20);
  final dd = _deco;
  _deco = null;
  c.save();
  c.translate(100, 0);
  c.scale(-1, 1);
  _bootShape(c, b, s, 20);
  c.restore();
  _deco = dd;
}

void _sneakShape(Canvas c, Color b, bool s, double x) {
  final bp = Path()
    ..moveTo(x - 10, 40)
    ..lineTo(x + 8, 40)
    ..lineTo(x + 10, 58)
    ..quadraticBezierTo(x + 34, 60, x + 34, 78)
    ..lineTo(x + 34, 90)
    ..lineTo(x - 10, 90)
    ..close();
  _sh(c, bp, b, s);
  if (!s) {
    _dec(c, bp, Offset(x + 6, 66), 11);
    _rr(c, x - 10, 82, 44, 9, 3, Colors.white, false);
    for (final y in [47.0, 53.0, 59.0]) {
      _line(c, x - 3, y, x + 7, y + 1.5, Colors.white, 1.8);
    }
  }
}

void _sneakers(Canvas c, Color b, bool s) {
  _sneakShape(c, b, s, 16);
  final dd = _deco;
  _deco = null;
  c.save();
  c.translate(100, 0);
  c.scale(-1, 1);
  _sneakShape(c, b, s, 16);
  c.restore();
  _deco = dd;
}

const _tpls = <_Tpl>[
  _Tpl('beanie', 'Gorro', 'acc', 'head', _beanie),
  _Tpl('cap', 'Gorra', 'acc', 'head', _cap),
  _Tpl('tophat', 'Sombrero', 'acc', 'head', _topHat),
  _Tpl('wizard', 'Sombrero de mago', 'acc', 'head', _wizard),
  _Tpl('crown', 'Corona', 'acc', 'head', _crown),
  _Tpl('headband', 'Diadema', 'acc', 'head', _headband),
  _Tpl('shirt', 'Camiseta', 'acc', 'body', _shirt),
  _Tpl('hoodie', 'Sudadera', 'acc', 'body', _hoodie),
  _Tpl('dress', 'Vestido', 'acc', 'body', _dress),
  _Tpl('glasses', 'Gafas', 'acc', 'eyes', _glasses),
  _Tpl('bow', 'Pajarita', 'acc', 'neck', _bow),
  _Tpl('scarf', 'Bufanda', 'acc', 'neck', _scarf),
  _Tpl('necklace', 'Collar', 'acc', 'neck', _necklace),
  _Tpl('cape', 'Capa', 'acc', 'back', _cape),
  _Tpl('wings', 'Alas', 'acc', 'back', _wings),
  _Tpl('pack', 'Mochila', 'acc', 'back', _pack),
  _Tpl('wand', 'Varita', 'acc', 'hand', _wand),
  _Tpl('boots', 'Botas', 'acc', 'feet', _boots),
  _Tpl('sneakers', 'Zapatillas', 'acc', 'feet', _sneakers),
];

// ---------- descripción escrita → objeto, color y detalle ----------
String _norm(String s) => s
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u');

const _colorWords = <String, int>{
  'azul marino': 0xFF1F3A7A, 'azul oscuro': 0xFF1F3A7A, 'azul claro': 0xFF8ED8FF, 'celeste': 0xFF8ED8FF,
  'azul': 0xFF3F7FE0, 'turquesa': 0xFF2FC5C0, 'cian': 0xFF22D3EE,
  'verde lima': 0xFFA6E34F, 'lima': 0xFFA6E34F, 'verde oscuro': 0xFF1F7A4A, 'verde claro': 0xFF8FE3A0,
  'menta': 0xFF9FF0CE, 'verde': 0xFF4FB06A,
  'rojo': 0xFFE8445A, 'roja': 0xFFE8445A, 'burdeos': 0xFF8C1F3A, 'granate': 0xFF8C1F3A, 'coral': 0xFFFF7F6E,
  'salmon': 0xFFFFA58F,
  'rosa fuerte': 0xFFFF4F9A, 'fucsia': 0xFFFF2E93, 'rosa claro': 0xFFFFC2DC, 'rosa pastel': 0xFFFFC2DC,
  'rosa': 0xFFFF8FB8,
  'morado': 0xFF8E5BD9, 'morada': 0xFF8E5BD9, 'violeta': 0xFF8E5BD9, 'purpura': 0xFF8E5BD9, 'lila': 0xFFC9B3F5,
  'lavanda': 0xFFC9B3F5,
  'amarillo': 0xFFFFD84D, 'amarilla': 0xFFFFD84D, 'naranja': 0xFFFF8A3D, 'mostaza': 0xFFD9A81E,
  'marron': 0xFF8B5A3C, 'cafe': 0xFF8B5A3C, 'beige': 0xFFEAD7B7, 'crema': 0xFFFFF1D6,
  'negro': 0xFF2B2B3A, 'negra': 0xFF2B2B3A, 'blanco': 0xFFFFFFFF, 'blanca': 0xFFFFFFFF,
  'gris oscuro': 0xFF5A6272, 'gris': 0xFF9AA3B2, 'plata': 0xFFC8D0DC, 'plateado': 0xFFC8D0DC,
  'plateada': 0xFFC8D0DC, 'dorado': 0xFFF2B134, 'dorada': 0xFFF2B134, 'oro': 0xFFF2B134,
};

const _objWords = <List<String>>[
  ['gorro de mago', 'wizard'], ['sombrero de mago', 'wizard'], ['mago', 'wizard'], ['bruja', 'wizard'],
  ['gorra', 'cap'], ['visera', 'cap'], ['beisbol', 'cap'],
  ['gorro', 'beanie'], ['pompon', 'beanie'], ['lana', 'beanie'],
  ['sombrero', 'tophat'], ['chistera', 'tophat'],
  ['corona', 'crown'], ['tiara', 'crown'],
  ['diadema', 'headband'], ['cinta', 'headband'],
  ['sudadera', 'hoodie'], ['capucha', 'hoodie'],
  ['camiseta', 'shirt'], ['camisa', 'shirt'], ['playera', 'shirt'], ['jersey', 'shirt'],
  ['vestido', 'dress'], ['falda', 'dress'],
  ['gafas', 'glasses'], ['lentes', 'glasses'],
  ['pajarita', 'bow'], ['lazo', 'bow'], ['corbata', 'bow'],
  ['bufanda', 'scarf'], ['collar', 'necklace'], ['colgante', 'necklace'],
  ['capa', 'cape'], ['alas', 'wings'], ['mochila', 'pack'], ['varita', 'wand'],
  ['botas', 'boots'], ['botines', 'boots'],
  ['zapatillas', 'sneakers'], ['deportivas', 'sneakers'], ['zapatos', 'sneakers'],
];

const _kindWords = <List<String>>[
  ['estrella', 'star'], ['corazon', 'heart'], ['raya', 'stripes'], ['lunar', 'dots'], ['punto', 'dots'],
  ['flor', 'flower'], ['arcoiris', 'rainbow'], ['arco iris', 'rainbow'], ['cuadro', 'checks'],
  ['cuadrad', 'checks'], ['luna', 'moon'], ['rayo', 'bolt'], ['huella', 'paw'], ['pata', 'paw'],
];

class _Parsed {
  String? tpl, letter, kind;
  Color? color, color2;
  bool big = false;
}

Color? _findColor(String t) {
  final keys = _colorWords.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  int bestPos = 1 << 30;
  Color? best;
  for (final k in keys) {
    final m = RegExp('(^|[^a-z])$k(?![a-z])').firstMatch(t);
    if (m != null && m.start < bestPos) {
      bestPos = m.start;
      best = Color(_colorWords[k]!);
    }
  }
  return best;
}

_Parsed _parse(String raw) {
  final r = _Parsed();
  final t = _norm(raw);
  if (t.trim().isEmpty) return r;
  final sp = RegExp(r'\s(con|y|que|lleva|llevando|tiene|ademas)\s').firstMatch(t);
  final main = sp == null ? t : t.substring(0, sp.start);
  final detail = sp == null ? t : t.substring(sp.start);
  int bestPos = 1 << 30;
  for (final w in _objWords) {
    final m = RegExp('(^|[^a-z])${w[0]}').firstMatch(t);
    if (m != null && m.start < bestPos) {
      bestPos = m.start;
      r.tpl = w[1];
    }
  }
  r.color = _findColor(main);
  r.color2 = sp == null ? null : _findColor(detail);
  final lm = RegExp(r'(?:letra|inicial)\s+(?:(?:una|la|el|de)\s+)?"?([a-z0-9n])"?\b').firstMatch(detail);
  if (lm != null) r.letter = lm.group(1)!.toUpperCase();
  final nm = RegExp(r'numero\s+(\d{1,2})').firstMatch(detail);
  if (nm != null) r.letter = nm.group(1);
  for (final w in _kindWords) {
    if (detail.contains(w[0])) {
      r.kind = w[1];
      break;
    }
  }
  r.big = RegExp(r'gigante|enorme|grande|xl|muy grande').hasMatch(detail);
  return r;
}

// ---------- reconocimiento del boceto ----------
const int _G = 24; // cuadrícula de comparación
const int _N = 128; // resolución de las máscaras

class _Stroke {
  final double width;
  final List<Offset> pts = [];
  _Stroke(this.width);
}

Path _smooth(List<Offset> p) {
  final path = Path()..moveTo(p.first.dx, p.first.dy);
  if (p.length < 3) {
    for (final q in p.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    return path;
  }
  for (int i = 1; i < p.length - 1; i++) {
    final m = (p[i] + p[i + 1]) / 2;
    path.quadraticBezierTo(p[i].dx, p[i].dy, m.dx, m.dy);
  }
  return path..lineTo(p.last.dx, p.last.dy);
}

void _ink(Canvas c, List<_Stroke> ss, Color col, {double extra = 0}) {
  for (final s in ss) {
    if (s.pts.length == 1) {
      c.drawCircle(s.pts.first, (s.width + extra) / 2, Paint()..color = col);
    } else {
      c.drawPath(
          _smooth(s.pts),
          Paint()
            ..color = col
            ..strokeWidth = s.width + extra
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke);
    }
  }
}

Future<List<bool>> _alpha(int n, void Function(Canvas) f) async {
  final rec = ui.PictureRecorder();
  f(Canvas(rec));
  final img = await rec.endRecording().toImage(n, n);
  final d = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  return [for (int i = 3; i < d.length; i += 4) d[i] > 60];
}

// cierra huecos del trazo y rellena el interior
List<bool> _closeFill(List<bool> m, int n, int r) {
  final dil = List<bool>.filled(n * n, false);
  for (int y = 0; y < n; y++) {
    for (int x = 0; x < n; x++) {
      if (!m[y * n + x]) continue;
      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          final yy = y + dy, xx = x + dx;
          if (dx * dx + dy * dy <= r * r && yy >= 0 && yy < n && xx >= 0 && xx < n) dil[yy * n + xx] = true;
        }
      }
    }
  }
  final out = List<bool>.filled(n * n, false);
  final q = <int>[];
  for (int i = 0; i < n; i++) {
    for (final j in [i, (n - 1) * n + i, i * n, i * n + n - 1]) {
      if (!dil[j] && !out[j]) {
        out[j] = true;
        q.add(j);
      }
    }
  }
  while (q.isNotEmpty) {
    final j = q.removeLast();
    final x = j % n, y = j ~/ n;
    for (final o in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      final xx = x + o[0], yy = y + o[1];
      if (xx < 0 || yy < 0 || xx >= n || yy >= n) continue;
      final k = yy * n + xx;
      if (!dil[k] && !out[k]) {
        out[k] = true;
        q.add(k);
      }
    }
  }
  return [for (int i = 0; i < n * n; i++) !out[i]];
}

// recorta al rectángulo del dibujo y lo pasa a _G x _G
List<int>? _grid(List<bool> m, int n) {
  int x0 = n, y0 = n, x1 = -1, y1 = -1;
  for (int y = 0; y < n; y++) {
    for (int x = 0; x < n; x++) {
      if (m[y * n + x]) {
        x0 = min(x0, x);
        y0 = min(y0, y);
        x1 = max(x1, x);
        y1 = max(y1, y);
      }
    }
  }
  if (x1 < 0) return null;
  final bw = x1 - x0 + 1, bh = y1 - y0 + 1;
  final g = List<int>.filled(_G * _G, 0);
  for (int gy = 0; gy < _G; gy++) {
    for (int gx = 0; gx < _G; gx++) {
      final sx0 = x0 + gx * bw ~/ _G, sx1 = max(sx0 + 1, x0 + (gx + 1) * bw ~/ _G);
      final sy0 = y0 + gy * bh ~/ _G, sy1 = max(sy0 + 1, y0 + (gy + 1) * bh ~/ _G);
      int on = 0, tot = 0;
      for (int y = sy0; y < sy1 && y < n; y++) {
        for (int x = sx0; x < sx1 && x < n; x++) {
          tot++;
          if (m[y * n + x]) on++;
        }
      }
      g[gy * _G + gx] = (tot > 0 && on / tot > 0.3) ? 1 : 0;
    }
  }
  return [...g, bw, bh];
}

List<int> _dil1(List<int> a) {
  final r = List<int>.filled(_G * _G, 0);
  for (int y = 0; y < _G; y++) {
    for (int x = 0; x < _G; x++) {
      if (a[y * _G + x] == 0) continue;
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final yy = y + dy, xx = x + dx;
          if (yy >= 0 && yy < _G && xx >= 0 && xx < _G) r[yy * _G + xx] = 1;
        }
      }
    }
  }
  return r;
}

double _overlap(List<int> a, List<int> b) {
  final da = _dil1(a), db = _dil1(b);
  int sa = 0, sb = 0, ia = 0, ib = 0;
  for (int i = 0; i < _G * _G; i++) {
    if (a[i] == 1) {
      sa++;
      if (db[i] == 1) ia++;
    }
    if (b[i] == 1) {
      sb++;
      if (da[i] == 1) ib++;
    }
  }
  return (sa == 0 || sb == 0) ? 0 : (ia / sa + ib / sb) / 2;
}

Map<String, List<int>>? _tplGrids;

Future<Map<String, List<int>>> _templateGrids() async {
  if (_tplGrids != null) return _tplGrids!;
  final r = <String, List<int>>{};
  for (final t in _tpls) {
    final m = await _alpha(_N, (c) {
      c.scale(_N / 100);
      t.draw(c, Colors.black, true);
    });
    r[t.id] = _grid(m, _N)!;
  }
  return _tplGrids = r;
}


Future<Uint8List> _render(_Tpl t, Color col, _Deco? d) async {
  const res = 512;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.scale(res / 100);
  _deco = d;
  t.draw(c, col, false);
  _deco = null;
  final img = await rec.endRecording().toImage(res, res);
  return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

class _DrawPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _DrawPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size s) {
    final g = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1;
    for (double x = 0; x <= s.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), g);
      canvas.drawLine(Offset(0, x), Offset(s.width, x), g);
    }
    canvas.save();
    canvas.clipRect(Offset.zero & s);
    _ink(canvas, strokes, const Color(0xFF4A3B5C));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DrawPainter o) => true;
}

/// Haz un boceto y/o descríbelo: se transforma en un objeto de la tienda.
class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});
  @override
  State<DrawScreen> createState() => _DrawState();
}

List<Color> _buildPalette() {
  final l = <Color>[];
  for (final sv in const [[0.32, 1.0], [0.85, 0.96], [0.8, 0.55]]) {
    for (int i = 0; i < 12; i++) {
      l.add(HSVColor.fromAHSV(1, i * 30.0, sv[0], sv[1]).toColor());
    }
  }
  l.addAll(const [
    Color(0xFFFFFFFF), Color(0xFFFFF1D6), Color(0xFFEAD7B7), Color(0xFFC8D0DC), Color(0xFF9AA3B2), Color(0xFF5A6272),
    Color(0xFF2B2B3A), Color(0xFF8B5A3C), Color(0xFFF2B134), Color(0xFF1F3A7A), Color(0xFF8C1F3A), Color(0xFF2FC5C0),
  ]);
  return l;
}

class _DrawState extends State<DrawScreen> {
  final palette = _buildPalette();
  static const kinds = <List<String>>[
    ['', 'Nada'], ['letter', 'Letra'], ['star', '⭐'], ['heart', '❤️'], ['stripes', 'Rayas'], ['dots', 'Lunares'],
    ['flower', '🌼'], ['rainbow', '🌈'], ['checks', 'Cuadros'], ['moon', '🌙'], ['bolt', '⚡'], ['paw', '🐾'],
  ];
  final List<_Stroke> strokes = [];
  Color color = const Color(0xFF3F7FE0);
  Color color2 = Colors.white;
  bool detailTarget = false;
  double width = 12;
  String dKind = '';
  bool dBig = false;
  List<_Tpl> ranked = [];
  _Tpl? pick;
  Uint8List? preview;
  int _job = 0;
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final letterCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    letterCtrl.dispose();
    super.dispose();
  }

  void _msg(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  _Deco? _curDeco() {
    final letter = (dKind == 'letter' || letterCtrl.text.trim().isNotEmpty) ? letterCtrl.text.trim() : '';
    final kind = (dKind.isEmpty || dKind == 'letter') ? null : dKind;
    if (letter.isEmpty && kind == null) return null;
    return _Deco(letter: letter.isEmpty ? null : letter, kind: kind, col: color2, big: dBig);
  }

  // lee la descripción y rellena objeto, color y detalle
  void _onDesc(String text) {
    final p = _parse(text);
    if (p.color != null) color = p.color!;
    if (p.color2 != null) color2 = p.color2!;
    if (p.letter != null) {
      letterCtrl.text = p.letter!;
      dKind = 'letter';
    }
    if (p.kind != null) dKind = p.kind!;
    dBig = p.big;
    if (p.tpl != null) {
      pick = _tpls.firstWhere((t) => t.id == p.tpl);
    }
    if (pick != null) _choose(pick!); else setState(() {});
  }

  Future<void> _recognize() async {
    final job = ++_job;
    if (strokes.isEmpty) {
      setState(() => ranked = []);
      return;
    }
    double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
    for (final s in strokes) {
      for (final q in s.pts) {
        x0 = min(x0, q.dx);
        y0 = min(y0, q.dy);
        x1 = max(x1, q.dx);
        y1 = max(y1, q.dy);
      }
    }
    final bw = max(x1 - x0, 8.0), bh = max(y1 - y0, 8.0);
    final k = 104 / max(bw, bh);
    final sm = await _alpha(_N, (c) {
      c.translate(_N / 2, _N / 2);
      c.scale(k);
      c.translate(-(x0 + x1) / 2, -(y0 + y1) / 2);
      _ink(c, strokes, Colors.black);
    });
    final filled = _closeFill(sm, _N, 4);
    final g = _grid(filled, _N);
    final tg = await _templateGrids();
    if (g == null || !mounted || job != _job) return;
    final arS = (g[_G * _G] / g[_G * _G + 1]).clamp(0.2, 5.0);
    final sc = <_Tpl, double>{};
    for (final t in _tpls) {
      final h = tg[t.id]!;
      final arT = h[_G * _G] / h[_G * _G + 1];
      sc[t] = _overlap(g.sublist(0, _G * _G), h.sublist(0, _G * _G)) * exp(-0.9 * (log(arS / arT)).abs());
    }
    final r = _tpls.toList()..sort((a, b) => sc[b]!.compareTo(sc[a]!));
    ranked = r;
    // si la descripción ya dice qué es, manda la descripción
    if (_parse(descCtrl.text).tpl == null) await _choose(r.first);
    else if (mounted) setState(() {});
  }

  Future<void> _choose(_Tpl t) async {
    pick = t;
    final b = await _render(t, color, _curDeco());
    if (!mounted) return;
    setState(() => preview = b);
  }

  void _refresh() {
    if (pick != null) {
      _choose(pick!);
    } else {
      setState(() {});
    }
  }

  void _add(Offset p, {bool start = false}) {
    if (start) {
      strokes.add(_Stroke(width)..pts.add(p));
    } else if (strokes.isNotEmpty) {
      final l = strokes.last.pts;
      if ((l.last - p).distance > 3) l.add(p);
    }
    setState(() {});
  }

  Future<void> _save() async {
    final t = pick;
    if (t == null) {
      _msg('Haz un boceto o escribe qué es');
      return;
    }
    final name = nameCtrl.text.trim().isEmpty ? t.name : nameCtrl.text.trim();
    store.addCustom(name, 'acc', t.slot, await _render(t, color, _curDeco()));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final side = min(MediaQuery.of(context).size.width - 16, 440.0);
    final order = ranked.isEmpty ? _tpls.toList() : ranked;
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo objeto ✏️')),
      body: Column(children: [
        const SizedBox(height: 8),
        Container(
          width: side,
          height: side * 0.78,
          decoration: BoxDecoration(color: const Color(0xFFF2EEF8), borderRadius: BorderRadius.circular(12)),
          foregroundDecoration:
              BoxDecoration(border: Border.all(color: kInk, width: 2), borderRadius: BorderRadius.circular(12)),
          child: GestureDetector(
            onTapUp: (d) {
              _add(d.localPosition, start: true);
              _recognize();
            },
            onPanStart: (d) => _add(d.localPosition, start: true),
            onPanUpdate: (d) => _add(d.localPosition),
            onPanEnd: (_) => _recognize(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(size: Size(side, side * 0.78), painter: _DrawPainter(strokes)),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Trazo'),
              SizedBox(width: 130, child: Slider(value: width, min: 6, max: 26, onChanged: (v) => setState(() => width = v))),
              IconButton(
                  onPressed: () {
                    if (strokes.isNotEmpty) strokes.removeLast();
                    _recognize();
                  },
                  icon: const Icon(Icons.undo)),
              IconButton(
                  onPressed: () {
                    strokes.clear();
                    _recognize();
                  },
                  icon: const Icon(Icons.delete_outline)),
            ]),
            TextField(
              controller: descCtrl,
              onChanged: _onDesc,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Describe el objeto (opcional)',
                  helperText: 'Ej.: es una gorra en color azul con una letra A gigante',
                  helperMaxLines: 2,
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 0, children: [
              for (final t in order)
                ChoiceChip(label: Text(t.name), selected: pick == t, onSelected: (_) => _choose(t)),
            ]),
            const Divider(),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('🎨 Color del objeto'), selected: !detailTarget, onSelected: (_) => setState(() => detailTarget = false)),
              ChoiceChip(label: const Text('✨ Color del detalle'), selected: detailTarget, onSelected: (_) => setState(() => detailTarget = true)),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
              for (final c in palette)
                GestureDetector(
                  onTap: () {
                    if (detailTarget) {
                      color2 = c;
                    } else {
                      color = c;
                    }
                    _refresh();
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: (detailTarget ? color2 : color) == c ? Colors.black : Colors.black26,
                            width: (detailTarget ? color2 : color) == c ? 3 : 1)),
                  ),
                ),
            ]),
            const Divider(),
            const Text('Detalle', style: TextStyle(fontWeight: FontWeight.w700)),
            Wrap(spacing: 6, children: [
              for (final k in kinds)
                ChoiceChip(
                    label: Text(k[1]),
                    selected: dKind == k[0],
                    onSelected: (_) {
                      dKind = k[0];
                      if (k[0] == '') letterCtrl.clear();
                      _refresh();
                    }),
            ]),
            Row(children: [
              SizedBox(
                  width: 120,
                  child: TextField(
                      controller: letterCtrl,
                      maxLength: 2,
                      onChanged: (_) => _refresh(),
                      decoration: const InputDecoration(labelText: 'Letra / nº', counterText: ''))),
              const SizedBox(width: 12),
              const Text('Grande'),
              Switch(
                  value: dBig,
                  onChanged: (v) {
                    dBig = v;
                    _refresh();
                  }),
            ]),
            if (preview != null && pick != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Container(
                    color: const Color(0xFFF2EEF8),
                    child: Image.memory(preview!, width: 170, height: 170, filterQuality: FilterQuality.high)),
              ),
              Center(child: Text('Parece: ${pick!.name} ✨', style: const TextStyle(fontWeight: FontWeight.w700))),
            ],
            TextField(controller: nameCtrl, maxLength: 24, decoration: const InputDecoration(labelText: 'Nombre (opcional)')),
            FilledButton(onPressed: _save, child: const Text('Añadir a la tienda 🛒')),
          ]),
        ),
      ]),
    );
  }
}
