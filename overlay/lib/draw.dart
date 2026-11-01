import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'data.dart';

// ---------- plantillas: objetos limpios en una cuadrícula de 100x100 ----------
Color _dk(Color c) => Color.lerp(c, Colors.black, 0.35)!;
Color _lt(Color c) => Color.lerp(c, Colors.white, 0.45)!;

void _sh(Canvas c, Path p, Color col, bool solid) {
  c.drawPath(p, Paint()..color = solid ? Colors.black : col);
  if (!solid) {
    c.drawPath(
        p,
        Paint()
          ..color = _dk(col)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round);
  }
}

void _rr(Canvas c, double x, double y, double w, double h, double r, Color col, bool s) =>
    _sh(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r))), col, s);

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

void _line(Canvas c, double x1, double y1, double x2, double y2, Color col, double w) => c.drawLine(
    Offset(x1, y1),
    Offset(x2, y2),
    Paint()
      ..color = col
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round);

class _Tpl {
  final String id, name, kind, slot;
  final void Function(Canvas c, Color b, bool s) draw;
  const _Tpl(this.id, this.name, this.kind, this.slot, this.draw);
}

void _beanie(Canvas c, Color b, bool s) {
  _sh(c, Path()..moveTo(14, 64)..cubicTo(12, 14, 88, 14, 86, 64)..close(), b, s);
  if (!s) {
    for (final x in [32.0, 50.0, 68.0]) {
      _line(c, x, 26 + (x - 50).abs() * 0.3, x, 60, _dk(b).withAlpha(90), 2);
    }
  }
  _rr(c, 8, 60, 84, 24, 8, _lt(b), s);
  _ci(c, 50, 12, 10, _lt(b), s);
}

void _topHat(Canvas c, Color b, bool s) {
  _rr(c, 28, 12, 44, 54, 6, b, s);
  _rr(c, 6, 62, 88, 16, 8, b, s);
  if (!s) _rr(c, 28, 50, 44, 10, 2, _dk(b), false);
}

void _crown(Canvas c, Color b, bool s) {
  _sh(c, _poly([10, 78, 10, 28, 30, 50, 50, 20, 70, 50, 90, 28, 90, 78]), b, s);
  if (!s) {
    _rr(c, 10, 66, 80, 12, 3, _lt(b), false);
    for (final x in [30.0, 50.0, 70.0]) {
      _ci(c, x, 58, 4, const Color(0xFFE8445A), false);
    }
  }
}

