import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'animal_background.dart';
import 'data.dart';
import 'focus_animal.dart';
import 'game.dart';
import 'cycle.dart';
import 'mood.dart';
import 'review.dart';
import 'shop.dart';
import 'widgets.dart';

const _ch = MethodChannel('focuspet/blocker');
const maxPauses = 3, pauseMinutes = 5;

const defaultPhrases = [
  '¡Tú puedes! Ya llevas parte del camino 💪',
  'Respira. Un poco más y lo logras ✨',
  'Tu yo del futuro te dará las gracias 💖',
  'Ahora no toca el móvil, toca brillar 🌟',
];

List<String> loadPhrases() =>
    List<String>.from(store.p.getStringList('phrases') ?? defaultPhrases);

void savePhrases(List<String> l) {
  store.p.setStringList('phrases', l);
}

String _dur(int m) => m >= 60 ? '${m ~/ 60} h ${m % 60} min' : '$m min';

String _fmt(int s) =>
    '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

/// Elige hasta 3 apps permitidas para un estado (se hace antes de empezar la sesión).
Future<void> pickApps(BuildContext context, int mode) async {
  final raw = await _ch.invokeMethod<List<dynamic>>('getApps') ?? <dynamic>[];
  final apps = raw.map((e) => Map<String, String>.from(e as Map)).toList();
  final sel = store.allowedFor(mode).toSet();
  if (!context.mounted) return;
  await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
            builder: (c, setS) => AlertDialog(
              title: Text('${modeNames[mode]}: hasta 3 apps (${sel.length}/3)'),
              content: SizedBox(
                width: double.maxFinite,
                height: 360,
                child: apps.isEmpty
                    ? const Center(child: Text('No se han encontrado apps'))
                    : ListView(children: [
                        for (final a in apps)
                          CheckboxListTile(
                              title: Text(a['name']!),
                              value: sel.contains('${a['pkg']}|${a['name']}'),
                              onChanged: (v) {
                                final k = '${a['pkg']}|${a['name']}';
                                setS(() {
                                  if (v == true) {
                                    if (sel.length < 3) sel.add(k);
                                  } else {
                                    sel.remove(k);
                                  }
                                });
                              }),
                      ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Listo'))
              ],
            ),
          ));
  store.setAllowed(mode, sel.toList());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  store = Store(await SharedPreferences.getInstance());
  dimLevel = store.p.getDouble('dim') ?? 0.25;
  darkMode.value = store.p.getBool('dark') ?? true;
  runApp(const FocusPetApp());
}

class FocusPetApp extends StatelessWidget {
  const FocusPetApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: darkMode,
        builder: (_, dark, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        ),
      );
}

