import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'data.dart';

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> pts = [];
  _Stroke(this.color, this.width);
}

class _Fill {
  final ui.Image img;
  _Fill(this.img);
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
  final List<_Fill> fills;
  final List<_Stroke> strokes;
  _DrawPainter(this.fills, this.strokes);

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
    for (final f in fills) {
      canvas.drawImage(f.img, Offset.zero, Paint());
    }
    _paintStrokes(canvas, strokes); // los trazos van encima de los rellenos
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DrawPainter o) => true;
}

/// Dibuja el contorno con el lápiz y toca dentro de cada figura para rellenarla con el color elegido.
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
  final List<_Fill> fills = [];
  final List<Object> actions = []; // orden para deshacer
  Color color = palette[1];
  double width = 5;
  bool bucket = false;
  bool real3d = true;
  String kind = 'acc';
  String slot = 'head';
  final nameCtrl = TextEditingController();

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

  Future<Uint8List> _png(int size, void Function(Canvas) f) async {
    final rec = ui.PictureRecorder();
    f(Canvas(rec));
    final img = await rec.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  void _undo() {
    if (actions.isEmpty) return;
    final a = actions.removeLast();
    if (a is _Stroke) {
      strokes.remove(a);
    } else if (a is _Fill) {
      fills.remove(a);
    }
    setState(() {});
  }

  Uint8List _dilate(Uint8List m, int n) {
    final o = Uint8List.fromList(m);
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        final i = y * n + x;
        if (m[i] == 1) continue;
        if ((x > 0 && m[i - 1] == 1) ||
            (x < n - 1 && m[i + 1] == 1) ||
            (y > 0 && m[i - n] == 1) ||
            (y < n - 1 && m[i + n] == 1)) {
          o[i] = 1;
        }
      }
    }
    return o;
  }

  // Relleno interactivo: rellena la figura cerrada donde tocas
  Future<void> _bucket(Offset p) async {
    if (strokes.isEmpty) {
      _msg('Primero dibuja el contorno de una figura');
      return;
    }
    const n = 280;
    final x = p.dx.floor(), y = p.dy.floor();
    if (x < 0 || y < 0 || x >= n || y >= n) return;
    // barrera: trazos algo engrosados para cerrar huecos pequeños
    final rec = ui.PictureRecorder();
    _paintStrokes(Canvas(rec), strokes, solid: true, extra: 4);
    final img = await rec.endRecording().toImage(n, n);
    final px = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
    bool wall(int i) => px[i * 4 + 3] > 100;
    final start = y * n + x;
    if (wall(start)) {
      _msg('Toca dentro de la figura, no sobre el trazo');
      return;
    }
    final reg = Uint8List(n * n);
    final q = <int>[start];
    reg[start] = 1;
    void add(int j) {
      if (reg[j] == 0 && !wall(j)) {
        reg[j] = 1;
        q.add(j);
      }
    }

    var h = 0;
    var leak = false;
    while (h < q.length && !leak) {
      final i = q[h++];
      final cx = i % n, cy = i ~/ n;
      if (cx == 0 || cy == 0 || cx == n - 1 || cy == n - 1 || q.length > n * n * 0.7) leak = true;
      if (cx > 0) add(i - 1);
      if (cx < n - 1) add(i + 1);
      if (cy > 0) add(i - n);
      if (cy < n - 1) add(i + n);
    }
    if (leak) {
      _msg('El contorno no está cerrado: únelo para poder rellenar');
      return;
    }
    var r = reg;
    for (int k = 0; k < 3; k++) {
      r = _dilate(r, n); // el relleno entra por debajo del trazo, sin huecos
    }
    final cv = color.toARGB32();
    final out = Uint8List(n * n * 4);
    for (int i = 0; i < n * n; i++) {
      if (r[i] == 1) {
        out[i * 4] = (cv >> 16) & 255;
        out[i * 4 + 1] = (cv >> 8) & 255;
        out[i * 4 + 2] = cv & 255;
        out[i * 4 + 3] = 255;
      }
    }
    final comp = Completer<ui.Image>();
    ui.decodeImageFromPixels(out, n, n, ui.PixelFormat.rgba8888, comp.complete);
    final f = _Fill(await comp.future);
    if (!mounted) return;
    setState(() {
      fills.add(f);
      actions.add(f);
    });
  }

  Future<Uint8List> _raw(int n, void Function(Canvas) f) async {
    final rec = ui.PictureRecorder();
    f(Canvas(rec));
    final img = await rec.endRecording().toImage(n, n);
    return (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  }

  // distancia de cada píxel interior al borde (chamfer)
  Float32List _dist(Uint8List mask, int n) {
    final d = Float32List(n * n);
    for (int i = 0; i < n * n; i++) {
      d[i] = mask[i] == 1 ? 1e6 : 0.0;
    }
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        final i = y * n + x;
        if (d[i] == 0) continue;
        double v = d[i];
        if (x > 0) v = min(v, d[i - 1] + 1);
        if (y > 0) {
          v = min(v, d[i - n] + 1);
          if (x > 0) v = min(v, d[i - n - 1] + 1.414);
          if (x < n - 1) v = min(v, d[i - n + 1] + 1.414);
        }
        d[i] = v;
      }
    }
    for (int y = n - 1; y >= 0; y--) {
      for (int x = n - 1; x >= 0; x--) {
        final i = y * n + x;
        if (d[i] == 0) continue;
        double v = d[i];
        if (x < n - 1) v = min(v, d[i + 1] + 1);
        if (y < n - 1) {
          v = min(v, d[i + n] + 1);
          if (x < n - 1) v = min(v, d[i + n + 1] + 1.414);
          if (x > 0) v = min(v, d[i + n - 1] + 1.414);
        }
        d[i] = v;
      }
    }
    return d;
  }

  Float32List _blur(Float32List a, int n, int r) {
    final t = Float32List(n * n), o = Float32List(n * n);
    final w = (2 * r + 1).toDouble();
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        double s = 0;
        for (int k = -r; k <= r; k++) {
          s += a[y * n + min(max(x + k, 0), n - 1)];
        }
        t[y * n + x] = s / w;
      }
    }
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        double s = 0;
        for (int k = -r; k <= r; k++) {
          s += t[min(max(y + k, 0), n - 1) * n + x];
        }
        o[y * n + x] = s / w;
      }
    }
    return o;
  }

  // Da volumen: bordes redondeados, costuras en los trazos interiores, luz, brillo y textura de tela
  Uint8List _relief(Uint8List rgba, Uint8List stroke, int n) {
    final mask = Uint8List(n * n);
    final sa = Float32List(n * n);
    for (int i = 0; i < n * n; i++) {
      mask[i] = rgba[i * 4 + 3] > 127 ? 1 : 0;
      sa[i] = stroke[i * 4 + 3] / 255.0;
    }
    final dist = _dist(mask, n);
    final sb = _blur(sa, n, 2);
    final h = Float32List(n * n);
    for (int i = 0; i < n * n; i++) {
      if (mask[i] == 0) continue;
      final t = min(dist[i] / 14.0, 1.0);
      h[i] = sqrt(1 - (1 - t) * (1 - t)) - 0.35 * sb[i];
    }
    final ll = sqrt(0.5 * 0.5 + 0.6 * 0.6 + 0.62 * 0.62);
    final lx = -0.5 / ll, ly = -0.6 / ll, lz = 0.62 / ll;
    final hz0 = lz + 1;
    final hl = sqrt(lx * lx + ly * ly + hz0 * hz0);
    final hx = lx / hl, hy = ly / hl, hz = hz0 / hl;
    final out = Uint8List(n * n * 4);
    for (int y = 1; y < n - 1; y++) {
      for (int x = 1; x < n - 1; x++) {
        final i = y * n + x;
        if (mask[i] == 0) continue;
        double nx = -(h[i + 1] - h[i - 1]) * 10.0;
        double ny = -(h[i + n] - h[i - n]) * 10.0;
        final inv = 1 / sqrt(nx * nx + ny * ny + 1);
        nx *= inv;
        ny *= inv;
        final nz = inv;
        final diff = max(0.0, nx * lx + ny * ly + nz * lz);
        final sp = pow(max(0.0, nx * hx + ny * hy + nz * hz), 30).toDouble() * 0.45;
        final tex = 1 + 0.045 * sin(x * 1.7) * sin(y * 1.7);
        final shade = (0.45 + 0.8 * diff) * tex;
        for (int c = 0; c < 3; c++) {
          out[i * 4 + c] = (rgba[i * 4 + c] * shade + sp * 255).clamp(0.0, 255.0).round();
        }
        out[i * 4 + 3] = 255;
      }
    }
    return out;
  }

  Future<Uint8List> _export() async {
    final b = _bounds();
    if (!real3d) {
      final kf = 240 / max(max(b.width, b.height), 20);
      return _png(256, (c) {
        c.translate(128, 128);
        c.scale(kf);
        c.translate(-b.center.dx, -b.center.dy);
        for (final f in fills) {
          c.drawImage(f.img, Offset.zero, Paint()..filterQuality = FilterQuality.high);
        }
        _paintStrokes(c, strokes);
      });
    }
    const n = 256;
    final k = 224 / max(max(b.width, b.height), 20);
    void tf(Canvas c) {
      c.translate(128, 128);
      c.scale(k);
      c.translate(-b.center.dx, -b.center.dy);
    }

    final rgba = await _raw(n, (c) {
      tf(c);
      for (final f in fills) {
        c.drawImage(f.img, Offset.zero, Paint()..filterQuality = FilterQuality.high);
      }
      _paintStrokes(c, strokes);
    });
    final sk = await _raw(n, (c) {
      tf(c);
      _paintStrokes(c, strokes, solid: true);
    });
    final comp = Completer<ui.Image>();
    ui.decodeImageFromPixels(_relief(rgba, sk, n), n, n, ui.PixelFormat.rgba8888, comp.complete);
    final img = await comp.future;
    return _png(256, (c) {
      c.drawImage(
          img,
          const Offset(3, 5),
          Paint()
            ..colorFilter = const ColorFilter.mode(Color(0x66000000), BlendMode.srcIn)
            ..imageFilter = ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3));
      c.drawImage(img, Offset.zero, Paint());
    });
  }

  Future<void> _preview() async {
    if (strokes.isEmpty) {
      _msg('Primero dibuja algo');
      return;
    }
    final bytes = await _export();
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              content: Container(color: const Color(0xFFF2EEF8), child: Image.memory(bytes)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))
              ],
            ));
  }

  Future<void> _save() async {
    final name = nameCtrl.text.trim();
    if (strokes.isEmpty || name.isEmpty) {
      _msg('Dibuja algo y ponle un nombre');
      return;
    }
    final bytes = await _export();
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
              color: const Color(0xFFF2EEF8), borderRadius: BorderRadius.circular(12)),
          foregroundDecoration: BoxDecoration(
              border: Border.all(color: kInk, width: 2), borderRadius: BorderRadius.circular(12)),
          child: GestureDetector(
            onTapUp: (d) {
              if (bucket) {
                _bucket(d.localPosition);
              } else {
                final s = _Stroke(color, width)..pts.add(d.localPosition);
                setState(() {
                  strokes.add(s);
                  actions.add(s);
                });
              }
            },
            onPanStart: (d) {
              if (bucket) return;
              final s = _Stroke(color, width)..pts.add(d.localPosition);
              setState(() {
                strokes.add(s);
                actions.add(s);
              });
            },
            onPanUpdate: (d) {
              if (bucket || strokes.isEmpty) return;
              setState(() => strokes.last.pts.add(d.localPosition));
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(size: const Size(side, side), painter: _DrawPainter(fills, strokes)),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ChoiceChip(
                  label: const Text('✏️ Lápiz'),
                  selected: !bucket,
                  onSelected: (_) => setState(() => bucket = false)),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: const Text('🪣 Rellenar'),
                  selected: bucket,
                  onSelected: (_) => setState(() => bucket = true)),
              IconButton(onPressed: _undo, icon: const Icon(Icons.undo)),
              IconButton(
                  onPressed: () => setState(() {
                        strokes.clear();
                        fills.clear();
                        actions.clear();
                      }),
                  icon: const Icon(Icons.delete_outline)),
            ]),
            Center(
              child: Text(
                  bucket
                      ? 'Toca dentro de una figura cerrada para rellenarla'
                      : 'Dibuja el contorno (ciérralo para poder rellenarlo)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final c in palette)
                GestureDetector(
                  onTap: () => setState(() => color = c),
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
            ]),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dar volumen 3D ✨'),
                subtitle: const Text('Luz, sombras, costuras y tela para que parezca real'),
                value: real3d,
                onChanged: (v) => setState(() => real3d = v)),
            OutlinedButton(onPressed: _preview, child: const Text('👁️ Vista previa')),
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
