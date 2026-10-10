import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'main.dart';

const gregMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const occasions = [
  [1, 1, 'رأس السنة الهجرية'],
  [1, 10, 'يوم عاشوراء'],
  [3, 12, 'المولد النبوي الشريف'],
  [7, 27, 'ذكرى الإسراء والمعراج'],
  [8, 15, 'ليلة النصف من شعبان'],
  [9, 1, 'أول رمضان'],
  [9, 27, 'ليلة القدر'],
  [10, 1, 'عيد الفطر'],
  [12, 9, 'يوم عرفة'],
  [12, 10, 'عيد الأضحى'],
];

int hijriToJdn(int y, int m, int d) =>
    d + (29.5 * (m - 1)).ceil() + (y - 1) * 354 + (3 + 11 * y) ~/ 30 + 1948439;

DateTime gregFromJdn(int jd) {
  final a = jd + 32044;
  final b = (4 * a + 3) ~/ 146097;
  final c = a - (146097 * b) ~/ 4;
  final d = (4 * c + 3) ~/ 1461;
  final e = c - (1461 * d) ~/ 4;
  final m = (5 * e + 2) ~/ 153;
  final day = e - (153 * m + 2) ~/ 5 + 1;
  final month = m + 3 - 12 * (m ~/ 10);
  final year = 100 * b + d - 4800 + m ~/ 10;
  return DateTime.utc(year, month, day);
}

BoxDecoration pageBg(AppPalette c) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: c.bg,
        stops: const [0.0, 0.5, 1.0],
      ),
    );

// ======================= الجدول الشهري =======================
class MonthlyPage extends StatefulWidget {
  final Place place;
  final String method;
  final bool hanafi;
  final bool use24;
  const MonthlyPage({
    super.key,
    required this.place,
    required this.method,
    required this.hanafi,
    required this.use24,
  });

  @override
  State<MonthlyPage> createState() => _MonthlyPageState();
}

