import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'data.dart';
import 'focus_animal.dart';

const double _sz = 60; // tamaño del animal en el juego
const double _px = 84; // posición horizontal del animal

class _Obs {
  double x;
  final double w, h, base; // base = altura sobre el suelo
  final String e;
  final bool bird;
  bool dead = false;
  _Obs(this.x, this.w, this.h, this.base, this.e, {this.bird = false});
}

class _Shot {
  double x, h; // h = altura sobre el suelo
  bool dead = false;
  _Shot(this.x, this.h);
}

class _Puff {
  double x, life;
  _Puff(this.x, this.life);
}

/// Minijuego de descanso estilo dinosaurio: cuantos más metros sin caer, más difícil.
class GameScreen extends StatefulWidget {
  final Animal animal;
  const GameScreen({super.key, required this.animal});
  @override
  State<GameScreen> createState() => _GameState();
}

class _GameState extends State<GameScreen> with SingleTickerProviderStateMixin {
  static const packs = [
    [1, 4],
    [3, 12],
    [5, 20]
  ]; // minutos, monedas (15 s por moneda)
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  final Random rnd = Random();
  final List<_Obs> obs = [];
  final List<_Puff> puffs = [];
  final List<_Shot> shots = [];
  double cd = 0; // enfriamiento del disparo
  bool playing = false;
  double total = 0, timeLeft = 0, meters = 0, speed = 230, y = 0, vy = 0, spawn = 1.5;
  double stumble = 0, duck = 0, bannerT = 0, dust = 0, scroll = 0, worldW = 400, worldH = 500;
  int level = 0, runBest = 0;
  int best = store.p.getInt('bestm') ?? 0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _start(int mins, int cost) {
    if (store.coins < cost) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Te faltan monedas 🪙')));
      return;
    }
    store.coins = store.coins - cost;
    obs.clear();
    puffs.clear();
    shots.clear();
    cd = 0;
    total = timeLeft = mins * 60.0;
    meters = 0;
    speed = 230;
    y = 0;
    vy = 0;
    spawn = 1.5;
    stumble = 0;
    duck = 0;
    level = 0;
    runBest = 0;
    playing = true;
    _last = Duration.zero;
    _ticker.start();
    setState(() {});
  }

  void _jump() {
    if (playing && y == 0 && stumble <= 0) vy = 560;
  }

  void _shoot() {
    if (!playing || cd > 0 || stumble > 0) return;
    cd = 0.45;
    shots.add(_Shot(_px + 18, y + 24));
  }

  void _duck() {
    if (playing && y == 0 && stumble <= 0) duck = 0.55;
  }

  void _spawn() {
    // separación variable: a veces muy juntos, a veces muy separados
    final g = rnd.nextDouble();
    double gap = max(430.0 - level * 20, 220.0) + rnd.nextDouble() * 170;
    if (level >= 2 && g < 0.28) {
      gap = speed * (0.85 + rnd.nextDouble() * 0.25);
    } else if (g > 0.8) {
      gap = speed * (1.5 + rnd.nextDouble() * 0.8);
    }
    spawn = gap / speed;
    final pool = <int>[0, 1];
    if (level >= 1) pool.add(2); // cactus alto
    if (level >= 2) pool.add(3); // grupo de 2
    if (level >= 3) pool.add(4); // ave baja: saltar
    if (level >= 4) pool.add(5); // ave media: agacharse
    if (level >= 6) pool.add(6); // grupo de 3
    if (level >= 5) pool.add(7); // pájaro grande: hay que dispararle
    if (level >= 7) pool.addAll([8, 6]); // cactus doble alto
    final x = worldW + 30;
    var pick = pool[rnd.nextInt(pool.length)];
    if (pick == 7 && obs.isNotEmpty && obs.last.x > worldW * 0.45) pick = 0;
    switch (pick) {
      case 0:
        obs.add(_Obs(x, 26, 36, 0, '🌵'));
        break;
      case 1:
        obs.add(_Obs(x, 30, 26, 0, '🪨'));
        break;
      case 2:
        obs.add(_Obs(x, 28, 54, 0, '🌵'));
        break;
      case 3:
        obs.add(_Obs(x, 54, 36, 0, '🌵🌵'));
        break;
      case 4:
        obs.add(_Obs(x, 34, 22, 6, '🦅', bird: true));
        break;
      case 5:
        obs.add(_Obs(x, 34, 20, 34, '🦅', bird: true));
        break;
      case 7:
        obs.add(_Obs(x, 44, 82, 0, '🦜', bird: true));
        spawn = max(spawn, 1.3);
        break;
      case 8:
        obs.add(_Obs(x, 58, 54, 0, '🌵🌵'));
        break;
      default:
        obs.add(_Obs(x, 82, 36, 0, '🌵🌵🌵'));
    }
  }

  void _crash() {
    runBest = max(runBest, meters.floor());
    meters = 0; // al caer, la racha y la dificultad vuelven a empezar
    level = 0;
    speed = 230;
    stumble = 1.1;
    bannerT = 0;
    obs.clear();
    shots.clear();
    spawn = 1.9;
  }

  void _tick(Duration d) {
    final dt = min((d - _last).inMicroseconds / 1000000.0, 0.05);
    _last = d;
    if (!playing) return;
    timeLeft -= dt;
    if (timeLeft <= 0) {
      _finish();
      return;
    }
    if (duck > 0) duck -= dt;
    if (bannerT > 0) bannerT -= dt;
    if (cd > 0) cd -= dt;
    final falling = stumble > 0;
    if (falling) stumble -= dt;
    final sp = falling ? 70.0 : speed;
    scroll += sp * dt;
    if (!falling) {
      final before = level;
      meters += speed * dt / 50;
      level = min(meters ~/ 100, 12);
      if (level > before) bannerT = 1.6;
      speed = min(230.0 + meters * 0.4, 640.0); // acelera de forma continua
      spawn -= dt;
      if (spawn <= 0) _spawn();
    }
    y += vy * dt;
    vy -= 1500 * dt;
    if (y <= 0) {
      y = 0;
      vy = 0;
    }
    dust -= dt;
    if (dust <= 0 && y == 0 && !falling) {
      puffs.add(_Puff(_px - 14, 0.45));
      dust = 0.09;
    }
    for (final p in puffs) {
      p.x -= sp * dt * 0.9;
      p.life -= dt;
    }
    puffs.removeWhere((p) => p.life <= 0);
    for (final sh in shots) {
      sh.x += 640 * dt;
      for (final o in obs) {
        if (o.bird && !o.dead && !sh.dead && sh.x > o.x && sh.x < o.x + o.w &&
            sh.h > o.base - 4 && sh.h < o.base + o.h + 4) {
          sh.dead = true;
          o.dead = true;
          meters += 15;
        }
      }
    }
    shots.removeWhere((sh) => sh.dead || sh.x > worldW + 20);
    obs.removeWhere((o) => o.dead);
    final ducking = duck > 0 && y == 0;
    final ph = ducking ? 32.0 : 50.0;
    var crashed = false;
    for (final o in obs) {
      o.x -= sp * dt + (o.bird ? 70 * dt : 0);
      if (!falling && o.x + o.w - 4 > _px - 13 && o.x + 4 < _px + 13) {
        if (y < o.base + o.h - 2 && y + ph > o.base + 2) crashed = true;
      }
    }
    obs.removeWhere((o) => o.x < -100);
    if (crashed) _crash();
    setState(() {});
  }

  void _finish() {
    _ticker.stop();
    playing = false;
    final r = max(runBest, meters.floor());
    final isBest = r > best;
    if (isBest) {
      best = r;
      store.p.setInt('bestm', r);
    }
    setState(() {});
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('¡Descanso terminado! 😌'),
              content: Text('Mejor racha sin caer: $r m${isBest ? ' · ¡récord! 🏆' : ' · récord: $best m'}'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vale'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final mm = (timeLeft.ceil() ~/ 60).toString().padLeft(2, '0');
    final ss = (timeLeft.ceil() % 60).toString().padLeft(2, '0');
    const st = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
    return Scaffold(
      appBar: AppBar(title: const Text('Descanso 🎮')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: playing
              ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('⏱️ $mm:$ss', style: st),
                  Text('🏃 ${meters.floor()} m', style: st),
                  Text('Nv $level', style: st),
                  Text('🏆 $best m', style: st),
                ])
              : Column(children: [
                  Text('Tienes 🪙 ${store.coins} · cada moneda = 15 s de juego'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    for (final p in packs)
                      FilledButton.tonal(
                          onPressed: () => _start(p[0], p[1]),
                          child: Text('${p[0]} min · 🪙 ${p[1]}')),
                  ]),
                  const SizedBox(height: 4),
                  Text('Arriba: saltar · abajo: agacharte · ⭐: disparar a los pájaros · récord 🏆 $best m',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Text('Cada 100 m sin caer sube el nivel y la velocidad; si caes, vuelves al nivel 0',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            worldW = box.maxWidth;
            worldH = box.maxHeight;
            final gy = worldH * 0.72;
            final ducking = playing && duck > 0 && y == 0 && stumble <= 0;
            final bob = (playing && y == 0 && stumble <= 0) ? sin(scroll * 0.06).abs() * 3 : 0.0;
            final ang = stumble > 0 ? -1.2 * sin(pi * min(1.0, (1.1 - stumble) / 1.1)) : 0.0;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                if (d.localPosition.dx > worldW - 90 && d.localPosition.dy > worldH - 90) {
                  _shoot();
                } else if (d.localPosition.dy > worldH * 0.62) {
                  _duck();
                } else {
                  _jump();
                }
              },
              child: Stack(children: [
                Positioned.fill(
                  child: CustomPaint(
                      painter: _GamePainter(
                          widget.animal, gy, scroll, meters, obs, puffs, shots, y, stumble)),
                ),
                if (playing)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: cd > 0 ? 0.4 : 1,
                        child: Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                              color: Color(0xFFFFD43B), shape: BoxShape.circle),
                          child: const Text('⭐', style: TextStyle(fontSize: 30)),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: _px - 0.7 * _sz,
                  top: gy - y - bob - 1.15 * _sz,
                  child: Transform(
                    transform: Matrix4.diagonal3Values(1.0, ducking ? 0.68 : 1.0, 1.0),
                    alignment: const Alignment(0, 0.64),
                    child: Transform.rotate(
                      angle: ang,
                      child: FocusAnimal(
                          animal: widget.animal,
                          size: _sz,
                          aura: false,
                          emotion: stumble > 0 ? 'sad' : null),
                    ),
                  ),
                ),
                if (bannerT > 0)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFD43B), borderRadius: BorderRadius.circular(20)),
                        child: Text('¡Nivel $level! ⚡',
                            style: const TextStyle(
                                color: kInk, fontWeight: FontWeight.w900, fontSize: 18)),
                      ),
                    ),
                  ),
              ]),
            );
          }),
        ),
      ]),
    );
  }
}

