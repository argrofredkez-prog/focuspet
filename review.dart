import 'package:flutter/material.dart';
import 'data.dart';

/// Repasos según la curva del olvido.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends State<ReviewScreen> {
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _add() async {
    final ctrl = TextEditingController();
    DateTime when = DateTime.now();
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
              builder: (c, setS) => AlertDialog(
                title: const Text('Nuevo tema 🧠'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Nombre del tema')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                            context: c,
                            initialDate: when,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1)));
                        if (d != null) setS(() => when = d);
                      },
                      child: Text('Estudiado el ${_date(when)}')),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
                ],
              ),
            ));
    final name = ctrl.text.trim();
    if (ok != true || name.isEmpty) return;
    final l = store.topics();
    l.add({'name': name, 'n': 1, 'last': when.millisecondsSinceEpoch});
    store.saveTopics(l);
    if (mounted) setState(() {});
  }

  void _done(int i) {
    final l = store.topics();
    l[i]['n'] = (l[i]['n'] as int) + 1;
    l[i]['last'] = DateTime.now().millisecondsSinceEpoch;
    store.saveTopics(l);
    setState(() {});
  }

  Future<void> _delete(int i) async {
    final l = store.topics();
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: Text('¿Borrar "${l[i]['name']}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Borrar')),
              ],
            ));
    if (yes != true) return;
    l.removeAt(i);
    store.saveTopics(l);
    if (mounted) setState(() {});
  }

  Future<void> _intervals() async {
    final ctrl = TextEditingController(text: store.intervalsText);
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Intervalos entre repasos (días)'),
              content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                      helperText: 'Separados por comas. El último se repite.',
                      hintText: '14,30,60,120')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
              ],
            ));
    if (ok == true) {
      store.p.setString('intervals', ctrl.text);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = store.topics();
    final idx = List<int>.generate(l.length, (i) => i)
      ..sort((a, b) => store.daysLeft(l[a]).compareTo(store.daysLeft(l[b])));
    return Scaffold(
      appBar: AppBar(title: const Text('Repasos 🧠'), actions: [
        IconButton(onPressed: _intervals, icon: const Icon(Icons.tune)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _add, icon: const Icon(Icons.add), label: const Text('Tema')),
      body: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Repasos a los ${store.intervals.join(' → ')} días (el último se repite)',
              style: const TextStyle(color: Colors.grey)),
        ),
        if (l.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Añade los temas que estudias y te diré cuándo repasarlos.'),
          ),
        for (final i in idx)
          () {
            final t = l[i];
            final d = store.daysLeft(t);
            final n = t['n'] as int;
            final color = d < 0
                ? const Color(0xFFD32F2F)
                : (d == 0 ? const Color(0xFFEF6C00) : const Color(0xFF2E7D32));
            final status = d < 0 ? 'atrasado ${-d} d' : (d == 0 ? 'hoy' : 'en $d d');
            return ListTile(
              title: Text('${t['name']}'),
              subtitle: Text(
                  'Estudiado $n ${n == 1 ? 'vez' : 'veces'} · próximo repaso ${_date(store.dueDate(t))} ($status)',
                  style: TextStyle(color: color)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    tooltip: 'Repasado hoy',
                    onPressed: () => _done(i),
                    icon: Icon(Icons.check_circle, color: color)),
                IconButton(onPressed: () => _delete(i), icon: const Icon(Icons.delete_outline)),
              ]),
            );
          }(),
      ]),
    );
  }
}
