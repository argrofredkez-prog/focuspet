import 'package:flutter/material.dart';
import 'data.dart';
import 'focus_animal.dart';
import 'widgets.dart';

class ShopScreen extends StatefulWidget {
  final Animal animal;
  const ShopScreen({super.key, required this.animal});
  @override
  State<ShopScreen> createState() => _ShopState();
}

class _ShopState extends State<ShopScreen> {
  Animal get a => widget.animal;

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  void _buy(Item it) {
    if (store.coins < it.price) {
      _msg('Te faltan monedas 🪙');
      return;
    }
    store.coins = store.coins - it.price;
    store.setInv(it.id, store.inv(it.id) + 1);
    setState(() {});
  }

  void _feed(Item it) {
    if (store.inv(it.id) < 1) return;
    store.setInv(it.id, store.inv(it.id) - 1);
    store.feed(a, it.hunger);
    store.addXp(a, it.xp);
    setState(() {});
    _msg('¡Ñam! +${it.xp} ⭐');
  }

  Widget _tile(Item it, String sub, List<Widget> actions) => ListTile(
        leading: Text(it.emoji, style: const TextStyle(fontSize: 30)),
        title: Text(it.name),
        subtitle: Text(sub),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
      );

  Widget _buyBtn(Item it) =>
      FilledButton.tonal(onPressed: () => _buy(it), child: Text('🪙 ${it.price}'));

  Widget _foods() => ListView(children: [
        for (final it in catalog.where((i) => i.kind == 'food' && i.animal == a))
          _tile(it, 'Tienes ${store.inv(it.id)} · +${it.hunger} 🍽️ +${it.xp} ⭐', [
            _buyBtn(it),
            const SizedBox(width: 6),
            FilledButton(
                onPressed: store.inv(it.id) > 0 ? () => _feed(it) : null,
                child: const Text('Dar')),
          ]),
      ]);

  Widget _accs() => ListView(children: [
        for (final it in catalog.where((i) => i.kind == 'acc'))
          _tile(it, store.acc(a) == it.id ? 'Puesto' : 'Complemento', [
            if (store.inv(it.id) < 1)
              _buyBtn(it)
            else if (store.acc(a) == it.id)
              OutlinedButton(
                  onPressed: () {
                    store.setAcc(a, '');
                    setState(() {});
                  },
                  child: const Text('Quitar'))
            else
              FilledButton(
                  onPressed: () {
                    store.setAcc(a, it.id);
                    setState(() {});
                  },
                  child: const Text('Poner')),
          ]),
      ]);

  Widget _scenes() {
    final cur = store.scene(a);
    return ListView(children: [
      ListTile(
        leading: const Text('☀️', style: TextStyle(fontSize: 30)),
        title: const Text('Día'),
        subtitle: const Text('Fondo normal'),
        trailing: cur == 0
            ? const Text('En uso')
            : FilledButton(
                onPressed: () {
                  store.setScene(a, 0);
                  setState(() {});
                },
                child: const Text('Usar')),
      ),
      for (final it in catalog.where((i) => i.kind == 'scene'))
        _tile(it, 'Fondo', [
          if (store.inv(it.id) < 1)
            _buyBtn(it)
          else if (cur == sceneIdx[it.id])
            const Text('En uso')
          else
            FilledButton(
                onPressed: () {
                  store.setScene(a, sceneIdx[it.id]!);
                  setState(() {});
                },
                child: const Text('Usar')),
        ]),
    ]);
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Tienda 🛒   🪙 ${store.coins}'),
            bottom: const TabBar(tabs: [
              Tab(text: 'Comida'),
              Tab(text: 'Complementos'),
              Tab(text: 'Fondos'),
            ]),
          ),
          body: Column(children: [
            SizedBox(
              height: 150,
              child: Row(children: [
                Expanded(
                  child: FittedBox(
                    child: FocusAnimal(
                        animal: a,
                        size: 120,
                        scale: stageScale[stageOf(store.xp(a))],
                        accessory: store.accEmoji(a)),
                  ),
                ),
                Expanded(
                    child: Center(child: PetStats(animal: a, ink: kInk))),
              ]),
            ),
            Expanded(child: TabBarView(children: [_foods(), _accs(), _scenes()])),
          ]),
        ),
      );
}
