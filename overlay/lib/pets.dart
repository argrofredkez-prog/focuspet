import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'data.dart';
import 'focus_animal.dart';
import 'widgets.dart';

const petKinds = ['mariposa', 'buho', 'abeja', 'fenix'];
const petLabels = {
  'mariposa': 'Mariposa 🦋',
  'buho': 'Búho 🦉',
  'abeja': 'Abeja 🐝',
  'fenix': 'Fénix 🔥',
};
const petDefaultColor = {
  'mariposa': 0xFF3FC1C9,
  'buho': 0xFF6C8EBF,
  'abeja': 0xFFFFE100,
  'fenix': 0xFFFF6B3D,
};
const petDefaultName = {
  'mariposa': 'Mariposi',
  'buho': 'Búho',
  'abeja': 'Abejita',
  'fenix': 'Fénix',
};
const petPalette = [
  0xFFE8445A, 0xFFFF8A3D, 0xFFFFD84D, 0xFFA6E34F, 0xFF6BCB77, 0xFF2FB5A0, 0xFF4FC3F7, 0xFF3F9BE0,
  0xFF8E5BD9, 0xFFB59CFF, 0xFFFF8FB8, 0xFFFFB6D5, 0xFFB08968, 0xFF8B5A3C, 0xFFF5E6C8, 0xFFFFFFFF,
  0xFFBFC5D2, 0xFF6B7280, 0xFF2B2140, 0xFFFFC9A8,
];
const animalLabels = {
  Animal.cerdo: 'Cerdito 🐷',
  Animal.unicornio: 'Unicornio 🦄',
  Animal.tigre: 'Tigre 🐯',
  Animal.cocodrilo: 'Dragón 🐲',
};
// frases por defecto (si no eliges ninguna)
const petDefaultPhrases = [
  'Vuelve al trabajo, es hora de conseguirlo 💪',
  'Tu objetivo no descansa, tú tampoco',
  'La disciplina vence todo',
  'El mejor momento es ahora, regresa',
  'Otra oportunidad, vuelve',
  '¡Venga, otra sesión! Tú puedes 💪',
  'Solo 5 minutos y ya estás dentro 🚀',
  'Tu yo del futuro te lo agradecerá ✨',
];

/// Una sola mascota por animal (se elige tipo, nombre y color).
class Pet {
  final String kind, name;
  final int color;
  const Pet(this.kind, this.name, this.color);
  Pet copy({String? kind, String? name, int? color}) => Pet(kind ?? this.kind, name ?? this.name, color ?? this.color);
  Map<String, dynamic> toJson() => {'kind': kind, 'name': name, 'color': color};
}

Pet? loadPet(Animal a) {
  final s = store.p.getString('pet_${a.name}');
  if (s == null) return null;
  try {
    final m = Map<String, dynamic>.from(jsonDecode(s) as Map);
    final k = m['kind'] as String;
    return Pet(petKinds.contains(k) ? k : 'mariposa', m['name'] as String, m['color'] as int);
  } catch (_) {
    return null;
  }
}

void savePet(Animal a, Pet? p) {
  if (p == null) {
    store.p.remove('pet_${a.name}');
  } else {
    store.p.setString('pet_${a.name}', jsonEncode(p.toJson()));
  }
  syncPetReminders();
}

/// Frases de TODAS las mascotas: las elegidas del repertorio 💬 (o las de por defecto).
List<String> petPhrases() {
  final l = store.p.getStringList('pet_phrases');
  return (l == null || l.isEmpty) ? petDefaultPhrases : l;
}

void savePetPhrases(List<String> l) {
  store.p.setStringList('pet_phrases', l);
  syncPetReminders();
}

String petPhrase() {
  final l = petPhrases();
  return l[Random().nextInt(l.length)];
}

const _pch = MethodChannel('focuspet/blocker');

