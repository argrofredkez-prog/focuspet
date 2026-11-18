import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data.dart';
import 'widgets.dart';

const petKinds = ['mariposa', 'buho', 'abeja', 'pajarito', 'pollito'];
const petLabels = {
  'mariposa': 'Mariposa 🦋',
  'buho': 'Búho 🦉',
  'abeja': 'Abeja 🐝',
  'pajarito': 'Pajarito 🐦',
  'pollito': 'Pollito 🐥',
};
const petDefaultColor = {
  'mariposa': 0xFFB59CFF,
  'buho': 0xFFB08968,
  'abeja': 0xFFFFD84D,
  'pajarito': 0xFF4FC3F7,
  'pollito': 0xFFFFE066,
};
const petDefaultName = {
  'mariposa': 'Mariposi',
  'buho': 'Búho',
  'abeja': 'Abejita',
  'pajarito': 'Pío',
  'pollito': 'Pollito',
};
const petPalette = [
  0xFFE8445A, 0xFFFF8A3D, 0xFFFFD84D, 0xFFA6E34F, 0xFF6BCB77, 0xFF2FB5A0, 0xFF4FC3F7, 0xFF3F9BE0,
  0xFF8E5BD9, 0xFFB59CFF, 0xFFFF8FB8, 0xFFFFB6D5, 0xFFB08968, 0xFF8B5A3C, 0xFFF5E6C8, 0xFFFFFFFF,
  0xFFBFC5D2, 0xFF6B7280, 0xFF2B2140, 0xFFFFC9A8,
];
const petDefaultPhrases = [
  '¡Venga, otra sesión! Tú puedes 💪',
  'Solo 5 minutos y ya estás dentro 🚀',
  'Cada sesión te acerca a tu meta 🎯',
  'Tu yo del futuro te lo agradecerá ✨',
  'Respira hondo… ¡y a por ello! 🌟',
  'Un pasito más y descansas 😉',
  'La constancia gana al talento 🌱',
  '¡Mira cuánto has avanzado ya! 🏆',
];

class Pet {
  String id, kind, name;
  int color;
  List<String> phrases;
  Pet(this.id, this.kind, this.name, this.color, this.phrases);
  Map<String, dynamic> toJson() =>
      {'id': id, 'kind': kind, 'name': name, 'color': color, 'phrases': phrases};
  factory Pet.fromJson(Map<String, dynamic> m) {
    var k = m['kind'] as String;
    if (k == 'grillo') k = 'mariposa';
    if (k == 'mariquita') k = 'pajarito';
    return Pet(m['id'] as String, k, m['name'] as String, m['color'] as int,
        List<String>.from(m['phrases'] as List));
  }
}

List<Pet> loadPets() {
  final s = store.p.getString('pets');
  if (s == null) return [];
  try {
    return [for (final m in jsonDecode(s) as List) Pet.fromJson(Map<String, dynamic>.from(m as Map))];
  } catch (_) {
    return [];
  }
}

const _pch = MethodChannel('focuspet/blocker');
const petReminderDefaults = [
  'Vuelve al trabajo, es hora de conseguirlo 💪',
  'Tu objetivo no descansa, tú tampoco',
  'La disciplina vence todo',
  'El mejor momento es ahora, regresa',
  'Otra oportunidad, vuelve',
];

