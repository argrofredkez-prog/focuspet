import 'package:flutter/material.dart';
import 'data.dart';

const moodFaces = ['😄', '🙂', '😐', '😕', '😢'];
const moodLabels = ['Genial', 'Bien', 'Normal', 'Bajo', 'Mal'];

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _nice(String k) => '${k.substring(8)}/${k.substring(5, 7)}/${k.substring(0, 4)}';

/// Registro diario del estado de ánimo.
class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodState();
}

class _MoodState extends State<MoodScreen> {
  final note = TextEditingController();
  final String today = dayKey(DateTime.now());
  int? sel;

  @override
  void initState() {
    super.initState();
    final e = store.moods()[today] as Map?;
    if (e != null) {
      sel = e['m'] as int;
      note.text = e['n'] as String;
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void _pick(int i) {
    setState(() => sel = i);
    store.setMood(today, i, note.text.trim());
  }

  void _saveNote() {
    final m = sel;
    if (m == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Elige primero cómo te sientes')));
      return;
    }
    store.setMood(today, m, note.text.trim());
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado ✅')));
  }

  @override
  Widget build(BuildContext context) {
    final all = store.moods();
    final keys = all.keys.toList()..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();
    final days = [for (int i = 13; i >= 0; i--) now.subtract(Duration(days: i))];
    int sum = 0, n = 0;
    for (int i = 0; i < 30; i++) {
      final e = all[dayKey(now.subtract(Duration(days: i)))] as Map?;
      if (e != null) {
        sum += e['m'] as int;
        n++;
      }
    }
    final avg = n == 0 ? -1 : (sum / n).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Estados de ánimo 😊')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('¿Cómo te sientes hoy?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (int i = 0; i < 5; i++)
            GestureDetector(
              onTap: () => _pick(i),
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: sel == i ? const Color(0x33FFB347) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sel == i ? kInk : Colors.transparent, width: 2)),
                  child: Text(moodFaces[i], style: TextStyle(fontSize: sel == i ? 40 : 34)),
                ),
                Text(moodLabels[i], style: const TextStyle(fontSize: 12)),
              ]),
            ),
        ]),
        const SizedBox(height: 12),
        TextField(
            controller: note,
            maxLength: 120,
            decoration: InputDecoration(
                hintText: 'Nota opcional (qué ha pasado, cómo duermes…)',
                suffixIcon: IconButton(icon: const Icon(Icons.check), onPressed: _saveNote))),
        const SizedBox(height: 8),
        Text(avg < 0 ? 'Aún no hay datos de los últimos 30 días' : 'Media de 30 días: ${moodFaces[avg]} ${moodLabels[avg]}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text('Últimos 14 días'),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final d in days)
            SizedBox(
              width: 38,
              child: Column(children: [
                Text(all[dayKey(d)] == null ? '·' : moodFaces[(all[dayKey(d)] as Map)['m'] as int],
                    style: const TextStyle(fontSize: 24)),
                Text('${d.day}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
            ),
        ]),
        const Divider(height: 28),
        for (final k in keys.take(30))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(moodFaces[(all[k] as Map)['m'] as int], style: const TextStyle(fontSize: 28)),
            title: Text('${_nice(k)} · ${moodLabels[(all[k] as Map)['m'] as int]}'),
            subtitle: ((all[k] as Map)['n'] as String).isEmpty ? null : Text((all[k] as Map)['n'] as String),
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