// programa (o apaga) los avisos de las mascotas en el móvil
Future<void> syncPetReminders() async {
  final pets = [for (final a in Animal.values) loadPet(a)].whereType<Pet>().toList();
  final ph = petPhrases();
  final data = jsonEncode([
    for (final n in (pets.isEmpty ? ['Tu mascota'] : [for (final p in pets) p.name])) {'name': n, 'phrases': ph}
  ]);
  try {
    await _pch.invokeMethod('petReminder', {
      'on': store.p.getBool('pet_rem_on') ?? false,
      'every': store.p.getInt('pet_rem_min') ?? 120,
      'from': store.p.getInt('pet_sleep_from') ?? 23 * 60,
      'to': store.p.getInt('pet_sleep_to') ?? 8 * 60,
      'data': data,
    });
  } catch (_) {}
}

// ---------------------------------------------------------------- dibujo
class PetSprite extends StatefulWidget {
  final String kind;
  final Color color;
  final double size;
  const PetSprite({super.key, required this.kind, required this.color, this.size = 80});
  @override
  State<PetSprite> createState() => _PetSpriteState();
}

class _PetSpriteState extends State<PetSprite> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
              size: Size.square(widget.size), painter: _PetPainter(widget.kind, widget.color, _c.value)),
        ),
      );
}

class _PetPainter extends CustomPainter {
  final String kind;
  final Color col;
  final double t;
  _PetPainter(this.kind, this.col, this.t);