// programa (o apaga) los avisos de las mascotas en el móvil
Future<void> syncPetReminders() async {
  final pets = loadPets();
  final data = jsonEncode(pets.isEmpty
      ? [{'name': 'Tu mascota', 'phrases': petReminderDefaults}]
      : [for (final p in pets) {'name': p.name, 'phrases': p.phrases.isEmpty ? petReminderDefaults : p.phrases}]);
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

void savePets(List<Pet> l) {
  store.p.setString('pets', jsonEncode([for (final p in l) p.toJson()]));
  syncPetReminders();
}

String petPhrase([Pet? p]) {
  final l = loadPets();
  final pet = p ?? (l.isEmpty ? null : l[Random().nextInt(l.length)]);
  final ph = (pet == null || pet.phrases.isEmpty) ? petDefaultPhrases : pet.phrases;
  return ph[Random().nextInt(ph.length)];
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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

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
    c.translate(0, -8 * hop);
    switch (kind) {
      case 'mariposa':
        final fm = .35 + .65 * sin(t * 4 * pi).abs();
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50, 54);
          c.scale(d * fm, 1);
          final up = Path()
            ..moveTo(0, -4)
            ..cubicTo(30, -58, 70, -26, 44, 10)
            ..cubicTo(30, 16, 10, 6, 0, 2)
            ..close();
          final lo = Path()
            ..moveTo(0, 4)
            ..cubicTo(34, 6, 56, 34, 36, 50)
            ..cubicTo(20, 58, 4, 34, 0, 12)
            ..close();
          _shape(c, up, col);
          _shape(c, lo, _w(col, .4));
          c.drawCircle(const Offset(34, -20), 7, _f(const Color(0xCCFFFFFF)));
          c.drawCircle(const Offset(34, -20), 3.4, _f(_w(col, .2)));
          c.drawCircle(const Offset(24, 34), 4.5, _f(const Color(0xB3FFFFFF)));
          c.drawPath(Path()..moveTo(2, 0)..quadraticBezierTo(22, -12, 36, -30), _l(_d(col, .25).withAlpha(120), 1));
          c.restore();
        }
        _shape(c, Path()..addOval(Rect.fromCenter(center: const Offset(50, 64), width: 11, height: 40)), _d(col, .3));
        c.drawPath(Path()..moveTo(44, 31)..quadraticBezierTo(38, 14, 32, 10), _l(_d(col), 1.8));
        c.drawPath(Path()..moveTo(56, 31)..quadraticBezierTo(62, 14, 68, 10), _l(_d(col), 1.8));
        c.drawPath(_heart(const Offset(31, 9), 3.2), _f(const Color(0xFFFF6F9F)));
        c.drawPath(_heart(const Offset(69, 9), 3.2), _f(const Color(0xFFFF6F9F)));
        _blob(c, Rect.fromCenter(center: const Offset(50, 40), width: 28, height: 26), _w(col, .7));
        _face(c, const Offset(50, 41), 5.6, s: .85);
        break;
      case 'buho':
        _shape(c, Path()..moveTo(26, 28)..lineTo(30, 8)..lineTo(46, 24)..close(), _d(col, .12));
        _shape(c, Path()..moveTo(74, 28)..lineTo(70, 8)..lineTo(54, 24)..close(), _d(col, .12));
        final fl = .18 * sin(t * 2 * pi);
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50 + d * 33, 62);
          c.rotate(d * (.15 + fl));
          _blob(c, Rect.fromCenter(center: Offset.zero, width: 17, height: 42), _d(col, .18));
          c.restore();
        }
        _blob(c, Rect.fromCenter(center: const Offset(50, 58), width: 66, height: 72), col);
        c.drawOval(Rect.fromCenter(center: const Offset(50, 73), width: 38, height: 42), _f(_w(col, .65)));
        for (final y in [66.0, 75.0, 84.0]) {
          c.drawArc(Rect.fromCenter(center: Offset(50, y), width: 14, height: 8), .3, pi - .6, false, _l(_d(col, .2).withAlpha(110), 1.4));
        }
        for (final d in [-1.0, 1.0]) {
          final e = Offset(50 + d * 13, 44);
          c.drawCircle(e, 13.5, _f(_w(col, .8)));
          c.drawCircle(e, 13.5, _l(_d(col), 1.4));
          c.drawCircle(e.translate(0, 1), 7.4, _f(ink));
          c.drawCircle(e.translate(-2.4, -2), 2.9, _f(Colors.white));
          c.drawCircle(e.translate(2.4, 3.4), 1.4, _f(Colors.white));
          c.drawCircle(Offset(50 + d * 29, 56), 3.6, _f(const Color(0x66FF6F9F)));
        }
        _shape(c, Path()..moveTo(50, 50)..lineTo(45, 57)..lineTo(55, 57)..close(), const Color(0xFFFF9F43));
        c.drawPath(Path()..moveTo(50, 11)..lineTo(80, 22)..lineTo(50, 33)..lineTo(20, 22)..close(), _f(ink));
        c.drawPath(Path()..moveTo(36, 28)..lineTo(36, 35)..quadraticBezierTo(50, 41, 64, 35)..lineTo(64, 28)..close(), _f(const Color(0xFF3B3355)));
        c.drawLine(const Offset(76, 23), const Offset(79, 38), _l(const Color(0xFFFFD84D), 1.6));
        c.drawCircle(const Offset(79, 40), 2.6, _f(const Color(0xFFFFD84D)));
        c.drawLine(const Offset(42, 94), const Offset(42, 91), _l(const Color(0xFFFF9F43), 3));
        c.drawLine(const Offset(58, 94), const Offset(58, 91), _l(const Color(0xFFFF9F43), 3));
        break;
      case 'abeja':
        final fw = .6 + .4 * sin(t * 6 * pi).abs();
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50 + d * 15, 34);
          c.rotate(d * .55);
          _shape(c, Path()..addOval(Rect.fromCenter(center: Offset(0, -10 * fw), width: 22, height: 30 * fw)), const Color(0xFFD6EFFF));
          c.restore();
        }
        c.drawPath(Path()..moveTo(41, 31)..quadraticBezierTo(35, 12, 27, 14), _l(ink, 2));
        c.drawPath(Path()..moveTo(59, 31)..quadraticBezierTo(65, 12, 73, 14), _l(ink, 2));
        c.drawPath(_heart(const Offset(26, 13), 3.4), _f(const Color(0xFFFF6F9F)));
        c.drawPath(_heart(const Offset(74, 13), 3.4), _f(const Color(0xFFFF6F9F)));
        final bd = Rect.fromCenter(center: const Offset(50, 64), width: 70, height: 60);
        _blob(c, bd, col);
        c.save();
        c.clipPath(Path()..addOval(bd));
        for (final y in [70.0, 82.0]) {
          c.drawPath(Path()..moveTo(10, y)..quadraticBezierTo(50, y + 7, 90, y)..lineTo(90, y + 7)..quadraticBezierTo(50, y + 14, 10, y + 7)..close(), _f(const Color(0xFF4A3B5C)));
        }
        c.restore();
        c.drawOval(bd, _l(_d(col), 1.7));
        c.drawPath(Path()..moveTo(50, 93)..lineTo(46, 100)..lineTo(54, 100)..close(), _f(ink));
        _face(c, const Offset(50, 56), 12);
        break;
      case 'pajarito':
        final wf = .3 * sin(t * 4 * pi);
        _shape(c, Path()..moveTo(26, 56)..lineTo(4, 46)..lineTo(8, 58)..lineTo(2, 66)..lineTo(28, 66)..close(), dk);
        _blob(c, Rect.fromCenter(center: const Offset(46, 62), width: 62, height: 48), col);
        c.drawOval(Rect.fromCenter(center: const Offset(48, 73), width: 38, height: 22), _f(_w(col, .6)));
        c.save();
        c.translate(40, 58);
        c.rotate(-.2 - wf);
        _blob(c, Rect.fromCenter(center: const Offset(-4, 4), width: 32, height: 19), dk);
        c.restore();
        _blob(c, Rect.fromCenter(center: const Offset(68, 42), width: 36, height: 34), col);
        _shape(c, Path()..moveTo(83, 40)..lineTo(96, 45)..lineTo(83, 50)..close(), const Color(0xFFFF9F43));
        c.drawOval(Rect.fromCenter(center: const Offset(73, 40), width: 9, height: 11), _f(ink));
        c.drawCircle(const Offset(71.6, 37.6), 2.8, _f(Colors.white));
        c.drawCircle(const Offset(74.6, 42.4), 1.3, _f(Colors.white));
        c.drawOval(Rect.fromCenter(center: const Offset(66, 49), width: 9, height: 6), _f(const Color(0x77FF6F9F)));
        for (final a in [-.5, 0.0, .5]) {
          c.drawPath(Path()..moveTo(66, 26)..quadraticBezierTo(66 + a * 16, 14, 66 + a * 22, 18), _l(dk, 2.2));
        }
        for (int k = 0; k < 5; k++) {
          c.drawCircle(Offset(56 + 4.6 * cos(k * 1.2566 - 1.2), 24 + 4.6 * sin(k * 1.2566 - 1.2)), 2.8, _f(const Color(0xFFFF8FB8)));
        }
        c.drawCircle(const Offset(56, 24), 2, _f(const Color(0xFFFFE066)));
        c.drawLine(const Offset(40, 84), const Offset(40, 92), _l(const Color(0xFFFF9F43), 2.6));
        c.drawLine(const Offset(54, 84), const Offset(54, 92), _l(const Color(0xFFFF9F43), 2.6));
        break;
      default: // pollito en su huevo
        c.drawPath(Path()..moveTo(46, 25)..quadraticBezierTo(44, 12, 40, 14), _l(dk, 2.6));
        c.drawPath(Path()..moveTo(50, 24)..quadraticBezierTo(50, 8, 53, 9), _l(dk, 2.6));
        c.drawPath(Path()..moveTo(54, 25)..quadraticBezierTo(58, 12, 62, 14), _l(dk, 2.6));
        _blob(c, Rect.fromCenter(center: const Offset(50, 54), width: 64, height: 62), col);
        final fl2 = .2 * sin(t * 2 * pi);
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50 + d * 32, 58);
          c.rotate(d * (.3 + fl2));
          _blob(c, Rect.fromCenter(center: Offset.zero, width: 14, height: 26), dk);
          c.restore();
        }
        _shape(c, Path()..moveTo(50, 52)..lineTo(44, 58)..lineTo(56, 58)..close(), const Color(0xFFFF9F43));
        _face(c, const Offset(50, 46), 12);
        final shell = Path()
          ..moveTo(12, 66)
          ..lineTo(21, 74)
          ..lineTo(30, 65)
          ..lineTo(39, 74)
          ..lineTo(48, 65)
          ..lineTo(57, 74)
          ..lineTo(66, 65)
          ..lineTo(75, 74)
          ..lineTo(84, 65)
          ..lineTo(88, 66)
          ..lineTo(86, 90)
          ..quadraticBezierTo(50, 100, 14, 90)
          ..close();
        c.drawPath(shell, _f(const Color(0xFFFFFBF2)));
        c.drawPath(shell, _l(const Color(0xFFD9C9B0), 1.6));
        c.drawPath(Path()..moveTo(70, 18)..lineTo(78, 12)..lineTo(78, 26)..close(), _f(const Color(0xFFFF8FB8)));
        c.drawPath(Path()..moveTo(86, 18)..lineTo(78, 12)..lineTo(78, 26)..close(), _f(const Color(0xFFFF8FB8)));
        c.drawCircle(const Offset(78, 19), 3, _f(const Color(0xFFE8587F)));
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

