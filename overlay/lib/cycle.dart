import 'package:flutter/material.dart';
import 'data.dart';

DateTime _day(DateTime x) => DateTime.utc(x.year, x.month, x.day);
DateTime _ms(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
const _months = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];

/// Cálculos del ciclo a partir de los registros.
class _Info {
  final List<Map<String, dynamic>> cs;
  _Info(this.cs);

  // duración media del ciclo (de inicio a inicio), por defecto 28
  int get len {
    final l = <int>[];
    for (int i = 1; i < cs.length; i++) {
      final d = _ms(cs[i]['s'] as int).difference(_ms(cs[i - 1]['s'] as int)).inDays;
      if (d >= 18 && d <= 45) l.add(d);
    }
    if (l.isEmpty) return 28;
    final last = l.length > 6 ? l.sublist(l.length - 6) : l;
    return (last.reduce((a, b) => a + b) / last.length).round();
  }

  // duración media de la regla, por defecto 5
  int get dur {
    if (cs.isEmpty) return 5;
    final l = cs.map((c) => c['d'] as int).toList();
    return (l.reduce((a, b) => a + b) / l.length).round();
  }

  // inicio estimado de la regla k-ésima siguiente (si hay ovulación registrada, = ovulación + 14)
  DateTime? nextStart(int k) {
    if (cs.isEmpty) return null;
    final ls = _ms(cs.last['s'] as int);
    final ov = cs.last['ov'] as int?;
    final n1 = ov != null ? _ms(ov).add(const Duration(days: 14)) : ls.add(Duration(days: len));
    return n1.add(Duration(days: len * (k - 1)));
  }

  // 'period' | 'ov' | 'pred' | 'ovp' | 'fertile' | ''
  String status(DateTime x) {
    if (cs.isEmpty) return '';
    for (final c in cs) {
      final s = _ms(c['s'] as int);
      if (!x.isBefore(s) && x.isBefore(s.add(Duration(days: c['d'] as int)))) return 'period';
    }
    for (final c in cs) {
      final ov = c['ov'] as int?;
      if (ov != null && _ms(ov) == x) return 'ov';
    }
    for (int k = 1; k <= 6; k++) {
      final ns = nextStart(k)!;
      if (!x.isBefore(ns) && x.isBefore(ns.add(Duration(days: dur)))) return 'pred';
      final ov = ns.subtract(const Duration(days: 14));
      if (x == ov) return 'ovp';
      if (!x.isBefore(ov.subtract(const Duration(days: 5))) &&
          !x.isAfter(ov.add(const Duration(days: 1)))) {
        return 'fertile';
      }
    }
    return '';
  }

  String phase(DateTime t) {
    if (cs.isEmpty) return 'Registra tu primera regla para ver las estimaciones';
    final ls = _ms(cs.last['s'] as int);
    final day = t.difference(ls).inDays + 1;
    final st = status(t);
    if (st == 'period') return '🩸 Menstruación · día $day';
    if (st == 'ov' || st == 'ovp') return '🥚 Ovulación probable hoy';
    if (st == 'fertile') return '🌱 Ventana fértil · día $day del ciclo';
    final ov = nextStart(1)!.subtract(const Duration(days: 14));
    return t.isBefore(ov) ? 'Fase folicular · día $day' : 'Fase lútea · día $day';
  }
}