// ======================= INICIO =======================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  Animal animal = Animal.values[store.p.getInt('animal') ?? 0];
  int mode = (DateTime.now().hour >= 22 || DateTime.now().hour < 6) ? 2 : 0;
  late double minutes = mode == 2 ? 480.0 : 25.0;
  String? bubble;
  Timer? _bt;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _ch.invokeMethod('setupBedtime'); // pide permiso de notificaciones
    _ch.invokeMethod('setBrightness', store.bright);
    _ch.invokeMethod('dndRestore');
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    for (final id in [1, 2, 3, 4, 5, 6, 7, 8]) {
      final v = store.rem(id);
      if (v >= 0) _ch.invokeMethod('setReminder', {'id': id, 'h': v ~/ 60, 'm': v % 60});
    }
  }

  @override
  void dispose() {
    _bt?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  // Al tocar al animal dice una frase en un bocadillo
  void _talk() {
    final p = loadPhrases();
    if (p.isEmpty) return;
    setState(() => bubble = p[Random().nextInt(p.length)]);
    _bt?.cancel();
    _bt = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => bubble = null);
    });
  }

  // Menú con las herramientas extra
  void _more() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Text('📊', style: TextStyle(fontSize: 26)),
              title: const Text('Mi día'),
              onTap: () {
                Navigator.pop(c);
                _stats();
              }),
          ListTile(
              leading: const Text('🎮', style: TextStyle(fontSize: 26)),
              title: const Text('Descanso: minijuego'),
              onTap: () {
                Navigator.pop(c);
                _go(GameScreen(animal: animal));
              }),
          ListTile(
              leading: const Text('😊', style: TextStyle(fontSize: 26)),
              title: const Text('Estados de ánimo'),
              onTap: () {
                Navigator.pop(c);
                _go(const MoodScreen());
              }),
          ListTile(
              leading: const Text('🌸', style: TextStyle(fontSize: 26)),
              title: const Text('Ciclo: regla y ovulación'),
              onTap: () {
                Navigator.pop(c);
                _go(const CycleScreen());
              }),
        ]),
      ),
    );
  }

  void _stats() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Mi día 📊'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                            '${modeEmoji[i]} ${modeNames[i]}: hoy ${_dur(store.minsToday(i))} · total ${_dur(store.minsTotal(i))}'),
                      ),
                  ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))
              ],
            ));
  }

  Future<void> _go(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    if (mounted) setState(() {});
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
    if (store.blockNotifs && !(await _ch.invokeMethod<bool>('hasDnd') ?? false)) {
      if (!mounted) return;
      final go = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
                title: const Text('Bloquear notificaciones 🔕'),
                content: const Text(
                    'Para silenciar todo menos las llamadas, permite a focuspet el acceso a "No molestar".'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Abrir ajustes')),
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Seguir sin bloquear')),
                ],
              ));
      if (go == true) {
        _ch.invokeMethod('openDndSettings');
        return;
      }
    }
    final strict = mode == 2 ? true : store.strict;
    final pkgs = strict
        ? <String>[]
        : store.allowedFor(mode).map((e) => e.substring(0, e.indexOf('|'))).toList();
    await _ch.invokeMethod('setAllowed', pkgs);
    if (!mounted) return;
    await _go(FocusScreen(
        animal: animal,
        minutes: minutes.round(),
        phrases: loadPhrases(),
        mode: mode,
        strict: strict));
  }

  @override
  Widget build(BuildContext context) {
    final scene = effScene(animal);
    final ink = inkFor(animal, scene);
    Widget icon(String e, VoidCallback f) => IconButton(
        onPressed: f,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        icon: Text(e, style: const TextStyle(fontSize: 24)));
    return Scaffold(
      body: AnimalBackground(
        animal: animal,
        scene: scene,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              Row(children: [
                const SizedBox(width: 12),
                const SkyIcon(),
                const SizedBox(width: 6),
                Text('🪙 ${store.coins}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
                const Spacer(),
                icon('🛒', () => _go(ShopScreen(animal: animal))),
                icon('➕', _more),
                icon(store.dueCount > 0 ? '🧠${store.dueCount}' : '🧠', () => _go(const ReviewScreen())),
                icon('💬', () => _go(PhrasesScreen(animal: animal))),
                icon('⚙️', () => _go(const SettingsScreen())),
              ]),
              GestureDetector(
                onTap: _talk,
                child: SizedBox(
                height: 230,
                child: Center(
                  child: FittedBox(
                    child: FocusAnimal(
                        animal: animal,
                        size: 200,
                        mode: mode,
                        acc: store.accIds(animal)),
                  ),
                ),
              ),
              ),
              SizedBox(
                  height: 70,
                  child: bubble == null ? null : Center(child: ComicBubble(text: bubble!))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final a in Animal.values)
                  ChoiceChip(
                      label: Text(emojiOf[a]!, style: const TextStyle(fontSize: 26)),
                      selected: a == animal,
                      onSelected: (_) {
                        setState(() => animal = a);
                        store.p.setInt('animal', a.index);
                      }),
              ]),
              Wrap(spacing: 8, children: [
                for (int i = 0; i < 3; i++)
                  ChoiceChip(
                      label: Text('${modeEmoji[i]} ${modeNames[i]}'),
                      selected: mode == i,
                      onSelected: (_) => setState(() {
                            mode = i;
                            minutes = i == 2 ? 480.0 : 25.0;
                          })),
              ]),
              Text(_dur(minutes.round()),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink)),
              Slider(
                  value: minutes,
                  min: mode == 2 ? 240.0 : 15.0,
                  max: mode == 2 ? 600.0 : 180.0,
                  divisions: mode == 2 ? 24 : 33,
                  activeColor: ink,
                  inactiveColor: Colors.white54,
                  onChanged: (v) => setState(() => minutes = v)),
              if (mode == 2)
                Text('🔒 Todo bloqueado mientras duermes',
                    style: TextStyle(fontSize: 14, color: ink))
              else
                Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                  ChoiceChip(
                      label: const Text('🔒 Estricto'),
                      selected: store.strict,
                      onSelected: (_) {
                        store.p.setBool('strict', true);
                        setState(() {});
                      }),
                  ChoiceChip(
                      label: const Text('🔓 No estricto'),
                      selected: !store.strict,
                      onSelected: (_) {
                        store.p.setBool('strict', false);
                        setState(() {});
                      }),
                  if (!store.strict)
                    ActionChip(
                        label: Text('📱 Apps (${store.allowedFor(mode).length}/3)'),
                        onPressed: () async {
                          await pickApps(context, mode);
                          if (mounted) setState(() {});
                        }),
                ]),
              if (!store.strict && mode != 2)
                Text('Mitad de monedas · elige las apps antes de empezar',
                    style: TextStyle(fontSize: 12, color: ink)),
              const SizedBox(height: 8),
              ActionChip(
                  label: Text('🎵 Música: ${musicShort[store.music]}'),
                  onPressed: () {
                    store.p.setInt('music', (store.music + 1) % 4);
                    setState(() {});
                  }),
              const SizedBox(height: 8),
              FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: ink,
                      foregroundColor: ink == Colors.white ? kInk : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
                  onPressed: _start,
                  child: Text(mode == 2 ? 'Buenas noches 🌙' : 'Concentrarme ✨',
                      style: const TextStyle(fontSize: 20))),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }
}

