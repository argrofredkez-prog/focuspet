import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';
import 'focus_animal.dart';

/// Burbuja de chat del animal.
class ChatBubble extends StatelessWidget {
  final Animal animal;
  final String text;
  const ChatBubble({super.key, required this.animal, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: AnimalIcon(animal, 22)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4)),
              ),
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, color: kInk, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
}

/// Etapa, hambre y experiencia del animal (tipo tamagotchi).
class PetStats extends StatelessWidget {
  final Animal animal;
  final Color ink;
  const PetStats({super.key, required this.animal, required this.ink});

  Widget _bar(String icon, double v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Text(icon),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: ink,
                backgroundColor: Colors.white38),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final xp = store.xp(animal);
    final st = stageOf(xp);
    final h = store.hunger(animal);
    final prev = st == 0 ? 0 : (st == 1 ? 50 : 150);
    final next = st == 0 ? 50 : (st == 1 ? 150 : 150);
    final prog = st == 2 ? 1.0 : (xp - prev) / (next - prev);
    final mood = h > 60 ? '😋' : (h > 25 ? '🙂' : '🥺');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(children: [
        Text('${stageNames[st]} · ⭐ $xp  $mood',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 4),
        _bar('🍽️', h / 100),
        _bar('⭐', prog.clamp(0.0, 1.0).toDouble()),
      ]),
    );
  }
}

/// Bocadillo de cómic con la frase del animal (el piquito apunta hacia arriba, al animal).
class ComicBubble extends StatelessWidget {
  final String text;
  const ComicBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: CustomPaint(
          painter: _BubblePainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: kInk, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    const tail = 12.0;
    final cx = s.width / 2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, tail, s.width, s.height - tail), const Radius.circular(20)))
      ..moveTo(cx - 10, tail + 1)
      ..lineTo(cx, 0)
      ..lineTo(cx + 10, tail + 1)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
        path,
        Paint()
          ..color = kInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);
    // tapa la línea entre el piquito y el cuerpo
    canvas.drawLine(Offset(cx - 9, tail), Offset(cx + 9, tail),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icono de un artículo: emoji o su dibujo.
Widget itemIcon(Item it, {double size = 30}) => it.img != null
    ? Image.memory(it.img!, width: size, height: size)
    : Text(it.emoji, style: TextStyle(fontSize: size));

/// Sol hasta las 16:00, atardecer hasta las 20:00 y luna hasta las 8:00. Brilla suavemente.
class SkyIcon extends StatefulWidget {
  const SkyIcon({super.key});
  @override
  State<SkyIcon> createState() => _SkyState();
}

class _SkyState extends State<SkyIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final p = (h >= 8 && h < 16) ? 0 : ((h >= 16 && h < 20) ? 1 : 2);
    const icons = ['☀️', '🌇', '🌙'];
    const glows = [Color(0xFFFFD43B), Color(0xFFFF8A3D), Color(0xFFB3C7FF)];
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(
              color: glows[p].withAlpha((70 + 100 * _c.value).round()),
              blurRadius: 8 + 12 * _c.value,
              spreadRadius: 1 + 3 * _c.value)
        ]),
        child: Text(icons[p], style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

/// Bocadillo cuyo piquito llega hasta la boca del animal.
class MouthBubble extends StatelessWidget {
  final String text;
  final double tipDx, tipDy, baseX; // punta del piquito y dónde nace, relativos al globo
  const MouthBubble(
      {super.key, required this.text, required this.tipDx, required this.tipDy, required this.baseX});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _MouthPainter(tipDx, tipDy, baseX),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + tipDy),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: kInk, fontWeight: FontWeight.w700)),
        ),
      );
}

class _MouthPainter extends CustomPainter {
  final double tipDx, tipDy, baseX;
  _MouthPainter(this.tipDx, this.tipDy, this.baseX);

