import 'package:flutter/material.dart';
import 'data.dart';

const moodTags = [
  ['😄', 'Alegre'], ['😢', 'Triste'], ['😴', 'Cansada'], ['💪', 'Fuerte'],
  ['😠', 'Enfadada'], ['🤬', 'Rabiosa'], ['🍽️', 'Hambrienta'], ['🤕', 'Adolorida'],
  ['🎈', 'Hinchada'], ['🌀', 'Desconcentrada'], ['😞', 'Desmotivada'],
];

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _nice(String k) => '${k.substring(8)}/${k.substring(5, 7)}/${k.substring(0, 4)}';

// etiquetas de un día (admite el formato antiguo de una sola carita)
List<int> tagsOf(Map e) {
  final t = e['t'];
  if (t is List) return [for (final v in t) v as int];
  final m = e['m'];
  if (m is int) return m <= 1 ? [0] : (m >= 3 ? [1] : <int>[]);
  return <int>[];
}

/// Registro diario de estados de ánimo (se pueden elegir varios).
class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodState();
}

class _MoodState extends State<MoodScreen> {
  final note = TextEditingController();
  final String today = dayKey(DateTime.now());
  final Set<int> sel = {};

  @override
  void initState() {
    super.initState();
    final e = store.moods()[today] as Map?;
    if (e != null) {
      sel.addAll(tagsOf(e));
      note.text = (e['n'] as String?) ?? '';
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void _persist() {
    if (sel.isEmpty && note.text.trim().isEmpty) {
      store.delMood(today);
    } else {
      store.setMood(today, sel.toList()..sort(), note.text.trim());
    }
  }

  void _toggle(int i) {
    setState(() {
      if (!sel.remove(i)) sel.add(i);
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final all = store.moods();
    final keys = all.keys.toList()..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();
    final days = [for (int i = 13; i >= 0; i--) now.subtract(Duration(days: i))];
    final cnt = List<int>.filled(moodTags.length, 0);
    for (int i = 0; i < 30; i++) {
      final e = all[dayKey(now.subtract(Duration(days: i)))] as Map?;
      if (e != null) {
        for (final t in tagsOf(e)) {
          cnt[t]++;
        }
      }
    }
    final top = List<int>.generate(moodTags.length, (i) => i)
        .where((i) => cnt[i] > 0)
        .toList()
      ..sort((a, b) => cnt[b].compareTo(cnt[a]));
    return Scaffold(
      appBar: AppBar(title: const Text('Estados de ánimo 😊')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('¿Cómo te sientes hoy?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const Text('Puedes elegir varios', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (int i = 0; i < moodTags.length; i++)
            FilterChip(
                label: Text('${moodTags[i][0]} ${moodTags[i][1]}'),
                selected: sel.contains(i),
                onSelected: (_) => _toggle(i)),
        ]),
        const SizedBox(height: 12),
        TextField(
            controller: note,
            maxLength: 120,
            decoration: InputDecoration(
                hintText: 'Nota opcional',
                suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      _persist();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Guardado ✅')));
                    }))),
        const SizedBox(height: 8),
        Text(
            top.isEmpty
                ? 'Aún no hay datos de los últimos 30 días'
                : 'Más frecuentes (30 días): ${top.take(3).map((i) => '${moodTags[i][0]} ${moodTags[i][1]} (${cnt[i]})').join(' · ')}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text('Últimos 14 días'),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final d in days)
            SizedBox(
              width: 44,
              child: Column(children: [
                Text(
                    all[dayKey(d)] == null
                        ? '·'
                        : tagsOf(all[dayKey(d)] as Map).take(2).map((t) => moodTags[t][0]).join(),
                    style: const TextStyle(fontSize: 18)),
                Text('${d.day}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
            ),
        ]),
        const Divider(height: 28),
        for (final k in keys.take(30))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
                '${_nice(k)}  ${tagsOf(all[k] as Map).map((t) => moodTags[t][0]).join(' ')}'),
            subtitle: Text([
              tagsOf(all[k] as Map).map((t) => moodTags[t][1]).join(', '),
              ((all[k] as Map)['n'] as String?) ?? '',
            ].where((s) => s.isNotEmpty).join(' · ')),
            trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  store.delMood(k);
                  setState(() {});
                }),
          ),
      ]),
    );
  }
}