void _shirt(Canvas c, Color b, bool s) {
  _sh(c, _poly([30, 10, 8, 30, 20, 46, 32, 38, 32, 90, 68, 90, 68, 38, 80, 46, 92, 30, 70, 10, 50, 22]), b, s);
  if (!s) {
    c.drawPath(
        Path()..moveTo(32, 10)..quadraticBezierTo(50, 32, 68, 10),
        Paint()
          ..color = _dk(b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
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
  _rr(c, 4, 26, 92, 28, 12, b, s);
  _rr(c, 58, 46, 24, 50, 8, b, s);
  if (!s) {
    for (final x in [20.0, 38.0, 56.0, 74.0]) {
      _line(c, x, 28, x, 52, _lt(b), 4);
    }
    _line(c, 60, 78, 80, 78, _lt(b), 4);
  }
}

void _cape(Canvas c, Color b, bool s) {
  _sh(c, Path()..moveTo(30, 6)..quadraticBezierTo(50, 0, 70, 6)..lineTo(96, 94)..quadraticBezierTo(50, 80, 4, 94)..close(), b, s);
  if (!s) _ci(c, 50, 10, 5, _lt(b), false);
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
  _rr(c, 20, 12, 60, 78, 22, b, s);
  _rr(c, 30, 54, 40, 28, 10, _lt(b), s);
  if (!s) _line(c, 34, 36, 66, 36, _dk(b), 3);
}

void _wand(Canvas c, Color b, bool s) {
  _sh(c, _poly([16, 86, 22, 94, 72, 44, 66, 38]), b, s);
  _sh(c, _star(76, 24, 20, 9), s ? Colors.black : const Color(0xFFFFD43B), s);
}

void _apple(Canvas c, Color b, bool s) {
  final p = Path.combine(
      ui.PathOperation.union,
      Path()..addOval(Rect.fromCircle(center: const Offset(37, 58), radius: 26)),
      Path()..addOval(Rect.fromCircle(center: const Offset(63, 58), radius: 26)));
  _sh(c, p, b, s);
  _line(c, 50, 34, 53, 16, s ? Colors.black : const Color(0xFF8B5A3C), 4);
  _sh(c, Path()..moveTo(54, 22)..quadraticBezierTo(70, 6, 82, 18)..quadraticBezierTo(68, 30, 54, 22), s ? Colors.black : const Color(0xFF4FA765), s);
}

void _pizza(Canvas c, Color b, bool s) {
  _sh(c, Path()..moveTo(8, 26)..quadraticBezierTo(50, 4, 92, 26)..lineTo(50, 94)..close(), const Color(0xFFFFD27A), s);
  if (!s) {
    c.drawPath(
        Path()..moveTo(8, 26)..quadraticBezierTo(50, 4, 92, 26),
        Paint()
          ..color = const Color(0xFFC98B4A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);
    for (final o in [const Offset(38, 40), const Offset(60, 44), const Offset(49, 64)]) {
      _ci(c, o.dx, o.dy, 7, b, false);
    }
  }
}

void _ice(Canvas c, Color b, bool s) {
  _sh(c, _poly([28, 46, 72, 46, 50, 96]), const Color(0xFFE0A96D), s);
  _ci(c, 50, 34, 24, b, s);
  _ci(c, 56, 8, 6, const Color(0xFFE8445A), s);
}

const _tpls = <_Tpl>[
  _Tpl('beanie', 'Gorro', 'acc', 'head', _beanie),
  _Tpl('tophat', 'Sombrero', 'acc', 'head', _topHat),
  _Tpl('crown', 'Corona', 'acc', 'head', _crown),
  _Tpl('shirt', 'Camiseta', 'acc', 'body', _shirt),
  _Tpl('glasses', 'Gafas', 'acc', 'eyes', _glasses),
  _Tpl('bow', 'Pajarita', 'acc', 'neck', _bow),
  _Tpl('scarf', 'Bufanda', 'acc', 'neck', _scarf),
  _Tpl('cape', 'Capa', 'acc', 'back', _cape),
  _Tpl('wings', 'Alas', 'acc', 'back', _wings),
  _Tpl('pack', 'Mochila', 'acc', 'back', _pack),
  _Tpl('wand', 'Varita', 'acc', 'hand', _wand),
  _Tpl('apple', 'Manzana', 'food', '', _apple),
  _Tpl('pizza', 'Pizza', 'food', '', _pizza),
  _Tpl('ice', 'Helado', 'food', '', _ice),
];

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

Future<Uint8List> _render(_Tpl t, Color col) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.scale(2.56);
  t.draw(c, col, false);
  final img = await rec.endRecording().toImage(256, 256);
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

/// Haz un boceto (aunque sea tosco): se transforma en el objeto que más se le parece.
class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});
  @override
  State<DrawScreen> createState() => _DrawState();
}

class _DrawState extends State<DrawScreen> {
  static const palette = [
    Color(0xFFE8445A), Color(0xFFFF8A3D), Color(0xFFFFD43B), Color(0xFF4FA765),
    Color(0xFF3F9BE0), Color(0xFF8E5BD9), Color(0xFFFF8FB8), Color(0xFF8B5A3C),
    Color(0xFF4A3B5C), Color(0xFFFFFFFF),
  ];
  final List<_Stroke> strokes = [];
  Color color = palette[0];
  double width = 12;
  String kind = 'acc';
  List<_Tpl> ranked = [];
  _Tpl? pick;
  Uint8List? preview;
  int _job = 0;
  final nameCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  void _msg(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _recognize() async {
    final job = ++_job;
    if (strokes.isEmpty) {
      setState(() {
        ranked = [];
        pick = null;
        preview = null;
      });
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
    for (final t in _tpls.where((t) => t.kind == kind)) {
      final h = tg[t.id]!;
      final arT = h[_G * _G] / h[_G * _G + 1];
      sc[t] = _overlap(g.sublist(0, _G * _G), h.sublist(0, _G * _G)) * exp(-0.9 * (log(arS / arT)).abs());
    }
    final r = sc.keys.toList()..sort((a, b) => sc[b]!.compareTo(sc[a]!));
    ranked = r;
    await _choose(r.first);
  }

  Future<void> _choose(_Tpl t) async {
    final b = await _render(t, color);
    if (!mounted) return;
    setState(() {
      pick = t;
      preview = b;
    });
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
      _msg('Primero haz un boceto');
      return;
    }
    final name = nameCtrl.text.trim().isEmpty ? t.name : nameCtrl.text.trim();
    store.addCustom(name, t.kind, t.kind == 'acc' ? t.slot : '', await _render(t, color));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final side = min(MediaQuery.of(context).size.width - 16, 440.0);
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo dibujo ✏️')),
      body: Column(children: [
        const SizedBox(height: 8),
        Container(
          width: side,
          height: side,
          decoration: BoxDecoration(color: const Color(0xFFF2EEF8), borderRadius: BorderRadius.circular(12)),
          foregroundDecoration: BoxDecoration(
              border: Border.all(color: kInk, width: 2), borderRadius: BorderRadius.circular(12)),
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
              child: CustomPaint(size: Size(side, side), painter: _DrawPainter(strokes)),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Trazo'),
              SizedBox(
                  width: 150,
                  child: Slider(value: width, min: 6, max: 26, onChanged: (v) => setState(() => width = v))),
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
            const Center(
              child: Text('Dibuja la silueta (gorro, camiseta, gafas, corona, manzana…) aunque salga tosca',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                  label: const Text('Complemento'),
                  selected: kind == 'acc',
                  onSelected: (_) {
                    kind = 'acc';
                    _recognize();
                  }),
              ChoiceChip(
                  label: const Text('Comida'),
                  selected: kind == 'food',
                  onSelected: (_) {
                    kind = 'food';
                    _recognize();
                  }),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final c in palette)
                GestureDetector(
                  onTap: () {
                    setState(() => color = c);
                    if (pick != null) _choose(pick!);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color == c ? Colors.black : Colors.black26, width: color == c ? 3 : 1)),
                  ),
                ),
            ]),
            if (preview != null && pick != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                Container(
                    color: const Color(0xFFF2EEF8),
                    child: Image.memory(preview!, width: 96, height: 96)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Parece: ${pick!.name} ✨\nSi no es, toca otra opción:',
                        style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
              Wrap(spacing: 8, children: [
                for (final t in ranked)
                  ChoiceChip(label: Text(t.name), selected: pick == t, onSelected: (_) => _choose(t)),
              ]),
            ],
            TextField(
                controller: nameCtrl,
                maxLength: 24,
                decoration: const InputDecoration(labelText: 'Nombre (opcional)')),
            FilledButton(onPressed: _save, child: const Text('Añadir a la tienda 🛒')),
          ]),
        ),
      ]),
    );
  }
}