  @override
  void paint(Canvas canvas, Size s) {
    final bodyH = s.height - tipDy;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, s.width, bodyH), const Radius.circular(18)))
      ..moveTo(baseX - 9, bodyH - 1)
      ..lineTo(tipDx, s.height)
      ..lineTo(baseX + 9, bodyH - 1)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
        path,
        Paint()
          ..color = kInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round);
    canvas.drawLine(Offset(baseX - 8, bodyH), Offset(baseX + 8, bodyH),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Icono de cada animal: emoji, y el dragón dibujado de frente
class AnimalIcon extends StatelessWidget {
  final Animal animal;
  final double size;
  const AnimalIcon(this.animal, this.size, {super.key});

  @override
  Widget build(BuildContext context) => animal == Animal.cocodrilo
      ? CustomPaint(size: Size.square(size * 1.25), painter: _DragonFace())
      : Text(emojiOf[animal]!, style: TextStyle(fontSize: size));
}

class _DragonFace extends CustomPainter {
  Paint _f(Color c) => Paint()..color = c;
  Paint _l(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 100, s.height / 100);
    const line = Color(0xFF2E7D4F);
    for (final d in [-1.0, 1.0]) {
      final horn = Path()
        ..moveTo(50 + d * 18, 26)
        ..quadraticBezierTo(50 + d * 26, 8, 50 + d * 34, 6)
        ..quadraticBezierTo(50 + d * 36, 20, 50 + d * 28, 30)
        ..close();
      c.drawPath(horn, _f(const Color(0xFFFFE9A8)));
      c.drawPath(horn, _l(const Color(0xFFD9A84E), 1.6));
      final fin = Path()
        ..moveTo(50 + d * 38, 46)
        ..lineTo(50 + d * 50, 40)
        ..lineTo(50 + d * 46, 52)
        ..lineTo(50 + d * 52, 62)
        ..lineTo(50 + d * 38, 62)
        ..close();
      c.drawPath(fin, _f(const Color(0xFF7ED6A0)));
      c.drawPath(fin, _l(line, 1.6));
    }
    final head = Rect.fromCenter(center: const Offset(50, 56), width: 78, height: 68);
    c.drawOval(
        head,
        Paint()
          ..shader = const RadialGradient(center: Alignment(-.3, -.5), colors: [Color(0xFFD8F7A0), Color(0xFF8FDC6A), Color(0xFF4FB06A)], stops: [0, .55, 1])
              .createShader(head));
    c.drawOval(head, _l(line, 2.4));
    for (final x in [38.0, 50.0, 62.0]) {
      final sp = Path()
        ..moveTo(x - 4, 24)
        ..lineTo(x, x == 50.0 ? 12 : 16)
        ..lineTo(x + 4, 24)
        ..close();
      c.drawPath(sp, _f(const Color(0xFFFFB04C)));
      c.drawPath(sp, _l(const Color(0xFFD9822E), 1.2));
    }
    final mz = Rect.fromCenter(center: const Offset(50, 70), width: 46, height: 30);
    c.drawOval(mz, _f(const Color(0xFFEAFBC4)));
    c.drawOval(mz, _l(line, 1.4));
    for (final d in [-1.0, 1.0]) {
      c.drawCircle(Offset(50 + d * 7, 66), 2.2, _f(line));
      c.drawOval(Rect.fromCenter(center: Offset(50 + d * 16, 50), width: 13, height: 16), _f(const Color(0xFF2B2140)));
      c.drawCircle(Offset(50 + d * 16 - 2.2, 46.5), 3.4, _f(Colors.white));
      c.drawCircle(Offset(50 + d * 16 + 2.4, 54), 1.7, _f(const Color(0xDDFFFFFF)));
      c.drawCircle(Offset(50 + d * 30, 62), 5, _f(const Color(0x66FF6F9F)));
    }
    c.drawArc(Rect.fromCenter(center: const Offset(50, 74), width: 14, height: 9), 0.2, pi - 0.4, false, _l(line, 1.8));
    c.drawPath(Path()..moveTo(46, 77)..lineTo(47.5, 82)..lineTo(49, 77)..close(), _f(Colors.white));
  }

  @override
  bool shouldRepaint(_DragonFace o) => false;
}
