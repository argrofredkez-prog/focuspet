import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'focus_animal.dart';

const kInk = Color(0xFF4A3B5C);
const emojiOf = {
  Animal.cerdo: '🐷',
  Animal.unicornio: '🦄',
  Animal.tigre: '🐯',
  Animal.cocodrilo: '🐊',
};

Color inkFor(Animal a, int scene) =>
    (a == Animal.cocodrilo || scene == 2) ? Colors.white : kInk;

class Item {
  final String id, name, emoji, kind, slot; // kind: food | acc | scene ; slot: head | eyes | neck
  final int price, hunger, xp;
  final Animal? animal;
  final Uint8List? img; // dibujo propio (PNG)
  const Item(this.id, this.name, this.emoji, this.price, this.kind,
      {this.hunger = 0, this.xp = 0, this.animal, this.slot = '', this.img});
}

const catalog = <Item>[
  // Comida
  Item('f_cerdo1', 'Fresas', '🍓', 10, 'food', hunger: 20, xp: 5, animal: Animal.cerdo),
  Item('f_cerdo2', 'Tarta', '🍰', 25, 'food', hunger: 45, xp: 12, animal: Animal.cerdo),
  Item('f_cerdo3', 'Donut', '🍩', 15, 'food', hunger: 30, xp: 8, animal: Animal.cerdo),
  Item('f_cerdo4', 'Banquete', '🍱', 60, 'food', hunger: 90, xp: 30, animal: Animal.cerdo),
  Item('f_uni1', 'Piruleta', '🍭', 10, 'food', hunger: 20, xp: 5, animal: Animal.unicornio),
  Item('f_uni2', 'Cupcake', '🧁', 25, 'food', hunger: 45, xp: 12, animal: Animal.unicornio),
  Item('f_uni3', 'Helado', '🍦', 15, 'food', hunger: 30, xp: 8, animal: Animal.unicornio),
  Item('f_uni4', 'Banquete', '🍱', 60, 'food', hunger: 90, xp: 30, animal: Animal.unicornio),
  Item('f_tigre1', 'Carne', '🥩', 10, 'food', hunger: 20, xp: 5, animal: Animal.tigre),
  Item('f_tigre2', 'Muslo de pollo', '🍗', 25, 'food', hunger: 45, xp: 12, animal: Animal.tigre),
  Item('f_tigre3', 'Costillas', '🍖', 15, 'food', hunger: 30, xp: 8, animal: Animal.tigre),
  Item('f_tigre4', 'Banquete', '🍱', 60, 'food', hunger: 90, xp: 30, animal: Animal.tigre),
  Item('f_croc1', 'Pescado', '🐟', 10, 'food', hunger: 20, xp: 5, animal: Animal.cocodrilo),
  Item('f_croc2', 'Gambas', '🍤', 25, 'food', hunger: 45, xp: 12, animal: Animal.cocodrilo),
  Item('f_croc3', 'Cangrejo', '🦀', 15, 'food', hunger: 30, xp: 8, animal: Animal.cocodrilo),
  Item('f_croc4', 'Banquete', '🍱', 60, 'food', hunger: 90, xp: 30, animal: Animal.cocodrilo),
  // Complementos
  Item('a_flower', 'Flor', '🌸', 20, 'acc', slot: 'head'),
  Item('a_bow', 'Lazo', '🎀', 30, 'acc', slot: 'head'),
  Item('a_headphones', 'Auriculares', '🎧', 45, 'acc', slot: 'head'),
  Item('a_hat', 'Sombrero', '🎩', 50, 'acc', slot: 'head'),
  Item('a_crown', 'Corona', '👑', 80, 'acc', slot: 'head'),
  Item('a_glasses', 'Gafas de sol', '🕶️', 40, 'acc', slot: 'eyes'),
  Item('a_scarf', 'Bufanda', '🧣', 25, 'acc', slot: 'neck'),
  Item('a_bowtie', 'Pajarita', '👔', 35, 'acc', slot: 'neck'),
  Item('a_wizard', 'Sombrero de mago', '🧙', 70, 'acc', slot: 'head'),
  Item('a_chef', 'Gorro de chef', '👨‍🍳', 45, 'acc', slot: 'head'),
  Item('a_antlers', 'Astas de reno', '🦌', 55, 'acc', slot: 'head'),
  Item('a_halo', 'Aureola', '😇', 60, 'acc', slot: 'head'),
  Item('a_pirate', 'Parche pirata', '🏴‍☠️', 40, 'acc', slot: 'eyes'),
  Item('a_mustache', 'Bigote', '🥸', 30, 'acc', slot: 'face'),
  Item('a_cape', 'Capa de superhéroe', '🦸', 90, 'acc', slot: 'back'),
  Item('a_wings', 'Alas de ángel', '👼', 100, 'acc', slot: 'back'),
  Item('a_balloon', 'Globo', '🎈', 35, 'acc', slot: 'hand'),
  // Fondos
  Item('s_dawn', 'Amanecer', '🌅', 70, 'scene'),
  Item('s_sunset', 'Atardecer', '🌇', 60, 'scene'),
  Item('s_night', 'Noche estrellada', '🌙', 100, 'scene'),
];

