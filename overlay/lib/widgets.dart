import 'dart:async';
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
              child: Text(emojiOf[animal]!, style: const TextStyle(fontSize: 20))),
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