class _MonthlyPageState extends State<MonthlyPage> {
  late final Duration _off;
  late final DateTime _today;
  late int _y;
  late int _m;

  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _off =
        p.gps ? DateTime.now().timeZoneOffset : Duration(seconds: p.offsetSec);
    _today = DateTime.now().toUtc().add(_off);
    _y = _today.year;
    _m = _today.month;
  }

  void _shift(int delta) {
    setState(() {
      _m += delta;
      if (_m > 12) {
        _m = 1;
        _y++;
      }
      if (_m < 1) {
        _m = 12;
        _y--;
      }
    });
  }

  DateTime _wall(DateTime t) => t.isUtc ? t : t.toUtc().add(_off);

  List<List<DateTime>> _compute() {
    final p = widget.place;
    final coords = Coordinates(p.lat, p.lng);
    final params = methods[widget.method]!.getParameters();
    params.madhab = widget.hanafi ? Madhab.hanafi : Madhab.shafi;
    final count = DateTime.utc(_y, _m + 1, 0).day;
    final out = <List<DateTime>>[];
    for (int d = 1; d <= count; d++) {
      final pt = PrayerTimes(
        coords,
        DateComponents.from(DateTime.utc(_y, _m, d)),
        params,
        utcOffset: _off,
      );
      out.add([
        _wall(pt.fajr),
        _wall(pt.sunrise),
        _wall(pt.dhuhr),
        _wall(pt.asr),
        _wall(pt.maghrib),
        _wall(pt.isha),
      ]);
    }
    return out;
  }

  String _fmt(DateTime t) {
    final mm = t.minute.toString().padLeft(2, '0');
    if (widget.use24) return '${t.hour.toString().padLeft(2, '0')}:$mm';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:$mm';
  }

  Widget _line(int day, List<DateTime> t, AppPalette c) {
    final date = DateTime.utc(_y, _m, day);
    final isToday =
        _y == _today.year && _m == _today.month && day == _today.day;
    final fri = date.weekday == DateTime.friday;
    final fg = isToday ? Colors.white : c.text;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      color: isToday ? const Color(0xFF0A9A0A) : (fri ? c.pill : c.row),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(arDigits('$day'),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: fg)),
                Text(weekdayNames[date.weekday - 1],
                    style: TextStyle(
                        fontSize: 11,
                        color: isToday ? Colors.white70 : c.soft)),
              ],
            ),
          ),
          for (final x in t)
            Expanded(
              child: Center(
                child: Text(_fmt(x),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fg)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = palettes[themeIdx.value];
    final data = _compute();
    const heads = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    return Scaffold(
      appBar: AppBar(title: Text('المواقيت - ${widget.place.name}')),
      body: Container(
        decoration: pageBg(c),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: c.text, size: 32),
                    onPressed: () => _shift(-1),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('${gregMonths[_m - 1]} $_y',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: c.text)),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: c.text, size: 32),
                    onPressed: () => _shift(1),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              color: c.pill,
              child: Row(
                children: [
                  const SizedBox(width: 64),
                  for (final h in heads)
                    Expanded(
                      child: Center(
                        child: Text(h,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: c.text)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: data.length,
                itemBuilder: (ctx, i) => _line(i + 1, data[i], c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= التقويم الهجري =======================
class HijriCalendarPage extends StatefulWidget {
  final int hcorr;
  final DateTime today;
  const HijriCalendarPage({
    super.key,
    required this.hcorr,
    required this.today,
  });

  @override
  State<HijriCalendarPage> createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  late final List<int> _t;
  late int _y;
  late int _m;

  @override
  void initState() {
    super.initState();
    _t = hijriOf(widget.today, widget.hcorr);
    _y = _t[0];
    _m = _t[1];
  }

  void _shift(int delta) {
    setState(() {
      _m += delta;
      if (_m > 12) {
        _m = 1;
        _y++;
      }
      if (_m < 1) {
        _m = 12;
        _y--;
      }
    });
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final c = palettes[themeIdx.value];
    final startJ = hijriToJdn(_y, _m, 1);
    final nextJ =
        _m == 12 ? hijriToJdn(_y + 1, 1, 1) : hijriToJdn(_y, _m + 1, 1);
    final len = nextJ - startJ;
    final firstG = startJ - widget.hcorr;
    final startCol = (firstG + 1) % 7;
    final g1 = gregFromJdn(firstG);
    final g2 = gregFromJdn(firstG + len - 1);
    const dayHeads = [
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];

    final cells = <Widget>[];
    for (int i = 0; i < startCol; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= len; d++) {
      final isToday = _y == _t[0] && _m == _t[1] && d == _t[2];
      final g = gregFromJdn(firstG + d - 1);
      cells.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFF0A9A0A) : c.row,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(arDigits('$d'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isToday ? Colors.white : c.text)),
              Text('${g.day}',
                  style: TextStyle(
                      fontSize: 10,
                      color: isToday ? Colors.white70 : c.soft)),
            ],
          ),
        ),
      );
    }

    final today0 = DateTime.utc(
        widget.today.year, widget.today.month, widget.today.day);
    final items = <Widget>[];
    for (final o in occasions) {
      final om = o[0] as int;
      final od = o[1] as int;
      final title = o[2] as String;
      final gd = gregFromJdn(hijriToJdn(_y, om, od) - widget.hcorr);
      final past = gd.isBefore(today0);
      items.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.row,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_two(gd.day)}/${_two(gd.month)}/${gd.year}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      fontSize: 13, color: past ? c.soft : c.text)),
              const SizedBox(height: 2),
              Text('$od ${hijriMonths[om - 1]} : $title',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: past ? c.soft : c.text)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('التقويم الهجري')),
      body: Container(
        decoration: pageBg(c),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_right, color: c.text, size: 32),
                  onPressed: () => _shift(-1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(arDigits('${hijriMonths[_m - 1]} $_y'),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: c.text)),
                      Text(
                          '${gregMonths[g1.month - 1]} ${g1.year} - ${gregMonths[g2.month - 1]} ${g2.year}',
                          style: TextStyle(fontSize: 13, color: c.soft)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_left, color: c.text, size: 32),
                  onPressed: () => _shift(1),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  for (final h in dayHeads)
                    Expanded(
                      child: Center(
                        child: Text(h,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: c.text)),
                      ),
                    ),
                ],
              ),
            ),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: cells,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(arDigits('مناسبات عام $_y هـ'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: c.text)),
            ),
            const SizedBox(height: 4),
            ...items,
          ],
        ),
      ),
    );
  }
}
