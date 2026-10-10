import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'main.dart';

// [الشهر الهجري، اليوم] ؛ عناوينها في l10n بالمفاتيح oc0..oc9
const occasions = <List<int>>[
  [1, 1], [1, 10], [3, 12], [7, 27], [8, 15],
  [9, 1], [9, 27], [10, 1], [12, 9], [12, 10],
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

IconData prevIcon() => isAr ? Icons.chevron_right : Icons.chevron_left;
IconData nextIcon() => isAr ? Icons.chevron_left : Icons.chevron_right;

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

  DateTime _wall(DateTime x) => x.isUtc ? x : x.toUtc().add(_off);

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

  String _fmt(DateTime x) {
    final mm = x.minute.toString().padLeft(2, '0');
    if (widget.use24) return '${x.hour.toString().padLeft(2, '0')}:$mm';
    final h = x.hour % 12 == 0 ? 12 : x.hour % 12;
    return '$h:$mm';
  }

  Widget _line(int day, List<DateTime> tm, AppPalette c) {
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
                Text(abbr(weekdayNames[date.weekday - 1]),
                    style: TextStyle(
                        fontSize: 11,
                        color: isToday ? Colors.white70 : c.soft)),
              ],
            ),
          ),
          for (final x in tm)
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final pname = widget.place.gps ? t('my_location') : widget.place.name;
    return Scaffold(
      appBar: AppBar(title: Text(t('monthly_title', [pname]))),
      body: Container(
        decoration: pageBg(c),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(prevIcon(), color: c.text, size: 32),
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
                    icon: Icon(nextIcon(), color: c.text, size: 32),
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
                  for (int i = 0; i < 6; i++)
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(prayerName(i),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: c.text)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 24 + bottomInset),
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final startJ = hijriToJdn(_y, _m, 1);
    final nextJ =
        _m == 12 ? hijriToJdn(_y + 1, 1, 1) : hijriToJdn(_y, _m + 1, 1);
    final len = nextJ - startJ;
    final firstG = startJ - widget.hcorr;
    final startCol = (firstG + 1) % 7;
    final g1 = gregFromJdn(firstG);
    final g2 = gregFromJdn(firstG + len - 1);
    final wd = weekdayNames;
    final dayHeads = [wd[6], wd[0], wd[1], wd[2], wd[3], wd[4], wd[5]];

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
    for (int k = 0; k < occasions.length; k++) {
      final om = occasions[k][0];
      final od = occasions[k][1];
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
              Text(arDigits('$od ${hijriMonths[om - 1]} : ${t('oc$k')}'),
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
      appBar: AppBar(title: Text(t('hijri_calendar'))),
      body: Container(
        decoration: pageBg(c),
        child: ListView(
          padding: EdgeInsets.only(bottom: 32 + bottomInset),
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(prevIcon(), color: c.text, size: 32),
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
                  icon: Icon(nextIcon(), color: c.text, size: 32),
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(abbr(h),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: c.text)),
                        ),
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
              child: Text(t('occ_year', [arDigits('$_y')]),
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
