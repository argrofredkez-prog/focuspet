import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';

// ---------- meta diaria, racha y logros ----------
String _dk(DateTime d) => '${d.year}${d.month}${d.day}';
int studyOn(DateTime d) => store.p.getInt('d${_dk(d)}_0') ?? 0;
int get goalMin => store.p.getInt('goal_min') ?? 120;

double _c01(double x) => min(1.0, max(0.0, x));
int _ci(int x, int lo, int hi) => min(hi, max(lo, x));

String fmtMin(int m) {
  if (m < 60) return '$m min';
  return m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60} min';
}

int streakDays() {
  var n = 0;
  var d = DateTime.now();
  if (studyOn(d) == 0) d = d.subtract(const Duration(days: 1));
  while (n < 3650 && studyOn(d) > 0) {
    n++;
    d = d.subtract(const Duration(days: 1));
  }
  return n;
}

int bestStreakDays() {
  var best = 0, cur = 0;
  final today = DateTime.now();
  for (int i = 400; i >= 0; i--) {
    if (studyOn(today.subtract(Duration(days: i))) > 0) {
      cur++;
      best = max(best, cur);
    } else {
      cur = 0;
    }
  }
  return best;
}

/// Barra de progreso del día (inicio)
class GoalBar extends StatelessWidget {
  final Color ink;
  final VoidCallback onTap;
  const GoalBar({super.key, required this.ink, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = studyOn(DateTime.now());
    final g = goalMin;
    final p = _c01(t / g);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
        child: Column(children: [
          Row(children: [
            Text('🎯 Hoy ${fmtMin(t)} / ${fmtMin(g)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
            const Spacer(),
            Text('🔥 ${streakDays()}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ink)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 8,
              color: p >= 1 ? const Color(0xFF4CD964) : ink,
              backgroundColor: ink.withAlpha(50),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------- pantalla de progreso ----------
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressState();
}

class _ProgressState extends State<ProgressScreen> {
  static const _days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = studyOn(now);
    final goal = goalMin;
    final week = [for (int i = 6; i >= 0; i--) studyOn(now.subtract(Duration(days: i)))];
    final labels = [for (int i = 6; i >= 0; i--) _days[now.subtract(Duration(days: i)).weekday - 1]];
    final total = store.minsTotal(0);
    final best = bestStreakDays();
    final streak = streakDays();
    final weekTotal = week.fold<int>(0, (a, b) => a + b);
    final achievements = <List<Object>>[
      ['🌱', 'Primer paso', _ci(total, 0, 1), 1, '1 sesión'],
      ['⏱️', '10 horas de enfoque', _ci(total, 0, 600), 600, '10 h'],
      ['📚', '50 horas de enfoque', _ci(total, 0, 3000), 3000, '50 h'],
      ['🏆', '100 horas de enfoque', _ci(total, 0, 6000), 6000, '100 h'],
      ['🔥', 'Racha de 3 días', _ci(best, 0, 3), 3, '3 días'],
      ['🔥', 'Racha de 7 días', _ci(best, 0, 7), 7, '7 días'],
      ['🌋', 'Racha de 30 días', _ci(best, 0, 30), 30, '30 días'],
      ['🎯', 'Meta de hoy', _ci(today, 0, goal), goal, fmtMin(goal)],
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso 🏆')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: _c01(today / goal),
                      strokeWidth: 11,
                      backgroundColor: cs.primary.withAlpha(40),
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(fmtMin(today), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('de ${fmtMin(goal)}', style: const TextStyle(fontSize: 12)),
                  ]),
                ]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('🔥 $streak días de racha', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('🏅 Mejor racha: $best días'),
                  Text('📅 Esta semana: ${fmtMin(weekTotal)}'),
                  Text('⏳ Total: ${fmtMin(total)}'),
                ]),
              ),
            ]),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🎯 Meta diaria: ${fmtMin(goal)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              Slider(
                value: min(360.0, max(30.0, goal.toDouble())),
                min: 30,
                max: 360,
                divisions: 22,
                label: fmtMin(goal),
                onChanged: (v) => setState(() => store.p.setInt('goal_min', v.round())),
              ),
            ]),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Últimos 7 días', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SizedBox(
                height: 170,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WeekPainter(week, labels, goal, cs.primary, const Color(0xFF4CD964), cs.onSurface),
                ),
              ),
            ]),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Constancia (28 días)', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (int i = 27; i >= 0; i--)
                  Tooltip(
                    message: fmtMin(studyOn(now.subtract(Duration(days: i)))),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: studyOn(now.subtract(Duration(days: i))) == 0
                            ? cs.onSurface.withAlpha(25)
                            : cs.primary.withAlpha((70 + 185 * _c01(studyOn(now.subtract(Duration(days: i))) / goal)).round()),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text('Logros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ),
        for (final a in achievements)
          Card(
            child: ListTile(
              leading: Text(a[0] as String, style: const TextStyle(fontSize: 28)),
              title: Text(a[1] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: (a[2] as int) / (a[3] as int),
                    minHeight: 7,
                    color: (a[2] as int) >= (a[3] as int) ? const Color(0xFF4CD964) : cs.primary,
                  ),
                ),
              ),
              trailing: (a[2] as int) >= (a[3] as int)
                  ? const Icon(Icons.check_circle, color: Color(0xFF4CD964))
                  : Text(a[4] as String, style: const TextStyle(fontSize: 12)),
            ),
          ),
      ]),
    );
  }
}

class _WeekPainter extends CustomPainter {
  final List<int> v;
  final List<String> labels;
  final int goal;
  final Color bar, ok, text;
  _WeekPainter(this.v, this.labels, this.goal, this.bar, this.ok, this.text);

  void _t(Canvas c, String s, Offset center, double fs, Color col, {bool bold = false}) {
    final tp = TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontSize: fs, color: col, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas c, Size s) {
    final mx = max(goal, v.fold<int>(0, max)).toDouble();
    final base = s.height - 22;
    final top = 18.0;
    final bw = s.width / (v.length * 1.7);
    final gap = (s.width - bw * v.length) / (v.length + 1);
    final gy = base - (goal / mx) * (base - top);
    for (double x = 0; x < s.width; x += 9) {
      c.drawLine(Offset(x, gy), Offset(x + 4, gy), Paint()
        ..color = text.withAlpha(110)
        ..strokeWidth = 1.2);
    }
    for (int i = 0; i < v.length; i++) {
      final x = gap + i * (bw + gap);
      final h = max(3.0, v[i] / mx * (base - top));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, base - h, bw, h), const Radius.circular(7)),
          Paint()..color = v[i] >= goal ? ok : bar);
      _t(c, labels[i], Offset(x + bw / 2, base + 12), 12, text, bold: i == v.length - 1);
      if (v[i] > 0) _t(c, '${v[i]}', Offset(x + bw / 2, base - h - 8), 10, text);
    }
  }

  @override
  bool shouldRepaint(_WeekPainter o) => true;
}