// ---------------------------------------------------------------- escenario: mascotas alrededor del animal
class PetStage extends StatefulWidget {
  final Widget child;
  final Color ink;
  final VoidCallback onStart;
  const PetStage({super.key, required this.child, required this.ink, required this.onStart});
  @override
  State<PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<PetStage> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  Timer? _t;
  Timer? _hide;
  Timer? _shake;
  String? msg;
  Pet? who;
  bool shaking = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 25), (_) => _speak());
    Future.delayed(const Duration(milliseconds: 2500), _speak);
  }

  @override
  void dispose() {
    _c.dispose();
    _t?.cancel();
    _hide?.cancel();
    _shake?.cancel();
    super.dispose();
  }

  Future<void> _buzz() async {
    for (int i = 0; i < 4; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
    }
  }

  void _speak([Pet? p]) {
    if (!mounted) return;
    final l = loadPets();
    if (l.isEmpty) return;
    final pet = p ?? l[Random().nextInt(l.length)];
    setState(() {
      who = pet;
      msg = petPhrase(pet);
      shaking = true;
    });
    _buzz();
    _shake?.cancel();
    _shake = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => shaking = false);
    });
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => msg = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pets = loadPets().take(4).toList();
    return Column(children: [
      SizedBox(
        height: 230,
        child: LayoutBuilder(
          builder: (_, box) => AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final w = box.maxWidth;
              return Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(child: widget.child),
                for (int i = 0; i < pets.length; i++) _pet(pets[i], i, pets.length, w),
              ]);
            },
          ),
        ),
      ),
      if (msg != null) ...[
        ComicBubble(text: '${who?.name ?? ''}: $msg'),
        FilledButton.tonal(
            onPressed: () {
              setState(() => msg = null);
              widget.onStart();
            },
            child: const Text('¡Empezar sesión! 🚀')),
      ],
      if (pets.isEmpty)
        ActionChip(
            label: const Text('🐾 Crear mascota ayudante'),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PetsScreen()));
              if (mounted) setState(() {});
            }),
    ]);
  }

  Widget _pet(Pet p, int i, int n, double w) {
    final dir = i.isEven ? 1.0 : -1.0;
    final a = 2 * pi * (dir * _c.value + i / max(1, n));
    final rx = min(w / 2 - 30, 150.0) * (i.isEven ? 1.0 : 0.82);
    final ry = 92.0 * (i.isEven ? 0.85 : 1.0);
    var x = w / 2 + rx * cos(a) - 30;
    var y = 115 + ry * sin(a) * 0.95 - 30 + 6 * sin(2 * pi * (3 * _c.value + i));
    if (shaking && who?.id == p.id) {
      x += 3.5 * sin(_c.value * 2 * pi * 120);
      y += 2.5 * cos(_c.value * 2 * pi * 140);
    }
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => _speak(p),
        child: PetSprite(kind: p.kind, color: Color(p.color), size: 60),
      ),
    );
  }
}