const sceneIdx = {'s_sunset': 1, 's_night': 2, 's_dawn': 3};
const slotNames = {
  'head': 'cabeza',
  'eyes': 'ojos',
  'neck': 'cuello',
  'face': 'cara',
  'back': 'espalda',
  'hand': 'mano',
};
const modeNames = ['Estudiar', 'Entrenar', 'Dormir'];
const modeEmoji = ['📚', '🏋️', '😴'];
const stageNames = ['Bebé', 'Joven', 'Adulto'];
const stageScale = [0.72, 0.86, 1.0];
int stageOf(int xp) => xp >= 150 ? 2 : (xp >= 50 ? 1 : 0);

List<Item> allItems() => [...catalog, ...store.customs];
Item itemById(String id) =>
    allItems().firstWhere((i) => i.id == id, orElse: () => catalog.first);

late Store store;

class Store {
  final SharedPreferences p;
  Store(this.p);

  int get coins => p.getInt('coins') ?? 0;
  set coins(int v) {
    p.setInt('coins', v);
  }

  bool get strict => p.getBool('strict') ?? true;
  List<String> get allowed => p.getStringList('allowed') ?? <String>[];

  // Avisos diarios (minutos del día; -1 = desactivado). 1 dormir, 2 entrenar, 3 estudiar, 4 repasar;
  // 5, 6 y 7 son el 2.º aviso de dormir, entrenar y estudiar
  int rem(int id) => p.getInt('r$id') ?? (id == 1 ? 1410 : -1);

  // Minutos por estado (0 estudiar, 1 entrenar, 2 dormir)
  String _day() {
    final n = DateTime.now();
    return '${n.year}${n.month}${n.day}';
  }

  int minsToday(int mode) => p.getInt('d${_day()}_$mode') ?? 0;
  int minsTotal(int mode) => p.getInt('t_$mode') ?? 0;
  void addMins(int mode, int m) {
    p.setInt('d${_day()}_$mode', minsToday(mode) + m);
    p.setInt('t_$mode', minsTotal(mode) + m);
  }

  int inv(String id) => p.getInt('inv_$id') ?? 0;
  void setInv(String id, int v) {
    p.setInt('inv_$id', v);
  }

  int xp(Animal a) => p.getInt('xp_${a.name}') ?? 0;
  void addXp(Animal a, int v) {
    p.setInt('xp_${a.name}', xp(a) + v);
  }

  // Complementos puestos (uno por zona: cabeza, ojos, cuello)
  List<String> accIds(Animal a) {
    final s = p.getString('acc_${a.name}') ?? '';
    return s.isEmpty ? <String>[] : s.split(',');
  }

  void setAccIds(Animal a, List<String> l) {
    p.setString('acc_${a.name}', l.join(','));
  }

  void equip(Animal a, Item it) {
    final l = accIds(a)..removeWhere((id) => itemById(id).slot == it.slot);
    l.add(it.id);
    setAccIds(a, l);
  }

  void unequip(Animal a, String id) {
    setAccIds(a, accIds(a)..remove(id));
  }

  int scene(Animal a) => p.getInt('scene_${a.name}') ?? 0;
  void setScene(Animal a, int v) {
    p.setInt('scene_${a.name}', v);
  }

