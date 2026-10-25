import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'focus_animal.dart';

const _ch = MethodChannel('focuspet/blocker');
const maxPauses = 3, pauseMinutes = 5;
const _ink = Color(0xFF4A3B5C);
const _emoji = {Animal.cerdo: '🐷', Animal.unicornio: '🦄', Animal.tigre: '🐯', Animal.pantera: '🐈‍⬛'};

BoxDecoration _bg(Animal a) => BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [animalColors[a]!, Color.lerp(animalColors[a], Colors.white, .75)!]));

String _fmt(int s) =>
    '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

void main() => runApp(const FocusPetApp());

class FocusPetApp extends StatelessWidget {
  const FocusPetApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  Animal animal = Animal.cerdo;
  double minutes = 25;
  int coins = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => coins = p.getInt('coins') ?? 0);
  }

  Future<void> _start() async {
    final ok = await _ch.invokeMethod<bool>('isEnabled') ?? false;
    if (!ok) {
      if (!mounted) return;
      await showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: const Text('Activa el bloqueo 🔒'),
                content: const Text(
                    'En Accesibilidad busca "focuspet" y actívalo. Solo se usa para saber qué app está abierta.'),
                actions: [
                  TextButton(
                      onPressed: () {
                        _ch.invokeMethod('openSettings');
                        Navigator.pop(context);
                      },
                      child: const Text('Abrir ajustes'))
                ],
              ));
      return;
    }
    if (!mounted) return;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => FocusScreen(animal: animal, minutes: minutes.round())));
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _bg(animal),
          child: SafeArea(
            child: Column(children: [
              const SizedBox(height: 16),
              Text('🪙 $coins',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
              const Spacer(),
              FocusAnimal(animal: animal, size: 200),
              const Spacer(),
              Wrap(spacing: 8, children: [
                for (final a in Animal.values)
                  ChoiceChip(
                      label: Text(_emoji[a]!, style: const TextStyle(fontSize: 26)),
                      selected: a == animal,
                      onSelected: (_) => setState(() => animal = a)),
              ]),
              const SizedBox(height: 16),
              Text('${minutes.round()} min',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _ink)),
              Slider(
                  value: minutes,
                  min: 15,
                  max: 180,
                  divisions: 33,
                  activeColor: _ink,
                  onChanged: (v) => setState(() => minutes = v)),
              const SizedBox(height: 8),
              FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: _ink,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
                  onPressed: _start,
                  child: const Text('Concentrarme ✨', style: TextStyle(fontSize: 20))),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      );
}

class FocusScreen extends StatefulWidget {
  final Animal animal;
  final int minutes;
  const FocusScreen({super.key, required this.animal, required this.minutes});
  @override
  State<FocusScreen> createState() => _FocusState();
}

class _FocusState extends State<FocusScreen> {
  late DateTime endAt = DateTime.now().add(Duration(minutes: widget.minutes));
  late final int total = widget.minutes * 60;
  late int remaining = total;
  DateTime? pauseStart;
  int pausesUsed = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _ch.invokeMethod('setBlocking', true);
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _t?.cancel();
    _ch.invokeMethod('setBlocking', false);
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    if (pauseStart != null) {
      if (now.difference(pauseStart!).inSeconds >= pauseMinutes * 60) {
        _resume();
      } else {
        setState(() {});
      }
      return;
    }
    final r = endAt.difference(now).inSeconds;
    if (r <= 0) {
      _complete();
    } else {
      setState(() => remaining = r);
    }
  }

  void _pause() {
    if (pausesUsed >= maxPauses) return;
    _ch.invokeMethod('pause', pauseMinutes * 60 * 1000);
    setState(() {
      pausesUsed++;
      pauseStart = DateTime.now();
    });
  }

  void _resume() {
    endAt = endAt.add(DateTime.now().difference(pauseStart!)); // la pausa no cuenta
    _ch.invokeMethod('setBlocking', true);
    setState(() => pauseStart = null);
  }

  Future<void> _complete() async {
    _t?.cancel();
    await _ch.invokeMethod('setBlocking', false);
    final earned = widget.minutes ~/ 5;
    final p = await SharedPreferences.getInstance();
    await p.setInt('coins', (p.getInt('coins') ?? 0) + earned);
    if (!mounted) return;
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
            title: const Text('¡Sesión completada! 🎉'),
            content: Text('Has ganado $earned 🪙')));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _abandon() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('¿Abandonar? 🥺'),
              content: const Text('Perderás la recompensa de esta sesión.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Seguir')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Abandonar')),
              ],
            ));
    if (yes == true && mounted) {
      _t?.cancel();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paused = pauseStart != null;
    final left = maxPauses - pausesUsed;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _bg(widget.animal),
          child: SafeArea(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                        value: 1 - remaining / total,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        color: _ink,
                        backgroundColor: Colors.white54)),
                FocusAnimal(animal: widget.animal, size: 160),
              ]),
              const SizedBox(height: 24),
              Text(_fmt(remaining),
                  style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: _ink)),
              Text(
                  paused
                      ? 'Pausa: ${_fmt(pauseMinutes * 60 - DateTime.now().difference(pauseStart!).inSeconds)}'
                      : 'Shhh… descansando 💤',
                  style: const TextStyle(fontSize: 16, color: _ink)),
              const SizedBox(height: 32),
              FilledButton.tonal(
                  onPressed: paused ? _resume : (left > 0 ? _pause : null),
                  child: Text(paused ? 'Reanudar' : 'Pausar ($left/$maxPauses)')),
              TextButton(onPressed: _abandon, child: const Text('Abandonar')),
            ]),
          ),
        ),
      ),
    );
  }
}