// ---------------------------------------------------------------- pantallas
class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});
  @override
  State<PetsScreen> createState() => _PetsState();
}

class _PetsState extends State<PetsScreen> {
  List<Pet> pets = loadPets();
  bool remOn = store.p.getBool('pet_rem_on') ?? false;
  int every = store.p.getInt('pet_rem_min') ?? 120;
  int from = store.p.getInt('pet_sleep_from') ?? 23 * 60;
  int to = store.p.getInt('pet_sleep_to') ?? 8 * 60;

  String _hm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  String _every(int m) => m < 60 ? '$m min' : (m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60} min');

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

  Future<void> _edit([Pet? p]) async {
    final r = await Navigator.push<Pet>(context, MaterialPageRoute(builder: (_) => _PetEditor(pet: p)));
    if (r == null) return;
    final i = pets.indexWhere((x) => x.id == r.id);
    setState(() {
      if (i >= 0) {
        pets[i] = r;
      } else {
        pets.add(r);
      }
    });
    savePets(pets);
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mascotas ayudantes 🐾')),
        floatingActionButton: pets.length >= 4
            ? null
            : FloatingActionButton.extended(
                onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Crear mascota')),
        body: ListView(children: [
          _remCard(),
          if (pets.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Crea una mascota que te anime con frases para empezar otra sesión de estudio (hasta 4).',
                    textAlign: TextAlign.center)),
          for (final p in pets)
            ListTile(
              leading: PetSprite(kind: p.kind, color: Color(p.color), size: 56),
              title: Text(p.name),
              subtitle: Text('${petLabels[p.kind]} · ${p.phrases.isEmpty ? 'frases por defecto' : '${p.phrases.length} frases'}'),
              onTap: () => _edit(p),
              trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() => pets.remove(p));
                    savePets(pets);
                  }),
            ),
          const SizedBox(height: 80),
        ]),
      );
}