  static const ink = Color(0xFF2B2140);
  Paint _f(Color c) => Paint()..color = c;
  Paint _l(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  Color _d(Color c, [double k = .42]) => Color.lerp(c, Colors.black, k)!;
  Color _w(Color c, [double k = .5]) => Color.lerp(c, Colors.white, k)!;

  // cuerpo redondo: degradado, contorno y brillo
  void _blob(Canvas c, Rect r, Color base) {
    c.drawOval(
        r,
        Paint()
          ..shader = RadialGradient(
                  center: const Alignment(-.35, -.45),
                  colors: [_w(base, .55), base, _d(base, .2)],
                  stops: const [0, .55, 1])
              .createShader(r));
    c.drawOval(r, _l(_d(base), 1.7));
    c.drawOval(Rect.fromLTWH(r.left + r.width * .2, r.top + r.height * .1, r.width * .28, r.height * .15), _f(const Color(0x66FFFFFF)));
  }

  void _shape(Canvas c, Path p, Color base) {
    final r = p.getBounds();
    c.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_w(base, .4), base, _d(base, .15)])
              .createShader(r));
    c.drawPath(p, _l(_d(base), 1.6));
  }

  Path _heart(Offset o, double r) => Path()
    ..moveTo(o.dx, o.dy + r * .9)
    ..cubicTo(o.dx - r * 1.6, o.dy - r * .2, o.dx - r * .7, o.dy - r * 1.2, o.dx, o.dy - r * .4)
    ..cubicTo(o.dx + r * .7, o.dy - r * 1.2, o.dx + r * 1.6, o.dy - r * .2, o.dx, o.dy + r * .9)
    ..close();

  void _sparkle(Canvas c, Offset o, double r) {
    c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - r)
          ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
          ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
          ..close(),
        _f(const Color(0xFFFFF3B0)));
  }

  void _feather(Canvas c, Offset pv, double ang, double len, Color base) {
    c.save();
    c.translate(pv.dx, pv.dy);
    c.rotate(ang);
    _shape(c, Path()..moveTo(0, 0)..quadraticBezierTo(len * .5, -len * .17, len, 0)..quadraticBezierTo(len * .5, len * .17, 0, 0)..close(), base);
    c.restore();
  }

  Path _flame(Offset o, double h) => Path()
    ..moveTo(o.dx, o.dy - h)
    ..quadraticBezierTo(o.dx + h * .6, o.dy - h * .2, o.dx, o.dy + h * .4)
    ..quadraticBezierTo(o.dx - h * .6, o.dy - h * .2, o.dx, o.dy - h)
    ..close();

  // ojos grandes con doble brillo, mejillas y boquita «ω»
  void _face(Canvas c, Offset o, double sep, {double s = 1}) {
    for (final d in [-1.0, 1.0]) {
      final e = o + Offset(d * sep, 0);
      c.drawOval(Rect.fromCenter(center: e, width: 11 * s, height: 13 * s), _f(ink));
      c.drawCircle(e + Offset(-1.6 * s, -2.8 * s), 3.1 * s, _f(Colors.white));
      c.drawCircle(e + Offset(1.8 * s, 2.6 * s), 1.5 * s, _f(const Color(0xCCFFFFFF)));
      final ch = o + Offset(d * (sep + 9 * s), 7 * s);
      c.drawOval(
          Rect.fromCenter(center: ch, width: 9 * s, height: 6 * s),
          Paint()
            ..shader = const RadialGradient(colors: [Color(0xAAFF6F9F), Color(0x00FF6F9F)])
                .createShader(Rect.fromCenter(center: ch, width: 9 * s, height: 6 * s)));
    }
    for (final d in [-1.0, 1.0]) {
      c.drawArc(Rect.fromCenter(center: o + Offset(d * 2.2 * s, 6.5 * s), width: 4.4 * s, height: 4 * s), 0, pi, false, _l(ink, 1.4));
    }
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100, size.height / 100);
    final dk = _d(col, .3);
    final lt = _w(col, .55);
    c.drawOval(Rect.fromCenter(center: const Offset(50, 95), width: 46, height: 7), _f(const Color(0x22000000)));
    final hop = sin(t * 2 * pi).abs();
    c.translate(0, -5 * hop);
    switch (kind) {
      case 'mariposa':
        final fm = .45 + .55 * sin(t * 4 * pi).abs();
        const pink = Color(0xFFFF9AB8);
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50, 56);
          c.scale(d * fm, 1);
          final up = Path()
            ..moveTo(0, -2)
            ..cubicTo(10, -66, 62, -56, 52, -14)
            ..cubicTo(46, 6, 18, 8, 0, 4)
            ..close();
          final lo = Path()
            ..moveTo(0, 6)
            ..cubicTo(40, 2, 58, 24, 44, 44)
            ..cubicTo(32, 62, 8, 48, 0, 16)
            ..close();
          _shape(c, up, col);
          _shape(c, lo, _w(col, .15));
          c.drawPath(Path()..moveTo(4, -6)..cubicTo(14, -44, 40, -42, 36, -16)..cubicTo(30, -4, 14, -2, 4, 0)..close(), _f(_w(col, .6)));
          c.drawPath(Path()..moveTo(4, 8)..cubicTo(26, 6, 38, 22, 28, 36)..cubicTo(18, 44, 8, 34, 4, 18)..close(), _f(_w(col, .6)));
          c.drawPath(Path()..moveTo(6, -10)..quadraticBezierTo(22, -26, 34, -34)..quadraticBezierTo(24, -14, 6, -6)..close(), _f(pink));
          c.drawCircle(const Offset(40, -44), 8, _f(pink));
          c.drawArc(Rect.fromCircle(center: const Offset(40, -44), radius: 4.6), .4, 5.0, false, _l(_d(pink, .35), 1.3));
          c.drawArc(Rect.fromCircle(center: const Offset(40, -44), radius: 2.2), 1.0, 4.6, false, _l(_d(pink, .35), 1.2));
          for (final o in const [Offset(46, 24), Offset(40, 33), Offset(32, 40), Offset(24, 44)]) {
            c.drawCircle(o, 2.6, _f(const Color(0xFFFF7A90)));
            c.drawCircle(o, 2.6, _l(_d(col, .4), .8));
          }
          c.drawPath(Path()..moveTo(6, -4)..quadraticBezierTo(24, -2, 44, -20), _l(_d(col, .3).withAlpha(140), 1));
          c.restore();
        }
        final bdy = Path()..addOval(Rect.fromCenter(center: const Offset(50, 66), width: 12, height: 40));
        _shape(c, bdy, const Color(0xFFFFD9A0));
        c.save();
        c.clipPath(bdy);
        for (final y in [56.0, 64.0, 72.0, 80.0]) {
          c.drawRect(Rect.fromLTWH(40, y, 20, 3.2), _f(const Color(0xFFFF9AA8)));
        }
        c.restore();
        c.drawPath(bdy, _l(_d(const Color(0xFFFFD9A0), .45), 1.5));
        c.drawPath(Path()..moveTo(46, 34)..quadraticBezierTo(40, 18, 34, 14)..quadraticBezierTo(30, 10, 33, 8)..quadraticBezierTo(37, 9, 35, 12), _l(ink, 1.5));
        c.drawPath(Path()..moveTo(54, 34)..quadraticBezierTo(60, 18, 66, 14)..quadraticBezierTo(70, 10, 67, 8)..quadraticBezierTo(63, 9, 65, 12), _l(ink, 1.5));
        c.drawCircle(const Offset(31, 9), 2.3, _f(const Color(0xFF7EC8E3)));
        c.drawCircle(const Offset(69, 9), 2.3, _f(const Color(0xFF7EC8E3)));
        _blob(c, Rect.fromCenter(center: const Offset(50, 42), width: 21, height: 19), const Color(0xFF7EC8E3));
        _face(c, const Offset(50, 42), 4.6, s: .62);
        break;
      case 'buho':
        final fl = .12 * sin(t * 2 * pi);
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50 + d * 31, 66);
          c.rotate(d * (.12 + fl));
          _blob(c, Rect.fromCenter(center: Offset.zero, width: 17, height: 44), _d(col, .2));
          c.restore();
        }
        _blob(c, Rect.fromCenter(center: const Offset(50, 64), width: 62, height: 60), col);
        c.drawOval(Rect.fromCenter(center: const Offset(50, 76), width: 38, height: 38), _f(const Color(0xFFFFF6E6)));
        for (final y in [70.0, 79.0, 88.0]) {
          for (final x in [-8.0, 8.0]) {
            c.drawArc(Rect.fromCenter(center: Offset(50 + x, y), width: 14, height: 8), .3, pi - .6, false, _l(const Color(0xFFC9B9A0), 1.4));
          }
        }
        for (final d in [-1.0, 1.0]) {
          final tuft = Path()
            ..moveTo(50 + d * 30, 34)
            ..quadraticBezierTo(50 + d * 38, 14, 50 + d * 32, 6)
            ..quadraticBezierTo(50 + d * 26, 16, 50 + d * 16, 20)
            ..close();
          _shape(c, tuft, _d(col, .18));
        }
        _blob(c, Rect.fromCenter(center: const Offset(50, 42), width: 66, height: 50), col);
        _shape(c, Path()..moveTo(50, 20)..lineTo(58, 30)..lineTo(50, 50)..lineTo(42, 30)..close(), _d(col, .22));
        for (final d in [-1.0, 1.0]) {
          final e = Offset(50 + d * 16, 43);
          c.drawCircle(e, 17.5, _f(const Color(0xFFFFF6E6)));
          c.drawCircle(e, 17.5, _l(const Color(0xFF3B3355), 2.4));
          c.drawCircle(e, 11, _f(ink));
          c.drawCircle(e.translate(0, 1), 8, _f(const Color(0xFFE8842E)));
          c.drawCircle(e.translate(0, 1.5), 4.8, _f(ink));
          c.drawCircle(e.translate(-3, -3), 3.2, _f(Colors.white));
          c.drawCircle(e.translate(3, 4), 1.6, _f(Colors.white));
          c.drawOval(Rect.fromCenter(center: Offset(50 + d * 27, 58), width: 9, height: 5), _f(const Color(0x77FF6F9F)));
        }
        _shape(c, Path()..moveTo(50, 50)..lineTo(45.5, 57)..lineTo(54.5, 57)..close(), const Color(0xFFFF9F43));
        for (final d in [-1.0, 1.0]) {
          for (final x in [-4.0, 0.0, 4.0]) {
            c.drawOval(Rect.fromCenter(center: Offset(50 + d * 12 + x, 94), width: 4.4, height: 5), _f(const Color(0xFFFF9F43)));
          }
        }
        break;
      case 'abeja':
        final fw = .75 + .25 * sin(t * 6 * pi).abs();
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50 + d * 17, 68);
          c.rotate(d * (.5 + .12 * sin(t * 6 * pi)));
          _shape(c, Path()..addOval(Rect.fromCenter(center: Offset(d * 13 * fw, 0), width: 30 * fw, height: 19)), const Color(0xFFA8DCE0));
          c.restore();
        }
        c.drawPath(Path()..moveTo(38, 24)..quadraticBezierTo(30, 8, 22, 8), _l(ink, 2));
        c.drawPath(Path()..moveTo(62, 24)..quadraticBezierTo(70, 8, 78, 8), _l(ink, 2));
        c.drawCircle(const Offset(20, 8), 4.5, _f(ink));
        c.drawCircle(const Offset(80, 8), 4.5, _f(ink));
        c.drawPath(Path()..moveTo(46, 90)..lineTo(50, 101)..lineTo(54, 90)..close(), _f(ink));
        final bd = Rect.fromCenter(center: const Offset(50, 72), width: 36, height: 40);
        _blob(c, bd, col);
        c.save();
        c.clipPath(Path()..addOval(bd));
        for (final y in [63.0, 75.0, 87.0]) {
          c.drawRect(Rect.fromLTWH(30, y, 40, 6.5), _f(ink));
        }
        c.restore();
        c.drawOval(bd, _l(_d(col), 1.6));
        final hd = Rect.fromCenter(center: const Offset(50, 40), width: 68, height: 52);
        _blob(c, hd, col);
        for (final d in [-1.0, 1.0]) {
          final e = Offset(50 + d * 16, 33);
          c.drawOval(Rect.fromCenter(center: e, width: 25, height: 27), _f(Colors.white));
          c.drawOval(Rect.fromCenter(center: e, width: 25, height: 27), _l(const Color(0xFFD9E6F0), 1));
          c.drawCircle(e.translate(0, -.5), 8.8, _f(ink));
          c.drawCircle(e.translate(-3.2, -4), 3.5, _f(Colors.white));
          c.drawCircle(e.translate(3, 2.6), 1.8, _f(Colors.white));
          c.drawOval(Rect.fromCenter(center: Offset(50 + d * 28, 50), width: 9, height: 5), _f(const Color(0x66FF8FA8)));
        }
        final mouth = Path()
          ..moveTo(40, 50)
          ..quadraticBezierTo(50, 64, 60, 50)
          ..close();
        c.drawPath(mouth, _f(const Color(0xFFE8374A)));
        c.drawPath(mouth, _l(ink, 1.4));
        break;
      case 'fenix':
        const gold = Color(0xFFFFC93C);
        final sw = .12 * sin(t * 2 * pi);
        for (final k in [-1, 0, 1]) {
          _feather(c, const Offset(50, 78), pi / 2 + k * .38 + sw * k, 30 - k.abs() * 4.0, k == 0 ? col : gold);
        }
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50, 56);
          c.scale(d, 1);
          for (int k = 0; k < 5; k++) {
            _feather(c, const Offset(10, 0), -1.25 + k * .33 + sw, 40 - k * 3.0, k.isEven ? _d(col, .12) : col);
          }
          for (int k = 0; k < 4; k++) {
            _feather(c, const Offset(10, 2), -.95 + k * .34 + sw, 26 - k * 2.0, k < 2 ? gold : _w(col, .25));
          }
          c.restore();
        }
        _blob(c, Rect.fromCenter(center: const Offset(50, 66), width: 36, height: 38), col);
        c.drawOval(Rect.fromCenter(center: const Offset(50, 71), width: 21, height: 23), _f(const Color(0xFFFFF1D6)));
        c.drawPath(_flame(const Offset(50, 72), 8), _f(gold));
        for (final d in [-1.0, 1.0]) {
          for (final x in [-3.0, 0.0, 3.0]) {
            c.drawLine(Offset(50 + d * 8 + x, 84), Offset(50 + d * 8 + x * 1.6, 90), _l(const Color(0xFFE08A1E), 1.6));
          }
        }
        _blob(c, Rect.fromCenter(center: const Offset(50, 40), width: 40, height: 36), col);
        for (final k in [-1, 0, 1]) {
          final fb = Offset(50.0 + k * 9, 24);
          c.drawPath(_flame(fb.translate(sw * 14 * k, -4), 13 - k.abs() * 3.0), _f(k == 0 ? gold : const Color(0xFFFFA630)));
          c.drawPath(_flame(fb.translate(sw * 14 * k, -3), 7 - k.abs() * 2.0), _f(const Color(0xFFFFE9A0)));
        }
        _face(c, const Offset(50, 41), 9.5, s: .9);
        _shape(c, Path()..moveTo(50, 44)..lineTo(46.5, 49)..lineTo(53.5, 49)..close(), gold);
        final fa = .6 + .4 * sin(t * 4 * pi);
        c.drawPath(_flame(const Offset(14, 40), 6 * fa), _f(const Color(0xCCFFA630)));
        c.drawPath(_flame(const Offset(88, 52), 5 * (1.2 - fa * .4)), _f(const Color(0xCCFF7A30)));
        break;
    }
    final k1 = .6 + .4 * sin(t * 4 * pi);
    final k2 = .6 + .4 * sin(t * 4 * pi + 2);
    _sparkle(c, Offset(12, 22 + 3 * sin(t * 2 * pi)), 4.2 * k1);
    _sparkle(c, Offset(90, 30 - 3 * sin(t * 2 * pi)), 3.4 * k2);
    c.restore();
  }

  @override
  bool shouldRepaint(_PetPainter o) => o.t != t || o.kind != kind || o.col != col;
}

