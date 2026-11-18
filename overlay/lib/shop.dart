import 'package:flutter/material.dart';
import 'animal_background.dart';
import 'data.dart';
import 'draw.dart';
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

  Widget _tile(Item it, String sub, List<Widget> actions) => ListTile(
        leading: it.kind == 'scene'
            ? ScenePreview(animal: a, scene: sceneIdx[it.id] ?? 4)
            : SizedBox(width: 40, child: Center(child: itemIcon(it))),
        title: Text(it.name),
        subtitle: Text(sub),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
      );

  Widget _buyBtn(Item it) =>
      FilledButton.tonal(onPressed: () => _buy(it), child: Text('🪙 ${it.price}'));

  Widget _accs() {
    final worn = store.accIds(a);
    const order = ['head', 'body', 'neck', 'eyes', 'face', 'back', 'hand', 'feet'];
    final all = allItems().where((i) => i.kind == 'acc').toList();
    final rows = <Widget>[];
    for (final sl in order) {
      final l = all.where((i) => i.slot == sl).toList();
      if (l.isEmpty) continue;
      rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: Text((slotNames[sl] ?? sl).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))));
      for (final it in l) {
        rows.add(_tile(it, worn.contains(it.id) ? 'Puesto' : 'Tienda', [
          if (store.inv(it.id) < 1)
            _buyBtn(it)
          else if (worn.contains(it.id))
            OutlinedButton(
                onPressed: () {
                  store.unequip(a, it.id);
                  setState(() {});
                },
                child: const Text('Quitar'))
          else
            FilledButton(
                onPressed: () {
                  store.equip(a, it);
                  setState(() {});
                },
                child: const Text('Poner')),
        ]));
      }
    }
    return ListView(children: rows);
  }

  Widget _scenes() {
    final cur = store.scene(a);
    return ListView(children: [
      ListTile(
        leading: const Text('🏡', style: TextStyle(fontSize: 30)),
        title: const Text('Predeterminado'),
        subtitle: const Text('El paisaje de tu animal'),
        trailing: (cur < 4)
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

  Widget _create() => ListView(children: [
        ListTile(
          leading: const Text('✏️', style: TextStyle(fontSize: 30)),
          title: const Text('Crear un artículo con un dibujo'),
          subtitle: const Text('Dibújalo y/o descríbelo (ej. «gorra azul con una A gigante»)'),
          onTap: () async {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const DrawScreen()));
            if (mounted) setState(() {});
          },
        ),
        for (final it in store.customs)
          ListTile(
            leading: SizedBox(width: 40, child: Center(child: itemIcon(it))),
            title: Text(it.name),
            subtitle: Text('Complemento (${slotNames[it.slot] ?? it.slot}) · 🪙 ${it.price}'),
            trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  store.delCustom(it.id);
                  setState(() {});
                }),
          ),
      ]);

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Tienda 🛒   🪙 ${store.coins}'),
            bottom: const TabBar(isScrollable: true, tabs: [
              Tab(text: 'Complementos'),
              Tab(text: 'Fondos'),
              Tab(text: 'Crear ✏️'),
            ]),
          ),
          body: Column(children: [
            SizedBox(
              height: 170,
              child: Row(children: [
                Expanded(
                  child: FittedBox(
                    child: FocusAnimal(animal: a, size: 130, acc: store.accIds(a)),
                  ),
                ),
              ]),
            ),
            Expanded(child: TabBarView(children: [_accs(), _scenes(), _create()])),
          ]),
        ),
      );
}