class _GamePainter extends CustomPainter {
  final Animal animal;
  final double gy, scroll, meters, y, stumble;
  final List<_Obs> obs;
  final List<_Puff> puffs;
  final List<_Shot> shots;
  _GamePainter(this.animal, this.gy, this.scroll, this.meters, this.obs, this.puffs, this.shots,
      this.y, this.stumble);

  static const _top = [Color(0xFF8EC9F5), Color(0xFFFF9A6B), Color(0xFF1B1F4F)];
  static const _bot = [Color(0xFFDFF3FF), Color(0xFFFFD9A8), Color(0xFF4A3F8F)];

  void _emoji(Canvas c, String e, Offset center, double size) {
    final tp = TextPainter(
        text: TextSpan(text: e, style: TextStyle(fontSize: size)), textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas c, Size s) {
    // cielo: día -> atardecer -> noche según los metros sin caer
    final cyc = meters / 150;
    final i = cyc.floor() % 3;
    final f = ((cyc - cyc.floor() - 0.3) / 0.7).clamp(0.0, 1.0).toDouble();
    final j = (i + 1) % 3;
    final top = Color.lerp(_top[i], _top[j], f)!;
    final bot = Color.lerp(_bot[i], _bot[j], f)!;
    final night = i == 2 ? 1 - f : (i == 1 ? f : 0.0);
    final rect = Offset.zero & s;
    c.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bot])
              .createShader(rect));
    for (int k = 0; k < 30; k++) {
      final r1 = (sin(k * 12.9898) * 43758.5453).abs() % 1.0;
      final r2 = (sin(k * 78.233) * 43758.5453).abs() % 1.0;
      c.drawCircle(Offset(s.width * r1, gy * 0.8 * r2), 1.4,
          Paint()..color = Colors.white.withAlpha((night * 220).round()));
    }
    final cel = Offset(s.width * 0.8, s.height * 0.16);
    final sunC = Color.lerp(const Color(0xFFFFE066), const Color(0xFFFF8A3D), i == 0 ? f : 1.0)!;
    c.drawCircle(cel, 44, Paint()..color = sunC.withAlpha(((1 - night) * 50).round()));
    c.drawCircle(cel, 24, Paint()..color = sunC.withAlpha(((1 - night) * 255).round()));
    c.drawCircle(cel, 22, Paint()..color = const Color(0xFFFFF3B0).withAlpha((night * 255).round()));
    c.drawCircle(cel.translate(8, -3), 19,
        Paint()..color = Color.lerp(top, bot, 0.3)!.withAlpha((night * 255).round()));
    // montañas con paralaje
    for (int layer = 0; layer < 2; layer++) {
      final w = layer == 0 ? 220.0 : 150.0;
      final hgt = layer == 0 ? 95.0 : 60.0;
      final col = Color.lerp(bot, const Color(0xFF6C5BA8), layer == 0 ? 0.3 : 0.5)!;
      final off = (scroll * (layer == 0 ? 0.05 : 0.12)) % w;
      for (double x = -w; x < s.width + w; x += w) {
        final cx = x - off + w;
        c.drawPath(
            Path()
              ..moveTo(cx - w * 0.6, gy)
              ..lineTo(cx, gy - hgt)
              ..lineTo(cx + w * 0.6, gy)
              ..close(),
            Paint()..color = col);
      }
    }
    // nubes
    final cloud = Paint()..color = Colors.white.withAlpha((170 - night * 120).round());
    for (int k = 0; k < 4; k++) {
      final x = (((k * 0.27 + 0.1) * (s.width + 140) - scroll * 0.18 * (1 + k * 0.3)) % (s.width + 140)) - 70;
      final yy = s.height * (0.1 + 0.07 * k);
      c.drawOval(Rect.fromCenter(center: Offset(x, yy), width: 80, height: 24), cloud);
      c.drawOval(Rect.fromCenter(center: Offset(x + 18, yy - 9), width: 46, height: 22), cloud);
    }
    // suelo
    final base = animalColors[animal]!;
    final ground = Color.lerp(Color.lerp(base, const Color(0xFF8B5A3C), 0.55)!, Colors.black, night * 0.4)!;
    c.drawRect(Rect.fromLTWH(0, gy, s.width, s.height - gy), Paint()..color = ground);
    c.drawRect(Rect.fromLTWH(0, gy, s.width, 6),
        Paint()..color = Color.lerp(ground, Colors.white, 0.25)!);
    final mark = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 2;
    for (int k = 0; k < 16; k++) {
      final x = (k * 83.0 - scroll) % (s.width + 83);
      final yy = gy + 16 + (k % 4) * 14;
      c.drawLine(Offset(x, yy), Offset(x + 14 + (k % 3) * 8, yy), mark);
      c.drawCircle(Offset((x + 40) % s.width, yy + 5), 2, Paint()..color = const Color(0x22000000));
    }
    for (int k = 0; k < 4; k++) {
      final x = (k * 260.0 - scroll) % (s.width + 260);
      _emoji(c, '🌿', Offset(x, gy + 4), 16);
    }
    // sombras y obstáculos
    for (final o in obs) {
      if (o.base == 0) {
        c.drawOval(Rect.fromCenter(center: Offset(o.x + o.w / 2, gy + 3), width: o.w, height: 6),
            Paint()..color = const Color(0x33000000));
      }
      final bob = o.bird ? sin(scroll * 0.05 + o.x) * 3 : 0.0;
      _emoji(c, o.e, Offset(o.x + o.w / 2, gy - o.base - o.h / 2 - 2 + bob), o.h * 1.1);
    }
    for (final sh in shots) {
      _emoji(c, '⭐', Offset(sh.x, gy - sh.h), 20);
    }
    // sombra y polvo del animal
    c.drawOval(
        Rect.fromCenter(
            center: const Offset(_px, 0).translate(0, gy + 4),
            width: 44 * (1 - min(y, 120) / 240),
            height: 8),
        Paint()..color = const Color(0x33000000));
    for (final p in puffs) {
      c.drawCircle(Offset(p.x, gy - 2), 3 + (0.45 - p.life) * 9,
          Paint()..color = Colors.white.withAlpha((p.life / 0.45 * 150).round()));
    }
    if (stumble > 0.8) _emoji(c, '✨', const Offset(_px + 6, 0).translate(0, gy - 70), 24);
  }

  @override
  bool shouldRepaint(_GamePainter o) => true;
}
