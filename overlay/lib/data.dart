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
  final String id, name, emoji, kind; // kind: food | acc | scene
  final int price, hunger, xp;
  final Animal? animal;
  const Item(this.id, this.name, this.emoji, this.price, this.kind,
      {this.hunger = 0, this.xp = 0, this.animal});
}

const catalog = <Item>[
  Item('f_cerdo1', 'Fresas', '🍓', 10, 'food', hunger: 20, xp: 5, animal: Animal.cerdo),
  Item('f_cerdo2', 'Tarta', '🍰', 25, 'food', hunger: 45, xp: 12, animal: Animal.cerdo),
  Item('f_uni1', 'Piruleta', '🍭', 10, 'food', hunger: 20, xp: 5, animal: Animal.unicornio),
  Item('f_uni2', 'Cupcake', '🧁', 25, 'food', hunger: 45, xp: 12, animal: Animal.unicornio),
  Item('f_tigre1', 'Carne', '🥩', 10, 'food', hunger: 20, xp: 5, animal: Animal.tigre),
  Item('f_tigre2', 'Muslo de pollo', '🍗', 25, 'food', hunger: 45, xp: 12, animal: Animal.tigre),
  Item('f_croc1', 'Pescado', '🐟', 10, 'food', hunger: 20, xp: 5, animal: Animal.cocodrilo),
  Item('f_croc2', 'Gambas', '🍤', 25, 'food', hunger: 45, xp: 12, animal: Animal.cocodrilo),
  Item('a_flower', 'Flor', '🌸', 20, 'acc'),
  Item('a_bow', 'Lazo', '🎀', 30, 'acc'),
  Item('a_glasses', 'Gafas', '🕶️', 40, 'acc'),
  Item('a_hat', 'Sombrero', '🎩', 50, 'acc'),
  Item('a_crown', 'Corona', '👑', 80, 'acc'),
  Item('s_sunset', 'Atardecer', '🌇', 60, 'scene'),
  Item('s_night', 'Noche estrellada', '🌙', 100, 'scene'),
];

const modeNames = ['Estudiar', 'Entrenar', 'Dormir'];
const modeEmoji = ['📚', '🏋️', '😴'];

const sceneIdx = {'s_sunset': 1, 's_night': 2};
const stageNames = ['Bebé', 'Joven', 'Adulto'];
const stageScale = [0.72, 0.86, 1.0];
int stageOf(int xp) => xp >= 150 ? 2 : (xp >= 50 ? 1 : 0);
Item itemById(String id) => catalog.firstWhere((i) => i.id == id);

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
  // Avisos diarios (minutos del día; -1 = desactivado). 1 dormir, 2 entrenar, 3 estudiar
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

  String acc(Animal a) => p.getString('acc_${a.name}') ?? '';
  void setAcc(Animal a, String id) {
    p.setString('acc_${a.name}', id);
  }

  String accEmoji(Animal a) {
    final id = acc(a);
    return id.isEmpty ? '' : itemById(id).emoji;
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
}
