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

void savePets(List<Pet> l) => store.p.setString('pets', jsonEncode([for (final p in l) p.toJson()]));

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
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
            size: Size.square(widget.size), painter: _PetPainter(widget.kind, widget.color, _c.value)),
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
    ..strokeCap = StrokeCap.round;

  void _face(Canvas c, Offset o, double s, {Color eye = ink}) {
    for (final d in [-1.0, 1.0]) {
      c.drawOval(Rect.fromCenter(center: o + Offset(d * s, 0), width: 9, height: 11), _f(eye));
      c.drawCircle(o + Offset(d * s - 1.5, -2.5), 2.2, _f(Colors.white));
      c.drawCircle(o + Offset(d * (s + 8), 6), 4, _f(const Color(0x66FF6F9F)));
    }
    c.drawArc(Rect.fromCenter(center: o + const Offset(0, 6), width: 8, height: 6), 0.2, pi - 0.4, false,
        _l(ink, 1.5));
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100, size.height / 100);
    final dk = Color.lerp(col, Colors.black, .3)!;
    final lt = Color.lerp(col, Colors.white, .5)!;
    c.drawOval(Rect.fromCenter(center: const Offset(50, 95), width: 44, height: 7), _f(const Color(0x22000000)));
    final hop = sin(t * 2 * pi).abs();
    c.translate(0, -8 * hop);
    switch (kind) {
      case 'mariposa':
        final fm = 0.3 + 0.7 * sin(t * 4 * pi).abs();
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50, 56);
          c.scale(d * fm, 1);
          final up = Path()
            ..moveTo(0, -6)
            ..cubicTo(32, -54, 62, -20, 40, 8)
            ..cubicTo(26, 14, 10, 6, 0, 0)
            ..close();
          final lo = Path()
            ..moveTo(0, 0)
            ..cubicTo(30, 6, 52, 30, 34, 46)
            ..cubicTo(18, 54, 4, 32, 0, 10)
            ..close();
          c.drawPath(up, _f(col));
          c.drawPath(lo, _f(lt));
          c.drawPath(up, _l(dk, 1.6));
          c.drawPath(lo, _l(dk, 1.6));
          c.drawCircle(const Offset(30, -22), 6, _f(const Color(0xCCFFFFFF)));
          c.drawCircle(const Offset(22, 30), 4, _f(col));
          c.restore();
        }
        c.drawOval(Rect.fromCenter(center: const Offset(50, 62), width: 9, height: 38), _f(dk));
        c.drawCircle(const Offset(50, 38), 10, _f(lt));
        c.drawPath(Path()..moveTo(47, 30)..quadraticBezierTo(42, 16, 36, 14), _l(dk, 2));
        c.drawPath(Path()..moveTo(53, 30)..quadraticBezierTo(58, 16, 64, 14), _l(dk, 2));
        c.drawCircle(const Offset(36, 14), 2.4, _f(dk));
        c.drawCircle(const Offset(64, 14), 2.4, _f(dk));
        for (final d in [-1.0, 1.0]) {
          c.drawCircle(Offset(50 + d * 4, 38), 2.2, _f(ink));
          c.drawCircle(Offset(50 + d * 4 - .8, 37), .8, _f(Colors.white));
          c.drawCircle(Offset(50 + d * 7.5, 42), 2, _f(const Color(0x66FF6F9F)));
        }
        c.drawArc(Rect.fromCenter(center: const Offset(50, 42), width: 5, height: 4), 0.2, pi - 0.4, false, _l(ink, 1));
        break;
      case 'buho':
        c.drawPath(Path()..moveTo(26, 26)..lineTo(32, 6)..lineTo(46, 22)..close(), _f(dk));
        c.drawPath(Path()..moveTo(74, 26)..lineTo(68, 6)..lineTo(54, 22)..close(), _f(dk));
        c.drawOval(Rect.fromCenter(center: const Offset(50, 58), width: 64, height: 70), _f(col));
        c.drawOval(Rect.fromCenter(center: const Offset(50, 70), width: 38, height: 44), _f(lt));
        for (final y in [62.0, 72.0, 82.0]) {
          c.drawArc(Rect.fromCenter(center: Offset(50, y), width: 14, height: 8), 0.3, pi - 0.6, false, _l(dk.withAlpha(120), 1.4));
        }
        final fl = 0.18 * sin(t * 2 * pi);
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50 + d * 33, 62);
          c.rotate(d * (0.15 + fl));
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: 15, height: 40), _f(dk));
          c.restore();
          c.drawCircle(Offset(50 + d * 12, 40), 12.5, _f(Colors.white));
          c.drawCircle(Offset(50 + d * 12, 41), 6, _f(ink));
          c.drawCircle(Offset(50 + d * 12 - 2, 38.5), 2.2, _f(Colors.white));
          c.drawCircle(Offset(50 + d * 28, 52), 3.6, _f(const Color(0x66FF6F9F)));
        }
        c.drawPath(Path()..moveTo(50, 46)..lineTo(44.5, 54)..lineTo(55.5, 54)..close(), _f(const Color(0xFFFF9F43)));
        c.drawLine(const Offset(42, 94), const Offset(42, 90), _l(const Color(0xFFFF9F43), 3));
        c.drawLine(const Offset(58, 94), const Offset(58, 90), _l(const Color(0xFFFF9F43), 3));
        break;
      case 'abeja':
        final fw = 0.6 + 0.4 * sin(t * 6 * pi).abs();
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50 + d * 14, 34);
          c.rotate(d * 0.5);
          c.drawOval(Rect.fromCenter(center: Offset(0, -9 * fw), width: 18, height: 26 * fw), _f(const Color(0xCCFFFFFF)));
          c.drawOval(Rect.fromCenter(center: Offset(0, -9 * fw), width: 18, height: 26 * fw), _l(const Color(0xFFB9D8F0), 1));
          c.restore();
        }
        c.drawPath(Path()..moveTo(40, 30)..quadraticBezierTo(34, 12, 26, 14), _l(ink, 2));
        c.drawPath(Path()..moveTo(60, 30)..quadraticBezierTo(66, 12, 74, 14), _l(ink, 2));
        c.drawCircle(const Offset(26, 14), 2.6, _f(ink));
        c.drawCircle(const Offset(74, 14), 2.6, _f(ink));
        final bd = Rect.fromCenter(center: const Offset(50, 62), width: 66, height: 56);
        c.drawOval(bd, _f(col));
        c.save();
        c.clipPath(Path()..addOval(bd));
        for (final y in [66.0, 78.0]) {
          c.drawRect(Rect.fromLTWH(10, y, 80, 6), _f(ink));
        }
        c.restore();
        c.drawPath(Path()..moveTo(50, 92)..lineTo(46, 99)..lineTo(54, 99)..close(), _f(ink));
        _face(c, const Offset(50, 52), 11);
        break;
      case 'pajarito':
        final wf = 0.3 * sin(t * 4 * pi);
        c.drawPath(Path()..moveTo(26, 56)..lineTo(4, 46)..lineTo(8, 58)..lineTo(2, 66)..lineTo(28, 66)..close(), _f(dk));
        c.drawOval(Rect.fromCenter(center: const Offset(46, 62), width: 60, height: 46), _f(col));
        c.drawOval(Rect.fromCenter(center: const Offset(48, 72), width: 36, height: 22), _f(lt));
        c.save();
        c.translate(40, 58);
        c.rotate(-0.2 - wf);
        c.drawOval(Rect.fromCenter(center: const Offset(-4, 4), width: 32, height: 18), _f(dk));
        c.restore();
        c.drawCircle(const Offset(68, 42), 17, _f(col));
        c.drawPath(Path()..moveTo(82, 40)..lineTo(95, 45)..lineTo(82, 49)..close(), _f(const Color(0xFFFF9F43)));
        c.drawCircle(const Offset(72, 38), 3.6, _f(ink));
        c.drawCircle(const Offset(73, 36.8), 1.2, _f(Colors.white));
        c.drawCircle(const Offset(66, 48), 3.6, _f(const Color(0x66FF6F9F)));
        c.drawPath(Path()..moveTo(64, 27)..quadraticBezierTo(62, 16, 68, 18), _l(dk, 2.4));
        c.drawLine(const Offset(40, 84), const Offset(40, 91), _l(const Color(0xFFFF9F43), 2.6));
        c.drawLine(const Offset(54, 84), const Offset(54, 91), _l(const Color(0xFFFF9F43), 2.6));
        break;
      default: // pollito
        c.drawPath(Path()..moveTo(46, 30)..quadraticBezierTo(44, 18, 40, 20), _l(dk, 2.6));
        c.drawPath(Path()..moveTo(50, 29)..quadraticBezierTo(50, 14, 52, 14), _l(dk, 2.6));
        c.drawPath(Path()..moveTo(54, 30)..quadraticBezierTo(58, 18, 62, 20), _l(dk, 2.6));
        c.drawCircle(const Offset(50, 60), 33, _f(col));
        final fl2 = 0.2 * sin(t * 2 * pi);
        for (final d in [-1.0, 1.0]) {
          c.save();
          c.translate(50 + d * 31, 66);
          c.rotate(d * (0.3 + fl2));
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: 14, height: 26), _f(dk));
          c.restore();
        }
        c.drawPath(Path()..moveTo(50, 54)..lineTo(44, 60)..lineTo(56, 60)..close(), _f(const Color(0xFFFF9F43)));
        _face(c, const Offset(50, 48), 12);
        c.drawLine(const Offset(42, 94), const Offset(42, 90), _l(const Color(0xFFFF9F43), 3));
        c.drawLine(const Offset(58, 94), const Offset(58, 90), _l(const Color(0xFFFF9F43), 3));
        break;
    }
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
    var x = w / 2 + rx * cos(a) - 26;
    var y = 115 + ry * sin(a) * 0.95 - 26 + 6 * sin(2 * pi * (3 * _c.value + i));
    if (shaking && who?.id == p.id) {
      x += 3.5 * sin(_c.value * 2 * pi * 120);
      y += 2.5 * cos(_c.value * 2 * pi * 140);
    }
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => _speak(p),
        child: PetSprite(kind: p.kind, color: Color(p.color), size: 52),
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mascotas ayudantes 🐾')),
        floatingActionButton: pets.length >= 4
            ? null
            : FloatingActionButton.extended(
                onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Crear mascota')),
        body: pets.isEmpty
            ? const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'Crea una mascota que te anime con frases para empezar otra sesión de estudio (hasta 4).',
                        textAlign: TextAlign.center)))
            : ListView(children: [
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
              ]),
      );
}

const _baseDefaults = [
  '¡Tú puedes! Ya llevas parte del camino 💪',
  'Respira. Un poco más y lo logras ✨',
  'Tu yo del futuro te dará las gracias 💖',
  'Ahora no toca el móvil, toca brillar 🌟',
];

// repertorio de frases creadas (el de 💬)
List<String> _repertoire() => List<String>.from(store.p.getStringList('phrases') ?? _baseDefaults);

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
