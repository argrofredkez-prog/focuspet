import 'package:flutter/material.dart';
import 'data.dart';

DateTime _day(DateTime x) => DateTime.utc(x.year, x.month, x.day);
DateTime _ms(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
String _short(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
String _fmt(DateTime d) => '${_short(d)}/${d.year}';
const _months = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];

// Fases del ciclo (día final de cada una): menstruación 1-5, folicular 6-14, ovulación 15-17, lútea 18-28
const phaseNames = ['Menstruación', 'Folicular', 'Ovulación', 'Lútea'];
const phaseEmoji = ['🩸', '🌱', '🥚', '🌙'];
const phaseEnds = [5, 14, 17, 28];
const phaseColors = [Color(0xFFE8445A), Color(0xFFBBDEFB), Color(0xFF2EC4B6), Color(0xFFD1C4E9)];
const _expected = Color(0x66E8445A);

int phaseOf(int idx) {
  for (int i = 0; i < 4; i++) {
    if (idx <= phaseEnds[i]) return i;
  }
  return -1;
}

class _Info {
  final List<DateTime> starts; // ordenadas
  _Info(this.starts);
  DateTime? get last => starts.isEmpty ? null : starts.last;

  // 0..3 = fase, 4 = regla esperada (días 28-30 tras el inicio), -1 = sin dato
  int status(DateTime x) {
    DateTime? s;
    for (final d in starts) {
      if (!d.isAfter(x)) s = d;
    }
    if (s == null) return -1;
    final idx = x.difference(s).inDays + 1;
    if (idx <= 28) return phaseOf(idx);
    if (s == starts.last && idx <= 31) return 4;
    return -1;
  }

  String phaseText(DateTime t) {
    final l = last;
    if (l == null) return 'Registra el primer día de tu regla para calcular tus fases';
    final idx = t.difference(l).inDays + 1;
    if (idx < 1) return '';
    if (idx <= 28) {
      final p = phaseOf(idx);
      return '${phaseEmoji[p]} ${phaseNames[p]} · día $idx';
    }
    if (idx <= 31) return '🩸 Regla esperada (entre los días 28 y 30) · día $idx';
    return 'Retraso: llevas $idx días de ciclo';
  }
}

/// Registro del ciclo: 4 fases calculadas desde el primer día de regla.
class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});
  @override
  State<CycleScreen> createState() => _CycleState();
}

class _CycleState extends State<CycleScreen> {
  DateTime month = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _start() async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (d == null) return;
    final l = store.cycles();
    final day = _day(d);
    if (l.any((c) => day.difference(_ms(c['s'] as int)).inDays.abs() < 10)) {
      _msg('Ya hay una regla registrada a menos de 10 días de esa fecha');
      return;
    }
    l.add({'s': day.millisecondsSinceEpoch});
    l.sort((a, b) => (a['s'] as int).compareTo(b['s'] as int));
    store.saveCycles(l);
    setState(() {});
  }

  void _delete(int i) {
    final l = store.cycles()..removeAt(i);
    store.saveCycles(l);
    setState(() {});
  }

  Widget _cell(DateTime d, _Info info, DateTime today) {
    final st = info.status(d);
    final bg = st == 4 ? _expected : (st >= 0 ? phaseColors[st] : null);
    final white = st == 0 || st == 2;
    return Container(
      margin: const EdgeInsets.all(2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: d == today ? Border.all(color: kInk, width: 2) : null),
      child: Text('${d.day}',
          style: TextStyle(color: white ? Colors.white : (bg == null ? null : Colors.black87), fontWeight: FontWeight.w600)),
    );
  }

  Widget _calendar(_Info info) {
    final days = DateTime.utc(month.year, month.month + 1, 0).day;
    final lead = month.weekday - 1;
    final today = _day(DateTime.now());
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        for (final w in const ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
          Center(child: Text(w, style: const TextStyle(fontWeight: FontWeight.bold))),
        for (int i = 0; i < lead; i++) const SizedBox(),
        for (int d = 1; d <= days; d++) _cell(DateTime.utc(month.year, month.month, d), info, today),
      ],
    );
  }

  Widget _dot(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(fontSize: 12)),
      ]);

  @override
  Widget build(BuildContext context) {
    final cs = store.cycles();
    final info = _Info([for (final c in cs) _ms(c['s'] as int)]);
    final today = _day(DateTime.now());
    final last = info.last;
    return Scaffold(
      appBar: AppBar(title: const Text('Ciclo 🌸')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(info.phaseText(today), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (last != null) ...[
          const SizedBox(height: 8),
          for (int p = 0; p < 4; p++)
            Text(
                '${phaseEmoji[p]} ${phaseNames[p]}: días ${p == 0 ? 1 : phaseEnds[p - 1] + 1}–${phaseEnds[p]} · '
                '${_short(last.add(Duration(days: p == 0 ? 0 : phaseEnds[p - 1])))} – ${_short(last.add(Duration(days: phaseEnds[p] - 1)))}'),
          const SizedBox(height: 6),
          Text(
              'Próxima regla estimada: ${_short(last.add(const Duration(days: 28)))} – ${_short(last.add(const Duration(days: 30)))}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 12),
        FilledButton(onPressed: _start, child: const Text('🩸 Empezó mi regla')),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              onPressed: () =>
                  setState(() => month = DateTime.utc(month.year, month.month - 1, 1)),
              icon: const Icon(Icons.chevron_left)),
          Text('${_months[month.month - 1]} ${month.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          IconButton(
              onPressed: () =>
                  setState(() => month = DateTime.utc(month.year, month.month + 1, 1)),
              icon: const Icon(Icons.chevron_right)),
        ]),
        _calendar(info),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 4, children: [
          for (int p = 0; p < 4; p++) _dot(phaseColors[p], phaseNames[p]),
          _dot(_expected, 'Regla esperada'),
        ]),
        const SizedBox(height: 8),
        const Text(
            'Las fases y fechas son estimaciones. No sirven como método anticonceptivo ni como diagnóstico. Los datos se guardan solo en tu móvil.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const Divider(height: 28),
        for (int i = cs.length - 1; i >= 0; i--)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Regla: ${_fmt(_ms(cs[i]['s'] as int))}'),
            subtitle: i + 1 < cs.length
                ? Text('Ciclo: ${_ms(cs[i + 1]['s'] as int).difference(_ms(cs[i]['s'] as int)).inDays} días')
                : null,
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(i)),
          ),
      ]),
    );
  }
}