// ---------------------------------------------------------------- escenario: la mascota da vueltas alrededor del animal
class PetStage extends StatefulWidget {
  final Animal animal;
  final Widget child;
  final Color ink;
  final VoidCallback onStart;
  const PetStage({super.key, required this.animal, required this.child, required this.ink, required this.onStart});
  @override
  State<PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<PetStage> with SingleTickerProviderStateMixin {
  final _rnd = Random();
  final _tickN = ValueNotifier<double>(0);
  late final Ticker _tk = createTicker(_onTick);
  Duration _last = Duration.zero;
  double _el = 0, th = 0, om = 0, rk = 1, ryk = 1, rkT = 1, rykT = 1, next = 5;
  double dir = 1;
  Timer? _t, _hide, _talkT, _buzzT;
  String? msg;
  bool talking = false, buzzing = false;

  @override
  void initState() {
    super.initState();
    dir = _rnd.nextBool() ? 1 : -1;
    _tk.start();
    _t = Timer.periodic(const Duration(seconds: 25), (_) => _speak());
    Future.delayed(const Duration(milliseconds: 2500), _speak);
  }

  @override
  void dispose() {
    _tk.dispose();
    _tickN.dispose();
    _t?.cancel();
    _hide?.cancel();
    _talkT?.cancel();
    _buzzT?.cancel();
    super.dispose();
  }

  // movimiento suave: círculos grandes que cambian de sentido y de tamaño
  void _onTick(Duration d) {
    final dt = ((d - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = d;
    _el = d.inMicroseconds / 1e6;
    if (_el > next) {
      if (_rnd.nextDouble() < .6) dir = -dir;
      rkT = .7 + _rnd.nextDouble() * .5;
      rykT = .75 + _rnd.nextDouble() * .3;
      next = _el + 5 + _rnd.nextDouble() * 8;
    }
    om += (dir * .4 * (talking ? .2 : 1.0) - om) * min(1.0, dt * 1.2);
    th += om * dt;
    rk += (rkT - rk) * min(1.0, dt * .5);
    ryk += (rykT - ryk) * min(1.0, dt * .5);
    _tickN.value = _el;
  }

  Future<void> _buzz() async {
    for (int i = 0; i < 2; i++) {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 130));
      if (!mounted) return;
    }
  }

  void _speak() {
    if (!mounted || loadPet(widget.animal) == null) return;
    setState(() {
      msg = petPhrase();
      talking = true;
      buzzing = true;
    });
    _buzz();
    _buzzT?.cancel();
    _buzzT = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => buzzing = false);
    });
    _talkT?.cancel();
    _talkT = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => talking = false);
    });
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => msg = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = loadPet(widget.animal);
    return Column(children: [
      SizedBox(
        height: 230,
        child: LayoutBuilder(
          builder: (_, box) => AnimatedBuilder(
            animation: _tickN,
            builder: (_, __) => Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: widget.child),
              if (pet != null) _pet(pet, box.maxWidth),
            ]),
          ),
        ),
      ),
      if (msg != null && pet != null) ...[
        ComicBubble(text: '${pet.name}: $msg'),
        FilledButton.tonal(
            onPressed: () {
              setState(() => msg = null);
              widget.onStart();
            },
            child: const Text('¡Empezar sesión! 🚀')),
      ],
      if (pet == null)
        ActionChip(
            label: const Text('🐾 Elegir mascota ayudante'),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => PetsScreen(animal: widget.animal)));
              if (mounted) setState(() {});
            }),
    ]);
  }

  Widget _pet(Pet p, double w) {
    const half = 21.0;
    var x = w / 2 + (w / 2) * rk * cos(th) - half;
    var y = 115 + 100 * ryk * sin(th) - half + 3 * sin(_el * 1.3);
    if (buzzing) {
      x += 2.2 * sin(_el * 45);
      y += 1.6 * cos(_el * 52);
    }
    return Positioned(
      left: x,
      top: y,
      child: AnimatedScale(
        scale: talking ? 1.7 : 1.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        child: GestureDetector(
          onTap: _speak,
          child: PetSprite(kind: p.kind, color: Color(p.color), size: 42),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- pantalla de la mascota
class PetsScreen extends StatefulWidget {
  final Animal animal;
  const PetsScreen({super.key, required this.animal});
  @override
  State<PetsScreen> createState() => _PetsState();
}

class _PetsState extends State<PetsScreen> {
  late Pet? pet = loadPet(widget.animal);
  late final nameC = TextEditingController(text: pet?.name ?? '');
  late final Set<String> chosen = {...(store.p.getStringList('pet_phrases') ?? <String>[])};
  late final List<String> rep = [...loadPhrases(), ...chosen.where((x) => !loadPhrases().contains(x))];
  bool remOn = store.p.getBool('pet_rem_on') ?? false;
  int every = store.p.getInt('pet_rem_min') ?? 120;
  int from = store.p.getInt('pet_sleep_from') ?? 23 * 60;
  int to = store.p.getInt('pet_sleep_to') ?? 8 * 60;

  @override
  void dispose() {
    nameC.dispose();
    super.dispose();
  }

  String _hm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  String _every(int m) => m < 60 ? '$m min' : (m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60} min');

  void _setPet(Pet? p) {
    setState(() => pet = p);
    savePet(widget.animal, p);
  }

  void _savePhrases() {
    savePetPhrases([for (final f in rep) if (chosen.contains(f)) f]);
    setState(() {});
  }

  void _saveRem() {
    store.p.setBool('pet_rem_on', remOn);
    store.p.setInt('pet_rem_min', every);
    store.p.setInt('pet_sleep_from', from);
    store.p.setInt('pet_sleep_to', to);
    syncPetReminders();
    setState(() {});
  }

  Future<void> _time(bool isFrom) async {
    final v = isFrom ? from : to;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: v ~/ 60, minute: v % 60));
    if (t == null) return;
    if (isFrom) {
      from = t.hour * 60 + t.minute;
    } else {
      to = t.hour * 60 + t.minute;
    }
    _saveRem();
  }

  Widget _remCard() => Card(
        margin: const EdgeInsets.all(12),
        child: Column(children: [
          SwitchListTile(
            title: const Text('🔔 Avisos para volver a estudiar'),
            subtitle: const Text('Tu mascota te manda una notificación'),
            value: remOn,
            onChanged: (v) {
              remOn = v;
              if (v) _pch.invokeMethod('setupBedtime'); // pide permiso de notificaciones
              _saveRem();
            },
          ),
          if (remOn) ...[
            ListTile(
              title: const Text('Cada'),
              trailing: DropdownButton<int>(
                value: const [30, 60, 90, 120, 180, 240, 360].contains(every) ? every : 120,
                items: [for (final m in const [30, 60, 90, 120, 180, 240, 360]) DropdownMenuItem(value: m, child: Text(_every(m)))],
                onChanged: (v) {
                  every = v ?? 120;
                  _saveRem();
                },
              ),
            ),
            ListTile(
              title: const Text('😴 Sin avisos al dormir'),
              subtitle: Text('De ${_hm(from)} a ${_hm(to)}'),
              trailing: Wrap(children: [
                TextButton(onPressed: () => _time(true), child: const Text('Desde')),
                TextButton(onPressed: () => _time(false), child: const Text('Hasta')),
              ]),
            ),
          ],
        ]),
      );

  Widget _pick() => Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
        for (final k in petKinds)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final p = Pet(k, petDefaultName[k]!, petDefaultColor[k]!);
              nameC.text = p.name;
              _setPet(p);
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                PetSprite(kind: k, color: Color(petDefaultColor[k]!), size: 72),
                Text(petLabels[k]!),
              ]),
            ),
          ),
      ]);

  Widget _edit(Pet p) => Column(children: [
        PetSprite(kind: p.kind, color: Color(p.color), size: 120),
        Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
          for (final k in petKinds)
            ChoiceChip(
                label: Text(petLabels[k]!),
                selected: p.kind == k,
                onSelected: (_) {
                  final cur = pet!;
                  var n = cur.name;
                  var c = cur.color;
                  if (n == petDefaultName[cur.kind]) {
                    n = petDefaultName[k]!;
                    nameC.text = n;
                  }
                  if (c == petDefaultColor[cur.kind]) c = petDefaultColor[k]!;
                  _setPet(cur.copy(kind: k, name: n, color: c));
                }),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          for (final c in petPalette)
            GestureDetector(
              onTap: () => _setPet(pet!.copy(color: c)),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: p.color == c ? Colors.black : Colors.black26, width: p.color == c ? 3 : 1)),
              ),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: nameC,
            maxLength: 16,
            decoration: const InputDecoration(labelText: 'Nombre'),
            onChanged: (v) {
              pet = pet!.copy(name: v.trim().isEmpty ? 'Mascota' : v.trim());
              savePet(widget.animal, pet);
            },
          ),
        ),
        TextButton(onPressed: () => _setPet(null), child: const Text('Quitar mascota')),
      ]);

  @override
  Widget build(BuildContext context) {
    final p = pet;
    return Scaffold(
      appBar: AppBar(title: const Text('Mascota ayudante 🐾')),
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        _remCard(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text('Mascota de ${animalLabels[widget.animal]} (una por animal)',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        p == null ? _pick() : _edit(p),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Expanded(child: Text('Frases de las mascotas (de tu repertorio 💬)', style: TextStyle(fontWeight: FontWeight.w900))),
            TextButton(
                onPressed: () {
                  chosen.addAll(rep);
                  _savePhrases();
                },
                child: const Text('Todas')),
            TextButton(
                onPressed: () {
                  chosen.clear();
                  _savePhrases();
                },
                child: const Text('Ninguna')),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Valen para todas tus mascotas. Sin elegir ninguna, usan frases motivadoras por defecto.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        for (final f in rep)
          CheckboxListTile(
            dense: true,
            value: chosen.contains(f),
            title: Text(f),
            onChanged: (v) {
              if (v == true) {
                chosen.add(f);
              } else {
                chosen.remove(f);
              }
              _savePhrases();
            },
          ),
      ]),
    );
  }
}