/// Registro de menstruación y ovulación con estimaciones.
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
    l.add({'s': day.millisecondsSinceEpoch, 'd': _Info(l).dur, 'ov': null});
    l.sort((a, b) => (a['s'] as int).compareTo(b['s'] as int));
    store.saveCycles(l);
    setState(() {});
  }

  void _end() {
    final l = store.cycles();
    if (l.isEmpty) return;
    final days = _day(DateTime.now()).difference(_ms(l.last['s'] as int)).inDays + 1;
    if (days < 1 || days > 15) {
      _msg('La última regla empezó hace demasiado tiempo');
      return;
    }
    l.last['d'] = days;
    store.saveCycles(l);
    setState(() {});
  }

  void _ovulation() {
    final l = store.cycles();
    if (l.isEmpty) {
      _msg('Registra primero el inicio de tu regla');
      return;
    }
    final today = _day(DateTime.now());
    if (today.difference(_ms(l.last['s'] as int)).inDays < 0) return;
    l.last['ov'] = today.millisecondsSinceEpoch;
    store.saveCycles(l);
    setState(() {});
  }

  void _delete(int i) {
    final l = store.cycles()..removeAt(i);
    store.saveCycles(l);
    setState(() {});
  }

  Widget _cell(DateTime d, _Info info, DateTime today) {
    Color? bg;
    Color fg = Colors.black87;
    switch (info.status(d)) {
      case 'period':
        bg = const Color(0xFFE8445A);
        fg = Colors.white;
        break;
      case 'pred':
        bg = const Color(0x66E8445A);
        break;
      case 'ov':
      case 'ovp':
        bg = const Color(0xFF2EC4B6);
        fg = Colors.white;
        break;
      case 'fertile':
        bg = const Color(0xFFB7E4C7);
        break;
      default:
        break;
    }
    return Container(
      margin: const EdgeInsets.all(2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: d == today ? Border.all(color: kInk, width: 2) : null),
      child: Text('${d.day}', style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
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
        for (int d = 1; d <= days; d++)
          _cell(DateTime.utc(month.year, month.month, d), info, today),
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
    final info = _Info(cs);
    final today = _day(DateTime.now());
    String next = '', ovTxt = '';
    if (cs.isNotEmpty) {
      int k = 1;
      while (k < 8 && info.nextStart(k)!.isBefore(today)) {
        k++;
      }
      final ns = info.nextStart(k)!;
      final ov = ns.subtract(const Duration(days: 14));
      final left = ns.difference(today).inDays;
      next = 'Próxima regla (estimada): ${_fmt(ns)} · ${left == 0 ? 'hoy' : 'en $left d'}';
      ovTxt =
          'Ovulación estimada: ${_fmt(ov)}\nVentana fértil: ${_fmt(ov.subtract(const Duration(days: 5)))} – ${_fmt(ov.add(const Duration(days: 1)))}';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ciclo 🌸')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(info.phase(today), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (cs.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(next),
          Text(ovTxt),
          Text('Ciclo medio: ${info.len} días · regla media: ${info.dur} días',
              style: const TextStyle(color: Colors.black54)),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(onPressed: _start, child: const Text('🩸 Empezó mi regla')),
          FilledButton.tonal(onPressed: _end, child: const Text('Terminó hoy')),
          FilledButton.tonal(onPressed: _ovulation, child: const Text('🥚 Ovulación hoy')),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              onPressed: () => setState(
                  () => month = DateTime.utc(month.year, month.month - 1, 1)),
              icon: const Icon(Icons.chevron_left)),
          Text('${_months[month.month - 1]} ${month.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          IconButton(
              onPressed: () => setState(
                  () => month = DateTime.utc(month.year, month.month + 1, 1)),
              icon: const Icon(Icons.chevron_right)),
        ]),
        _calendar(info),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 4, children: [
          _dot(const Color(0xFFE8445A), 'Regla'),
          _dot(const Color(0x66E8445A), 'Regla estimada'),
          _dot(const Color(0xFFB7E4C7), 'Ventana fértil'),
          _dot(const Color(0xFF2EC4B6), 'Ovulación'),
        ]),
        const SizedBox(height: 8),
        const Text(
            'Las fechas son estimaciones. No sirven como método anticonceptivo ni como diagnóstico. Los datos se guardan solo en tu móvil.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const Divider(height: 28),
        for (int i = cs.length - 1; i >= 0; i--)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Regla: ${_fmt(_ms(cs[i]['s'] as int))} · ${cs[i]['d']} días'),
            subtitle: Text([
              if (cs[i]['ov'] != null) 'Ovulación: ${_fmt(_ms(cs[i]['ov'] as int))}',
              if (i + 1 < cs.length)
                'Ciclo: ${_ms(cs[i + 1]['s'] as int).difference(_ms(cs[i]['s'] as int)).inDays} días',
            ].join(' · ')),
            trailing: IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: () => _delete(i)),
          ),
      ]),
    );
  }
}