// ======================= AJUSTES =======================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  Future<void> _pickRem(int id) async {
    final cur = store.rem(id);
    final t = await showTimePicker(
        context: context,
        initialTime: cur < 0
            ? const TimeOfDay(hour: 18, minute: 0)
            : TimeOfDay(hour: cur ~/ 60, minute: cur % 60));
    if (t == null) return;
    store.p.setInt('r$id', t.hour * 60 + t.minute);
    _ch.invokeMethod('setReminder', {'id': id, 'h': t.hour, 'm': t.minute});
    if (mounted) setState(() {});
  }

  Widget _remTile(int id, String name, String hint) {
    final v = store.rem(id);
    return ListTile(
      title: Text('Aviso de $name'),
      subtitle: Text(v < 0 ? 'Desactivado · toca para elegir hora' : '${_fmt(v)} cada día$hint'),
      trailing: v < 0
          ? const Icon(Icons.chevron_right)
          : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                store.p.setInt('r$id', -1);
                _ch.invokeMethod('cancelReminder', id);
                setState(() {});
              }),
      onTap: () => _pickRem(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes ⚙️')),
      body: ListView(children: [
        ListTile(
          title: Text('Brillo de la app 🔆 ${(store.bright * 100).round()}%'),
          subtitle: Slider(
              value: store.bright,
              min: 0.1,
              max: 1.0,
              onChanged: (v) {
                store.p.setDouble('bright', v);
                _ch.invokeMethod('setBrightness', v);
                setState(() {});
              }),
        ),
        ListTile(
          title: Text('Atenuar colores ${(dimLevel * 100).round()}%'),
          subtitle: Slider(
              value: dimLevel,
              min: 0,
              max: 0.6,
              onChanged: (v) {
                dimLevel = v;
                store.p.setDouble('dim', v);
                setState(() {});
              }),
        ),
        SwitchListTile(
          title: const Text('Tema oscuro 🌙'),
          value: darkMode.value,
          onChanged: (v) {
            darkMode.value = v;
            store.p.setBool('dark', v);
            setState(() {});
          },
        ),
        SwitchListTile(
          title: const Text('Bloquear notificaciones 🔕'),
          subtitle: const Text('En la sesión solo suenan las llamadas (y las alarmas)'),
          value: store.blockNotifs,
          onChanged: (v) {
            store.p.setBool('dnd', v);
            setState(() {});
          },
        ),
        ListTile(
          title: Text('Volumen de la música 🎵 ${(store.musicVol * 100).round()}%'),
          subtitle: Slider(
              value: store.musicVol,
              min: 0.05,
              max: 1.0,
              onChanged: (v) {
                store.p.setDouble('mvol', v);
                _ch.invokeMethod('musicVolume', v);
                setState(() {});
              }),
        ),
        SwitchListTile(
          title: const Text('Modo estricto 🔒'),
          subtitle: const Text(
              'Desactivado: puedes usar hasta 3 apps durante la sesión y ganas la mitad de monedas.'),
          value: store.strict,
          onChanged: (v) {
            store.p.setBool('strict', v);
            setState(() {});
          },
        ),
        for (final md in [0, 1])
          ListTile(
            title: Text('Apps permitidas al ${md == 0 ? 'estudiar 📚' : 'entrenar 🏋️'} (${store.allowedFor(md).length}/3)'),
            subtitle: Text(store.allowedFor(md).isEmpty
                ? 'Toca para elegir (se usan en modo no estricto)'
                : store.allowedFor(md).map((e) => e.substring(e.indexOf('|') + 1)).join(', ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await pickApps(context, md);
              if (mounted) setState(() {});
            },
          ),
        _remTile(3, 'estudiar 📚 · 1.º', ''),
        _remTile(7, 'estudiar 📚 · 2.º', ''),
        _remTile(2, 'entrenar 🏋️ · 1.º', ''),
        _remTile(6, 'entrenar 🏋️ · 2.º', ''),
        _remTile(1, 'dormir 🌙 · 1.º', ' (menos viernes y sábado)'),
        _remTile(5, 'dormir 🌙 · 2.º', ' (menos viernes y sábado)'),
        _remTile(4, 'repasar 🧠', ''),
        _remTile(8, 'registrar ánimo 😊', ''),
      ]),
    );
  }
}

