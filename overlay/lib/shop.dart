import 'package:flutter/material.dart';
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

class _ShopState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  Animal get a => widget.animal;
  late final AnimationController _eatC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  Item? _eating;

  @override
  void dispose() {
    _eatC.dispose();
    super.dispose();
  }

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
    if (store.inv(it.id) < 1 || _eating != null) return;
    store.setInv(it.id, store.inv(it.id) - 1);
    setState(() => _eating = it);
    _eatC.forward(from: 0).then((_) {
      if (mounted) setState(() => _eating = null);
    });
    _msg('¡Ñam! 😋');
  }

  Widget _tile(Item it, String sub, List<Widget> actions) => ListTile(
        leading: SizedBox(width: 40, child: Center(child: itemIcon(it))),
        title: Text(it.name),
        subtitle: Text(sub),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
      );

  Widget _buyBtn(Item it) =>
      FilledButton.tonal(onPressed: () => _buy(it), child: Text('🪙 ${it.price}'));

  Widget _foods() => ListView(children: [
        for (final it in allItems().where((i) => i.kind == 'food' && (i.animal == a || i.animal == null)))
          _tile(it, 'Tienes ${store.inv(it.id)}', [
            _buyBtn(it),
            const SizedBox(width: 6),
            FilledButton(
                onPressed: store.inv(it.id) > 0 && _eating == null ? () => _feed(it) : null,
                child: const Text('Dar')),
          ]),
      ]);

  Widget _accs() {
    final worn = store.accIds(a);
    return ListView(children: [
      for (final it in allItems().where((i) => i.kind == 'acc'))
        _tile(it, 'Zona: ${slotNames[it.slot] ?? it.slot}${worn.contains(it.id) ? ' · puesto' : ''}', [
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
        ]),
    ]);
  }

  Widget _scenes() {
    final cur = store.scene(a);
    return ListView(children: [
      ListTile(
        leading: const Text('☀️', style: TextStyle(fontSize: 30)),
        title: const Text('Automático'),
        subtitle: const Text('Cambia con la hora: sol, atardecer y noche'),
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

  Widget _create() => ListView(children: [
        ListTile(
          leading: const Text('✏️', style: TextStyle(fontSize: 30)),
          title: const Text('Crear un artículo con un dibujo'),
          subtitle: const Text('Dibuja un complemento o una comida y aparecerá en la tienda'),
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
            subtitle: Text(it.kind == 'food'
                ? 'Comida · 🪙 ${it.price}'
                : 'Complemento (${slotNames[it.slot] ?? it.slot}) · 🪙 ${it.price}'),
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
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Tienda 🛒   🪙 ${store.coins}'),
            bottom: const TabBar(isScrollable: true, tabs: [
              Tab(text: 'Comida'),
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
                    child: AnimatedBuilder(
                      animation: _eatC,
                      builder: (_, __) => FocusAnimal(
                          animal: a,
                          size: 130,
                          acc: store.accIds(a),
                          eat: _eating == null ? -1 : _eatC.value,
                          food: _eating),
                    ),
                  ),
                ),
              ]),
            ),
            Expanded(child: TabBarView(children: [_foods(), _accs(), _scenes(), _create()])),
          ]),
        ),
      );
}
