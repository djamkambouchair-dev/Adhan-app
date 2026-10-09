import 'dart:async';
import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const AdhanApp());

const names = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

final Map<String, CalculationMethod> methods = {
  'رابطة العالم الإسلامي': CalculationMethod.muslim_world_league,
  'أم القرى (مكة)': CalculationMethod.umm_al_qura,
  'الهيئة المصرية': CalculationMethod.egyptian,
  'جامعة كراتشي': CalculationMethod.karachi,
  'أمريكا الشمالية (ISNA)': CalculationMethod.north_america,
  'الإمارات': CalculationMethod.dubai,
  'قطر': CalculationMethod.qatar,
  'الكويت': CalculationMethod.kuwait,
  'سنغافورة': CalculationMethod.singapore,
};

class Place {
  final String name;
  final String sub;
  final double lat;
  final double lng;
  final bool gps;
  final int offsetSec;

  const Place({
    required this.name,
    required this.sub,
    required this.lat,
    required this.lng,
    this.gps = false,
    this.offsetSec = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sub': sub,
        'lat': lat,
        'lng': lng,
        'gps': gps,
        'off': offsetSec,
      };

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        name: j['name'] as String,
        sub: j['sub'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        gps: j['gps'] as bool,
        offsetSec: (j['off'] as num).toInt(),
      );

  Place withOffset(int s) => Place(
        name: name,
        sub: sub,
        lat: lat,
        lng: lng,
        gps: gps,
        offsetSec: s,
      );
}

Future<int?> fetchOffset(double lat, double lng) async {
  try {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lng',
      'current': 'temperature_2m',
      'timezone': 'auto',
    });
    final r = await http.get(uri).timeout(const Duration(seconds: 15));
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['utc_offset_seconds'] as num?)?.toInt();
  } catch (_) {
    return null;
  }
}

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
  Place? _place;
  String _method = 'رابطة العالم الإسلامي';
  bool _hanafi = false;
  List<DateTime> _times = [];
  DateTime? _tomorrowFajr;
  int _calcDay = -1;
  DateTime _wallNow = DateTime.now().toUtc();
  Timer? _timer;
  bool _busy = false;
  String? _msg;

  Duration _offset(Place p) =>
      p.gps ? DateTime.now().timeZoneOffset : Duration(seconds: p.offsetSec);

  DateTime _wall(DateTime t, Duration off) =>
      t.isUtc ? t : t.toUtc().add(off);

  @override
  void initState() {
    super.initState();
    _init();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final p = _place;
      final now = DateTime.now()
          .toUtc()
          .add(p == null ? Duration.zero : _offset(p));
      setState(() {
        _wallNow = now;
        if (p != null && now.day != _calcDay) _recalc();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('place');
    final m = sp.getString('method');
    if (m != null && methods.containsKey(m)) _method = m;
    _hanafi = sp.getBool('hanafi') ?? false;
    if (raw != null) {
      try {
        _place = Place.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _recalc());
    final pl = _place;
    if (pl != null && !pl.gps) {
      final off = await fetchOffset(pl.lat, pl.lng);
      if (off != null && off != pl.offsetSec && mounted) {
        _place = pl.withOffset(off);
        await _savePlace();
        setState(() => _recalc());
      }
    }
  }

  Future<void> _savePlace() async {
    final sp = await SharedPreferences.getInstance();
    final p = _place;
    if (p != null) await sp.setString('place', jsonEncode(p.toJson()));
  }

  Future<void> _saveSettings() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('method', _method);
    await sp.setBool('hanafi', _hanafi);
  }

  void _recalc() {
    final p = _place;
    if (p == null) {
      _times = [];
      _tomorrowFajr = null;
      return;
    }
    final off = _offset(p);
    final now = DateTime.now().toUtc().add(off);
    final coords = Coordinates(p.lat, p.lng);
    final params = methods[_method]!.getParameters();
    params.madhab = _hanafi ? Madhab.hanafi : Madhab.shafi;
    final today = PrayerTimes(coords, DateComponents.from(now), params,
        utcOffset: off);
    final tmr = PrayerTimes(
        coords, DateComponents.from(now.add(const Duration(days: 1))), params,
        utcOffset: off);
    _times = [
      _wall(today.fajr, off),
      _wall(today.sunrise, off),
      _wall(today.dhuhr, off),
      _wall(today.asr, off),
      _wall(today.maghrib, off),
      _wall(today.isha, off),
    ];
    _tomorrowFajr = _wall(tmr.fajr, off);
    _calcDay = now.day;
    _wallNow = now;
  }

  Future<void> _useGps() async {
    setState(() {
      _busy = true;
      _msg = null;
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
      if (pos == null) throw 'تعذر تحديد موقعك. جرّب في مكان مفتوح';
      _place = Place(
        name: 'موقعي الحالي',
        sub: '',
        lat: pos.latitude,
        lng: pos.longitude,
        gps: true,
      );
      await _savePlace();
      if (!mounted) return;
      setState(() {
        _recalc();
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msg = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _pickCity() async {
    final res = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
    if (res == null || !mounted) return;
    setState(() {
      _busy = true;
      _msg = null;
    });
    final off = await fetchOffset(res.lat, res.lng);
    _place = res.withOffset(off ?? DateTime.now().timeZoneOffset.inSeconds);
    await _savePlace();
    if (!mounted) return;
    setState(() {
      _recalc();
      _busy = false;
    });
  }

  void _placeSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('ابحث عن مدينة أو بلدية'),
              onTap: () {
                Navigator.pop(ctx);
                _pickCity();
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('موقعي الحالي (GPS)'),
              onTap: () {
                Navigator.pop(ctx);
                _useGps();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _settings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('طريقة الحساب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                isExpanded: true,
                value: _method,
                items: [
                  for (final k in methods.keys)
                    DropdownMenuItem(value: k, child: Text(k)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _method = v;
                    _recalc();
                  });
                  setS(() {});
                  _saveSettings();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('المذهب الحنفي في العصر'),
                value: _hanafi,
                onChanged: (v) {
                  setState(() {
                    _hanafi = v;
                    _recalc();
                  });
                  setS(() {});
                  _saveSettings();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'ص' : 'م'}';
  }

  String _countdown(Duration d) {
    final x = d.isNegative ? Duration.zero : d;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(x.inHours)}:${two(x.inMinutes % 60)}:${two(x.inSeconds % 60)}';
  }

  Widget _welcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mosque, size: 72, color: Color(0xFF0B6E4F)),
            const SizedBox(height: 16),
            const Text('بسم الله',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('اختر موقعك لحساب مواقيت الصلاة',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            if (_busy)
              const CircularProgressIndicator()
            else ...[
              FilledButton.icon(
                onPressed: _pickCity,
                icon: const Icon(Icons.search),
                label: const Text('ابحث عن مدينة أو بلدية'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _useGps,
                icon: const Icon(Icons.my_location),
                label: const Text('استخدم موقعي الحالي'),
              ),
            ],
            if (_msg != null) ...[
              const SizedBox(height: 16),
              Text(_msg!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _main() {
    if (_times.length != 6) {
      return const Center(child: CircularProgressIndicator());
    }
    int nextIdx = -1;
    for (final i in [0, 2, 3, 4, 5]) {
      if (_times[i].isAfter(_wallNow)) {
        nextIdx = i;
        break;
      }
    }
    final tomorrow = nextIdx == -1;
    final target = tomorrow
        ? (_tomorrowFajr ?? _times[0].add(const Duration(days: 1)))
        : _times[nextIdx];
    final label = tomorrow ? 'الفجر (غداً)' : names[nextIdx];
    final left = target.difference(_wallNow);
    final p = _place!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B6E4F), Color(0xFF12A37A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text('الصلاة القادمة',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(_countdown(left),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0x33000000))),
          leading: Icon(p.gps ? Icons.my_location : Icons.location_on),
          title: Text(p.name),
          subtitle: p.sub.isEmpty ? null : Text(p.sub),
          trailing: const Icon(Icons.edit_location_alt),
          onTap: _placeSheet,
        ),
        if (_busy) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        for (int i = 0; i < names.length; i++)
          ListTile(
            selected: !tomorrow && i == nextIdx,
            title: Text(names[i], style: const TextStyle(fontSize: 22)),
            trailing: Text(_fmt(_times[i]),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'طريقة الحساب: $_method',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _settings),
        ],
      ),
      body: _place == null ? _welcome() : _main(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _c = TextEditingController();
  Timer? _deb;
  List<Place> _res = [];
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _deb?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _deb?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _res = [];
        _err = null;
      });
      return;
    }
    _deb = Timer(const Duration(milliseconds: 500), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': q,
        'count': '15',
        'language': 'ar',
        'format': 'json',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final list = (data['results'] as List?) ?? [];
      final out = list.map((e) {
        final m = e as Map<String, dynamic>;
        final parts = <String>[
          if (m['admin1'] != null) m['admin1'].toString(),
          if (m['country'] != null) m['country'].toString(),
        ];
        return Place(
          name: m['name'].toString(),
          sub: parts.join('، '),
          lat: (m['latitude'] as num).toDouble(),
          lng: (m['longitude'] as num).toDouble(),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _res = out;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذر البحث. تأكد من اتصالك بالإنترنت';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _c,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'اكتب اسم المدينة أو البلدية',
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_err!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final p in _res)
                  ListTile(
                    leading: const Icon(Icons.location_city),
                    title: Text(p.name),
                    subtitle: p.sub.isEmpty ? null : Text(p.sub),
                    onTap: () => Navigator.pop(context, p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