// ======================= FRASES =======================
class PhrasesScreen extends StatefulWidget {
  final Animal animal;
  const PhrasesScreen({super.key, required this.animal});
  @override
  State<PhrasesScreen> createState() => _PhrasesState();
}

class _PhrasesState extends State<PhrasesScreen> {
  List<String> phrases = loadPhrases();
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      phrases.add(t);
      ctrl.clear();
    });
    savePhrases(phrases);
  }

  void _del(int i) {
    setState(() => phrases.removeAt(i));
    savePhrases(phrases);
  }

  @override
  Widget build(BuildContext context) {
    final scene = effScene(widget.animal);
    final ink = inkFor(widget.animal, scene);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Mis frases 💬'),
          backgroundColor: animalColors[widget.animal],
          foregroundColor: ink),
      body: AnimalBackground(
        animal: widget.animal,
        scene: scene,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    maxLength: 80,
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(
                        hintText: 'Una frase que te anime…',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none)),
                  ),
                ),
                IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: phrases.length,
                itemBuilder: (_, i) => Row(children: [
                  Expanded(child: ChatBubble(animal: widget.animal, text: phrases[i])),
                  IconButton(onPressed: () => _del(i), icon: Icon(Icons.close, color: ink)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ======================= SESIÓN =======================
class FocusScreen extends StatefulWidget {
  final Animal animal;
  final int minutes;
  final List<String> phrases;
  final bool strict;
  final int mode; // 0 estudiar, 1 entrenar, 2 dormir
  const FocusScreen({
    super.key,
    required this.animal,
    required this.minutes,
    required this.phrases,
    required this.mode,
    required this.strict,
  });
  @override
  State<FocusScreen> createState() => _FocusState();
}

class _FocusState extends State<FocusScreen> with WidgetsBindingObserver {
  late DateTime endAt = DateTime.now().add(Duration(minutes: widget.minutes));
  late final int total = widget.minutes * 60;
  late int remaining = total;
  late final List<String> phrases = List<String>.from(widget.phrases);
  final List<MapEntry<int, String>> chat = [];
  final Random _rnd = Random();
  int _n = 0;
  DateTime? pauseStart;
  int pausesUsed = 0;
  Timer? _t;
  Timer? _chatT;
  bool done = false;
  String? speech; // frase que dice el animal desde la boca
  Timer? _speechT;
  String? emotion; // focus | sad | happy
  Timer? _emoT;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.mode != 2) {
      emotion = 'focus';
      _emoT = Timer(const Duration(seconds: 3), () {
        if (mounted && emotion == 'focus') setState(() => emotion = null);
      });
    }
    _ch.invokeMethod('setDnd', store.blockNotifs);
    _ch.invokeMethod('musicVolume', store.musicVol);
    if (store.music > 0) _ch.invokeMethod('musicPlay', store.music);
    _ch.invokeMethod('setBlocking', true);
    _ch.invokeMethod('lockScreen'); // apaga la pantalla
    _scheduleEnd();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (widget.mode != 2) {
      _chatT = Timer.periodic(const Duration(seconds: 25), (_) => _say());
      Future.delayed(const Duration(milliseconds: 3500), () => _say());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _t?.cancel();
    _chatT?.cancel();
    _emoT?.cancel();
    _speechT?.cancel();
    _ch.invokeMethod('musicStop');
    _ch.invokeMethod('cancelEnd');
    _ch.invokeMethod('setBlocking', false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  // Avisa (y vibra) al terminar aunque la pantalla esté apagada
  void _scheduleEnd() {
    _ch.invokeMethod('scheduleEnd',
        {'at': endAt.millisecondsSinceEpoch, 'v': widget.mode != 2, 'mode': widget.mode});
  }

  void _say([String? text]) {
    if (!mounted) return;
    if (text == null && phrases.isEmpty) return;
    final msg = text ?? phrases[_rnd.nextInt(phrases.length)];
    setState(() => speech = msg);
    _speechT?.cancel();
    _speechT = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => speech = null);
    });
  }

  Future<void> _addPhrase() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Nueva frase 💬'),
              content: TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(hintText: 'Escribe algo que te anime…')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
                TextButton(
                    onPressed: () => Navigator.pop(c, ctrl.text.trim()),
                    child: const Text('Guardar')),
              ],
            ));
    if (text == null || text.isEmpty || !mounted) return;
    phrases.add(text);
    savePhrases(phrases);
    _say(text);
  }

  void _tick() {
    if (done) return;
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
    _ch.invokeMethod('cancelEnd');
    setState(() {
      pausesUsed++;
      pauseStart = DateTime.now();
    });
  }

  void _resume() {
    endAt = endAt.add(DateTime.now().difference(pauseStart!)); // la pausa no cuenta
    _scheduleEnd();
    _ch.invokeMethod('setBlocking', true);
    setState(() => pauseStart = null);
  }

  Future<void> _complete() async {
    if (done) return;
    done = true;
    _t?.cancel();
    _ch.invokeMethod('cancelEnd');
    await _ch.invokeMethod('setBlocking', false);
    final base = widget.mode == 2 ? widget.minutes / 10 : widget.minutes / 5;
    final earned = (base * (widget.strict ? 1.0 : 0.5)).round();
    store.coins = store.coins + earned;
    store.addMins(widget.mode, widget.minutes);
    const extra = '';
    if (!mounted) return;
    setState(() => emotion = 'happy');
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
            title: Text(widget.mode == 2 ? '¡Buenos días! ☀️' : '¡Sesión completada! 🎉'),
            content: Text('Has ganado $earned 🪙$extra')));
    if (mounted) Navigator.pop(context);
  }

  void _nextTrack() {
    final n = (store.music + 1) % 4;
    store.p.setInt('music', n);
    if (n == 0) {
      _ch.invokeMethod('musicStop');
    } else {
      _ch.invokeMethod('musicPlay', n);
    }
    setState(() {});
  }

  Widget _banner(String t) => TweenAnimationBuilder<double>(
        key: ValueKey(t),
        tween: Tween<double>(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFFFFD43B), borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: const TextStyle(color: kInk, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      );

  // Para abandonar hay que resolver una operación
  Future<void> _abandon() async {
    final msg = phrases.isEmpty
        ? '¿Seguro? Estás muy cerca 🥺'
        : phrases[_rnd.nextInt(phrases.length)];
    var q = '';
    var ans = 0;
    var err = '';
    void newQ() {
      final t = _rnd.nextInt(3);
      final a = 12 + _rnd.nextInt(38), b = 3 + _rnd.nextInt(7), n = 10 + _rnd.nextInt(90);
      if (t == 0) {
        q = '$a × $b + $n';
        ans = a * b + n;
      } else if (t == 1) {
        q = '($a + $n) × $b';
        ans = (a + n) * b;
      } else {
        q = '$a × $b − $n';
        ans = a * b - n;
      }
    }

    newQ();
    final ctrl = TextEditingController();
    final yes = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (c) => StatefulBuilder(
              builder: (c, setS) => AlertDialog(
                title: const Text('¿Abandonar? 🥺'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  ComicBubble(text: msg),
                  const SizedBox(height: 8),
                  const Text('Resuelve para poder salir:'),
                  Text('$q = ?', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  TextField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      decoration: InputDecoration(
                          hintText: 'Resultado', errorText: err.isEmpty ? null : err)),
                ]),
                actions: [
                  FilledButton(
                      onPressed: () => Navigator.pop(c, false), child: const Text('Seguir 💪')),
                  TextButton(
                      onPressed: () {
                        if (int.tryParse(ctrl.text.trim()) == ans) {
                          Navigator.pop(c, true);
                        } else {
                          setS(() {
                            err = 'Incorrecto, prueba con esta';
                            newQ();
                            ctrl.clear();
                          });
                        }
                      },
                      child: const Text('Abandonar')),
                ],
              ),
            ));
    if (yes == true && mounted) {
      done = true;
      _t?.cancel();
      setState(() => emotion = 'sad');
      await Future.delayed(const Duration(milliseconds: 2400));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paused = pauseStart != null;
    final left = maxPauses - pausesUsed;
    final scene = widget.mode == 2 ? 2 : effScene(widget.animal);
    final ink = inkFor(widget.animal, scene);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AnimalBackground(
          animal: widget.animal,
          scene: scene,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                    SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                            value: 1 - remaining / total,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            color: ink,
                            backgroundColor: Colors.white38)),
                    FocusAnimal(
                        animal: widget.animal,
                        size: 150,
                        mode: widget.mode,
                        acc: store.accIds(widget.animal),
                        emotion: emotion ?? ((speech != null && widget.mode != 2) ? 'talk' : null)),
                    if (emotion == 'focus' || emotion == 'happy')
                      Positioned(
                          top: 0,
                          child: _banner(emotion == 'focus' ? 'FOCUS ON ⚡' : '¡Lo lograste! 👏')),
                    if (speech != null && emotion == null && widget.mode != 2)
                      Positioned(
                          bottom: 127,
                          left: 85,
                          width: 170,
                          child: MouthBubble(text: speech!, tipDx: 50, tipDy: 63, baseX: 98)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_fmt(remaining),
                      style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: ink)),
                  Text(
                      paused
                          ? 'Pausa: ${_fmt(pauseMinutes * 60 - DateTime.now().difference(pauseStart!).inSeconds)}'
                          : ['Estudiando 📚', 'Entrenando 💪', 'Durmiendo 😴 Buenas noches'][widget.mode],
                      style: TextStyle(fontSize: 16, color: ink)),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  if (!widget.strict && store.allowedFor(widget.mode).isNotEmpty)
                    Wrap(spacing: 6, children: [
                      for (final e in store.allowedFor(widget.mode))
                        ActionChip(
                            label: Text('📱 ${e.substring(e.indexOf('|') + 1)}'),
                            onPressed: () =>
                                _ch.invokeMethod('launchApp', e.substring(0, e.indexOf('|')))),
                    ]),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FilledButton.tonal(
                        onPressed: paused ? _resume : (left > 0 ? _pause : null),
                        child: Text(paused ? 'Reanudar' : 'Pausar ($left/$maxPauses)')),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                        onPressed: _addPhrase, icon: const Icon(Icons.chat_bubble_outline)),
                  ]),
                  ActionChip(
                      label: Text('🎵 ${musicShort[store.music]}'), onPressed: _nextTrack),
                  TextButton(
                      onPressed: _abandon,
                      child: Text('Abandonar', style: TextStyle(color: ink))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
