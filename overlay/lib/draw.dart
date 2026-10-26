import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'data.dart';
import 'icons.dart';

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> pts = [];
  _Stroke(this.color, this.width);
}

void _paintStrokes(Canvas c, List<_Stroke> ss, {bool solid = false, double extra = 0}) {
  for (final s in ss) {
    final col = solid ? Colors.black : s.color;
    final w = s.width + extra;
    if (s.pts.length == 1) {
      c.drawCircle(s.pts.first, w / 2, Paint()..color = col);
      continue;
    }
    final path = Path()..moveTo(s.pts.first.dx, s.pts.first.dy);
    for (final q in s.pts.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    c.drawPath(
        path,
        Paint()
          ..color = col
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke);
  }
}

class _DrawPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _DrawPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size s) {
    final g = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1;
    for (double x = 0; x <= s.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), g);
      canvas.drawLine(Offset(0, x), Offset(s.width, x), g);
    }
    canvas.save();
    canvas.clipRect(Offset.zero & s);
    _paintStrokes(canvas, strokes);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DrawPainter o) => true;
}

class _TplPainter extends CustomPainter {
  final IconTpl t;
  final Color color;
  _TplPainter(this.t, this.color);
  @override
  void paint(Canvas canvas, Size s) => paintTpl(canvas, s, t, color);
  @override
  bool shouldRepaint(_TplPainter o) => o.t != t || o.color != color;
}

/// Silueta rellena de lo dibujado (rejilla n x n).
class _Shape {
  final int n;
  final List<bool> fill;
  final int x0, y0, w, h;
  _Shape(this.n, this.fill, this.x0, this.y0, this.w, this.h);
}

List<Offset> _hull(List<Offset> pts) {
  pts.sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  double cross(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  final lo = <Offset>[];
  for (final p in pts) {
    while (lo.length >= 2 && cross(lo[lo.length - 2], lo.last, p) <= 0) {
      lo.removeLast();
    }
    lo.add(p);
  }
  final up = <Offset>[];
  for (final p in pts.reversed) {
    while (up.length >= 2 && cross(up[up.length - 2], up.last, p) <= 0) {
      up.removeLast();
    }
    up.add(p);
  }
  lo.removeLast();
  up.removeLast();
  return [...lo, ...up];
}

/// Pantalla para dibujar un artículo; la silueta se convierte en un icono completo.
class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});
  @override
  State<DrawScreen> createState() => _DrawState();
}

class _DrawState extends State<DrawScreen> {
  static const double side = 280;
  static const palette = [
    Color(0xFF4A3B5C), Color(0xFFE8445A), Color(0xFFFF8A3D), Color(0xFFFFD43B),
    Color(0xFF4FA765), Color(0xFF3F9BE0), Color(0xFF8E5BD9), Color(0xFFFF8FB8),
    Color(0xFF8B5A3C), Color(0xFFFFFFFF),
  ];
  final List<_Stroke> strokes = [];
  Color color = palette[1];
  double width = 6;
  String kind = 'acc';
  String slot = 'head';
  final nameCtrl = TextEditingController();

  _Shape? shape;
  IconTpl? tpl; // icono elegido (null = mi dibujo relleno)
  Uint8List? result; // PNG final ya convertido
  bool busy = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Rect _bounds() {
    double x0 = double.infinity, y0 = double.infinity, x1 = -double.infinity, y1 = -double.infinity;
    for (final s in strokes) {
      for (final q in s.pts) {
        x0 = min(x0, q.dx - s.width);
        y0 = min(y0, q.dy - s.width);
        x1 = max(x1, q.dx + s.width);
        y1 = max(y1, q.dy + s.width);
      }
    }
    return Rect.fromLTRB(x0, y0, x1, y1);
  }

