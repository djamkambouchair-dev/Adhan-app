import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(const AdhanApp());

class AdhanApp extends StatelessWidget {
  const AdhanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0B6E4F),
        useMaterial3: true,
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Coordinates? _coords;
  PrayerTimes? _times;
  String? _error;
  bool _loading = true;
  Timer? _timer;
  DateTime _now = DateTime.now();
  int _day = DateTime.now().day;

  CalculationParameters _params() {
    final p = CalculationMethod.muslim_world_league.getParameters();
    p.madhab = Madhab.shafi;
    return p;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final n = DateTime.now();
      if (n.day != _day && _coords != null) {
        _day = n.day;
        _times = PrayerTimes.today(_coords!, _params());
      }
      setState(() => _now = n);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'فعّل خدمة الموقع (GPS) في هاتفك ثم أعد المحاولة';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'لم يتم السماح بالوصول للموقع. فعّله من إعدادات التطبيق';
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 30),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        throw 'تعذر تحديد موقعك. جرّب في مكان مفتوح';
      }
      final c = Coordinates(pos.latitude, pos.longitude);
      setState(() {
        _coords = c;
        _times = PrayerTimes.today(c, _params());
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmt(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'ص' : 'م'}';
  }

  String _countdown(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = _times;
    final items = t == null
        ? <MapEntry<String, DateTime>>[]
        : <MapEntry<String, DateTime>>[
            MapEntry('الفجر', t.fajr),
            MapEntry('الشروق', t.sunrise),
            MapEntry('الظهر', t.dhuhr),
            MapEntry('العصر', t.asr),
            MapEntry('المغرب', t.maghrib),
            MapEntry('العشاء', t.isha),
          ];
    MapEntry<String, DateTime>? next;
    for (final e in items) {
      if (e.key != 'الشروق' && e.value.isAfter(_now)) {
        next = e;
        break;
      }
    }
    final nx = next;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    nx == null
                        ? 'انتهت صلوات اليوم'
                        : 'الصلاة القادمة: ${nx.key}',
                    style: const TextStyle(fontSize: 22),
                  ),
                  if (nx != null)
                    Text(
                      _countdown(nx.value.difference(_now)),
                      style: const TextStyle(
                          fontSize: 44, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final e in items)
            ListTile(
              selected: nx != null && e.key == nx.key,
              title: Text(e.key, style: const TextStyle(fontSize: 22)),
              trailing: Text(_fmt(e.value),
                  style: const TextStyle(fontSize: 22)),
            ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'طريقة رابطة العالم الإسلامي\n'
              '${_coords?.latitude.toStringAsFixed(2)}, '
              '${_coords?.longitude.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: body,
    );
  }
}