  // Hambre 0..100: baja 4 puntos por hora
  double hunger(Animal a) {
    final kt = 'ht_${a.name}', kh = 'hg_${a.name}';
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!p.containsKey(kt)) {
      p.setInt(kt, now);
      p.setDouble(kh, 80.0);
      return 80.0;
    }
    final h = p.getDouble(kh) ?? 80.0;
    final hours = (now - (p.getInt(kt) ?? now)) / 3600000.0;
    return (h - hours * 4).clamp(0.0, 100.0).toDouble();
  }

  void feed(Animal a, int amount) {
    final h = (hunger(a) + amount).clamp(0.0, 100.0).toDouble();
    p.setDouble('hg_${a.name}', h);
    p.setInt('ht_${a.name}', DateTime.now().millisecondsSinceEpoch);
  }

  // ---------- artículos creados con dibujos ----------
  List<Item>? _cc;

  List<Map<String, dynamic>> _rawCustoms() {
    final s = p.getString('customs');
    if (s == null) return [];
    return [for (final m in jsonDecode(s) as List<dynamic>) Map<String, dynamic>.from(m as Map)];
  }

  List<Item> get customs {
    final cached = _cc;
    if (cached != null) return cached;
    final l = [
      for (final m in _rawCustoms())
        Item(m['id'] as String, m['name'] as String, '', m['kind'] == 'food' ? 12 : 25,
            m['kind'] as String,
            hunger: m['kind'] == 'food' ? 20 : 0,
            xp: m['kind'] == 'food' ? 5 : 0,
            slot: m['slot'] as String,
            img: base64Decode(m['png'] as String))
    ];
    _cc = l;
    return l;
  }

  void addCustom(String name, String kind, String slot, Uint8List png) {
    final raw = _rawCustoms();
    raw.add({
      'id': 'c_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'kind': kind,
      'slot': slot,
      'png': base64Encode(png),
    });
    p.setString('customs', jsonEncode(raw));
    _cc = null;
  }

  void delCustom(String id) {
    for (final a in Animal.values) {
      setAccIds(a, accIds(a)..remove(id));
    }
    final raw = _rawCustoms()..removeWhere((m) => m['id'] == id);
    p.setString('customs', jsonEncode(raw));
    _cc = null;
  }

  // ---------- repasos (curva del olvido) ----------
  List<Map<String, dynamic>> topics() {
    final s = p.getString('topics');
    if (s == null) return [];
    return [for (final m in jsonDecode(s) as List<dynamic>) Map<String, dynamic>.from(m as Map)];
  }

  void saveTopics(List<Map<String, dynamic>> l) {
    p.setString('topics', jsonEncode(l));
  }

  // 14 días tras el 1.º estudio, 30 tras el 2.º, y 30 en adelante (mensual)
  String get intervalsText {
    final s = p.getString('intervals');
    return (s == null || s == '14,30,60,120,180') ? '14,30' : s;
  }

  List<int> get intervals {
    final l = <int>[];
    for (final e in intervalsText.split(',')) {
      final v = int.tryParse(e.trim()) ?? 0;
      if (v > 0) l.add(v);
    }
    return l.isEmpty ? <int>[14] : l;
  }

  // Fecha del próximo repaso: último estudio + intervalo según nº de veces estudiado
  DateTime dueDate(Map<String, dynamic> t) {
    final iv = intervals;
    final n = t['n'] as int;
    final days = iv[min(max(n - 1, 0), iv.length - 1)];
    final last = DateTime.fromMillisecondsSinceEpoch(t['last'] as int);
    return DateTime(last.year, last.month, last.day + days);
  }

  int daysLeft(Map<String, dynamic> t) {
    final d = dueDate(t);
    final now = DateTime.now();
    return DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;
  }

  int get dueCount => topics().where((t) => daysLeft(t) <= 0).length;

  // ---------- estados de ánimo (clave 'aaaa-mm-dd' -> {m: 0..4, n: nota}) ----------
  Map<String, dynamic> moods() {
    final s = p.getString('moods');
    return s == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(s) as Map);
  }

  void setMood(String key, List<int> tags, String note) {
    final all = moods();
    all[key] = {'t': tags, 'n': note};
    p.setString('moods', jsonEncode(all));
  }

  void delMood(String key) {
    final all = moods()..remove(key);
    p.setString('moods', jsonEncode(all));
  }

  // ---------- ciclo: [{s: inicio (ms UTC), d: días de regla, ov: ovulación (ms) o null}] ----------
  List<Map<String, dynamic>> cycles() {
    final s = p.getString('cycles');
    if (s == null) return [];
    return [for (final m in jsonDecode(s) as List<dynamic>) Map<String, dynamic>.from(m as Map)];
  }

  void saveCycles(List<Map<String, dynamic>> l) {
    p.setString('cycles', jsonEncode(l));
  }
}