  Future<Uint8List> _png(void Function(Canvas) f) async {
    final rec = ui.PictureRecorder();
    f(Canvas(rec));
    final img = await rec.endRecording().toImage(256, 256);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  // ---- silueta rellena: engrosa el trazo, rellena el interior y, si queda abierta, usa el casco convexo ----
  Future<_Shape> _shapeOf() async {
    const n = 96;
    final b = _bounds();
    final k = (n - 10) / max(max(b.width, b.height), 20);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.translate(n / 2, n / 2);
    c.scale(k);
    c.translate(-b.center.dx, -b.center.dy);
    _paintStrokes(c, strokes, solid: true, extra: 5 / k);
    final img = await rec.endRecording().toImage(n, n);
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final px = bd!.buffer.asUint8List();
    final ink = List<bool>.generate(n * n, (i) => px[i * 4 + 3] > 40);

    final ext = List<bool>.filled(n * n, false);
    final q = <int>[];
    void push(int i) {
      if (!ink[i] && !ext[i]) {
        ext[i] = true;
        q.add(i);
      }
    }

    for (int i = 0; i < n; i++) {
      push(i);
      push((n - 1) * n + i);
      push(i * n);
      push(i * n + n - 1);
    }
    int head = 0;
    while (head < q.length) {
      final i = q[head++];
      final x = i % n, y = i ~/ n;
      if (x > 0) push(i - 1);
      if (x < n - 1) push(i + 1);
      if (y > 0) push(i - n);
      if (y < n - 1) push(i + n);
    }
    var fill = List<bool>.generate(n * n, (i) => !ext[i]);

    int ix0 = n, iy0 = n, ix1 = 0, iy1 = 0;
    final pts = <Offset>[];
    for (int i = 0; i < n * n; i++) {
      if (!ink[i]) continue;
      final x = i % n, y = i ~/ n;
      ix0 = min(ix0, x);
      iy0 = min(iy0, y);
      ix1 = max(ix1, x);
      iy1 = max(iy1, y);
      pts.add(Offset(x + 0.5, y + 0.5));
    }
    final area = (ix1 - ix0 + 1) * (iy1 - iy0 + 1);
    if (fill.where((v) => v).length < 0.3 * area && pts.length > 3) {
      final hp = Path()..addPolygon(_hull(pts), true);
      fill = List<bool>.generate(n * n, (i) => hp.contains(Offset(i % n + 0.5, i ~/ n + 0.5)));
    }
    int fx0 = n, fy0 = n, fx1 = 0, fy1 = 0;
    for (int i = 0; i < n * n; i++) {
      if (!fill[i]) continue;
      fx0 = min(fx0, i % n);
      fy0 = min(fy0, i ~/ n);
      fx1 = max(fx1, i % n);
      fy1 = max(fy1, i ~/ n);
    }
    return _Shape(n, fill, fx0, fy0, max(fx1 - fx0 + 1, 1), max(fy1 - fy0 + 1, 1));
  }

  List<bool> _sample(_Shape s) => [
        for (int j = 0; j < 32; j++)
          for (int i = 0; i < 32; i++)
            s.fill[(s.y0 + ((j + 0.5) / 32 * s.h).floor()) * s.n +
                (s.x0 + ((i + 0.5) / 32 * s.w).floor())]
      ];

  Future<Uint8List> _renderFill(_Shape sh, Color col) async {
    final n = sh.n;
    final cv = col.toARGB32(), dv = Color.lerp(col, Colors.black, 0.4)!.toARGB32();
    bool f(int x, int y) => x >= 0 && y >= 0 && x < n && y < n && sh.fill[y * n + x];
    final px = Uint8List(n * n * 4);
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (!f(x, y)) continue;
        final edge = !f(x - 1, y) || !f(x + 1, y) || !f(x, y - 1) || !f(x, y + 1) ||
            !f(x - 2, y) || !f(x + 2, y) || !f(x, y - 2) || !f(x, y + 2);
        final v = edge ? dv : cv;
        final i = (y * n + x) * 4;
        px[i] = (v >> 16) & 255;
        px[i + 1] = (v >> 8) & 255;
        px[i + 2] = v & 255;
        px[i + 3] = 255;
      }
    }
    final comp = Completer<ui.Image>();
    ui.decodeImageFromPixels(px, n, n, ui.PixelFormat.rgba8888, comp.complete);
    final small = await comp.future;
    final k = 232 / max(sh.w, sh.h);
    final dw = sh.w * k, dh = sh.h * k;
    return _png((c) => c.drawImageRect(
        small,
        Rect.fromLTWH(sh.x0.toDouble(), sh.y0.toDouble(), sh.w.toDouble(), sh.h.toDouble()),
        Rect.fromLTWH((256 - dw) / 2, (256 - dh) / 2, dw, dh),
        Paint()..filterQuality = FilterQuality.high));
  }

  Future<void> _apply() async {
    final sh = shape;
    if (sh == null) return;
    final t = tpl;
    final bytes = t != null
        ? await _png((c) => paintTpl(c, const Size(256, 256), t, color))
        : await _renderFill(sh, color);
    if (!mounted) return;
    setState(() {
      result = bytes;
      if (t != null) {
        kind = t.kind;
        if (t.slot.isNotEmpty) slot = t.slot;
        if (nameCtrl.text.trim().isEmpty) nameCtrl.text = t.name;
      }
    });
  }

  Future<void> _convert() async {
    if (strokes.isEmpty) {
      _msg('Primero dibuja una silueta');
      return;
    }
    setState(() => busy = true);
    final sh = await _shapeOf();
    final best = bestMatches(_sample(sh), sh.w / sh.h);
    if (!mounted) return;
    setState(() {
      busy = false;
      shape = sh;
    });
    Widget cand(BuildContext ctx, int idx, IconTpl? t) => GestureDetector(
          onTap: () => Navigator.pop(ctx, idx),
          child: SizedBox(
            width: 78,
            child: Column(children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: const Color(0xFFF2EEF8), borderRadius: BorderRadius.circular(12)),
                child: t == null
                    ? const Center(child: Text('🖌️', style: TextStyle(fontSize: 30)))
                    : CustomPaint(painter: _TplPainter(t, color)),
              ),
              const SizedBox(height: 4),
              Text(t?.name ?? 'Mi dibujo relleno',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        );
    final pick = await showModalBottomSheet<int>(
        context: context,
        builder: (ctx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('¿Qué has dibujado?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    for (int i = 0; i < best.length; i++) cand(ctx, i, best[i]),
                    cand(ctx, -1, null),
                  ]),
                ]),
              ),
            ));
    if (pick == null) return;
    tpl = pick >= 0 ? best[pick] : null;
    await _apply();
  }

  Future<void> _save() async {
    final name = nameCtrl.text.trim();
    if (strokes.isEmpty || name.isEmpty) {
      _msg('Dibuja algo y ponle un nombre');
      return;
    }
    Uint8List bytes;
    final r = result;
    if (r != null) {
      bytes = r;
    } else {
      final b = _bounds();
      final k = 240 / max(max(b.width, b.height), 20);
      bytes = await _png((c) {
        c.translate(128, 128);
        c.scale(k);
        c.translate(-b.center.dx, -b.center.dy);
        _paintStrokes(c, strokes);
      });
    }
    store.addCustom(name, kind, kind == 'acc' ? slot : '', bytes);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo dibujo ✏️')),
      body: Column(children: [
        const SizedBox(height: 8),
        Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
              color: const Color(0xFFF2EEF8),
              border: Border.all(color: kInk, width: 2),
              borderRadius: BorderRadius.circular(12)),
          child: GestureDetector(
            onPanStart: (d) => setState(() {
              result = null;
              strokes.add(_Stroke(color, width)..pts.add(d.localPosition));
            }),
            onPanUpdate: (d) => setState(() {
              if (strokes.isNotEmpty) strokes.last.pts.add(d.localPosition);
            }),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(size: const Size(side, side), painter: _DrawPainter(strokes)),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final c in palette)
                GestureDetector(
                  onTap: () {
                    setState(() => color = c);
                    if (result != null) _apply();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color == c ? Colors.black : Colors.black26,
                            width: color == c ? 3 : 1)),
                  ),
                ),
            ]),
            Row(children: [
              const Text('Grosor'),
              Expanded(
                  child: Slider(
                      value: width, min: 2, max: 20, onChanged: (v) => setState(() => width = v))),
              IconButton(
                  onPressed: () => setState(() {
                        if (strokes.isNotEmpty) strokes.removeLast();
                        result = null;
                      }),
                  icon: const Icon(Icons.undo)),
              IconButton(
                  onPressed: () => setState(() {
                        strokes.clear();
                        result = null;
                      }),
                  icon: const Icon(Icons.delete_outline)),
            ]),
            FilledButton.icon(
                onPressed: busy ? null : _convert,
                icon: busy
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: const Text('Convertir silueta en icono ✨')),
            if (result != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF2EEF8), borderRadius: BorderRadius.circular(12)),
                    child: Image.memory(result!, width: 90, height: 90),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Icono listo ✅', style: TextStyle(color: Colors.green.shade700)),
                    TextButton(
                        onPressed: () => setState(() {
                              result = null;
                              tpl = null;
                            }),
                        child: const Text('Volver a mi dibujo')),
                  ]),
                ]),
              ),
            TextField(
                controller: nameCtrl,
                maxLength: 24,
                decoration: const InputDecoration(labelText: 'Nombre del artículo')),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                  label: const Text('Complemento'),
                  selected: kind == 'acc',
                  onSelected: (_) => setState(() => kind = 'acc')),
              ChoiceChip(
                  label: const Text('Comida'),
                  selected: kind == 'food',
                  onSelected: (_) => setState(() => kind = 'food')),
            ]),
            if (kind == 'acc')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(spacing: 8, children: [
                  for (final e in slotNames.entries)
                    ChoiceChip(
                        label: Text('En: ${e.value}'),
                        selected: slot == e.key,
                        onSelected: (_) => setState(() => slot = e.key)),
                ]),
              ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text('Añadir a la tienda 🛒')),
          ]),
        ),
      ]),
    );
  }
}