// repertorio de frases creadas (el de 💬)
List<String> _repertoire() => loadPhrases();

class _PetEditor extends StatefulWidget {
  final Pet? pet;
  const _PetEditor({this.pet});
  @override
  State<_PetEditor> createState() => _PetEditorState();
}

class _PetEditorState extends State<_PetEditor> {
  late String kind = widget.pet?.kind ?? 'mariposa';
  late int color = widget.pet?.color ?? petDefaultColor['mariposa']!;
  late final name = TextEditingController(text: widget.pet?.name ?? petDefaultName['mariposa']!);
  late final Set<String> chosen = {...(widget.pet?.phrases ?? <String>[])};
  late final List<String> rep = [..._repertoire(), ...chosen.where((x) => !_repertoire().contains(x))];

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tu mascota ✨')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: PetSprite(kind: kind, color: Color(color), size: 130)),
          Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
            for (final k in petKinds)
              ChoiceChip(
                  label: Text(petLabels[k]!),
                  selected: kind == k,
                  onSelected: (_) => setState(() {
                        if (name.text == petDefaultName[kind]) name.text = petDefaultName[k]!;
                        kind = k;
                        color = petDefaultColor[k]!;
                      })),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (final c in petPalette)
              GestureDetector(
                onTap: () => setState(() => color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: color == c ? Colors.black : Colors.black26, width: color == c ? 3 : 1)),
                ),
              ),
          ]),
          TextField(controller: name, maxLength: 16, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 4),
          Row(children: [
            const Expanded(
                child: Text('Sus frases (de tu repertorio 💬)', style: TextStyle(fontWeight: FontWeight.w700))),
            TextButton(onPressed: () => setState(() => chosen.addAll(rep)), child: const Text('Todas')),
            TextButton(onPressed: () => setState(chosen.clear), child: const Text('Ninguna')),
          ]),
          const Text('Sin elegir ninguna usará frases motivadoras por defecto',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          for (final f in rep)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: chosen.contains(f),
              title: Text(f),
              onChanged: (v) => setState(() => v == true ? chosen.add(f) : chosen.remove(f)),
            ),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () {
                Navigator.pop(
                    context,
                    Pet(widget.pet?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), kind,
                        name.text.trim().isEmpty ? 'Mascota' : name.text.trim(), color,
                        [for (final f in rep) if (chosen.contains(f)) f]));
              },
              child: const Text('Guardar')),
        ]),
      );
}
