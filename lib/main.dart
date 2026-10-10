import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const names = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
const adhanNames = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
const weekdayNames = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const hijriMonths = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الثاني',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

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

// ---------------- الثيمات ----------------
class AppPalette {
  final String name;
  final List<Color> bg;
  final Color skyline;
  final Color pill;
  final Color row;
  final Color text;
  final Color soft;
  const AppPalette(
    this.name,
    this.bg,
    this.skyline,
    this.pill,
    this.row,
    this.text,
    this.soft,
  );
}

const palettes = <AppPalette>[
  AppPalette(
    'ذهبي',
    [Color(0xFFEFCF8A), Color(0xFFE6F2F3), Color(0xFFF3DAE5)],
    Color(0xFF7A5C2E),
    Color(0x66A8A58C),
    Color(0x55FFFFFF),
    Color(0xFF111111),
    Color(0xFF444444),
  ),
  AppPalette(
    'أخضر',
    [Color(0xFFBFE3C7), Color(0xFFE8F5EC), Color(0xFFF3F8F1)],
    Color(0xFF2F6B4B),
    Color(0x99FFFFFF),
    Color(0x66FFFFFF),
    Color(0xFF10261A),
    Color(0xFF3C5A4A),
  ),
  AppPalette(
    'ليلي',
    [Color(0xFF0B1B2B), Color(0xFF12263A), Color(0xFF1B2F44)],
    Color(0xFF5A7A9A),
    Color(0x33FFFFFF),
    Color(0x1AFFFFFF),
    Color(0xFFF2F2F2),
    Color(0xFFB8C4D0),
  ),
  AppPalette(
    'أزرق',
    [Color(0xFFBFDDF2), Color(0xFFE8F3FA), Color(0xFFF4F7FB)],
    Color(0xFF2D5F8A),
    Color(0x99FFFFFF),
    Color(0x66FFFFFF),
    Color(0xFF0F2233),
    Color(0xFF3D5B73),
  ),
  AppPalette(
    'وردي',
    [Color(0xFFF3C6D3), Color(0xFFFBE9EE), Color(0xFFFDF4F6)],
    Color(0xFF8A3A55),
    Color(0x99FFFFFF),
    Color(0x66FFFFFF),
    Color(0xFF2A1019),
    Color(0xFF6B3F50),
  ),
  AppPalette(
    'رملي',
    [Color(0xFFD9C3A5), Color(0xFFF1E8DA), Color(0xFFF8F3EA)],
    Color(0xFF5B4326),
    Color(0x99FFFFFF),
    Color(0x66FFFFFF),
    Color(0xFF261A0C),
    Color(0xFF6B5638),
  ),
  AppPalette(
    'ليلي أخضر',
    [Color(0xFF06241B), Color(0xFF0B3A2B), Color(0xFF104A38)],
    Color(0xFF3F8F72),
    Color(0x33FFFFFF),
    Color(0x1AFFFFFF),
    Color(0xFFEFF7F3),
    Color(0xFFA9C7BA),
  ),
];

bool isDarkTheme(int i) => i == 2 || i == 6;

final ValueNotifier<int> themeIdx = ValueNotifier<int>(0);

// ---------------- التاريخ الهجري ----------------
int _jdn(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final yy = y + 4800 - a;
  final mm = m + 12 * a - 3;
  return d +
      (153 * mm + 2) ~/ 5 +
      365 * yy +
      yy ~/ 4 -
      yy ~/ 100 +
      yy ~/ 400 -
      32045;
}

List<int> hijriOf(DateTime g, int corr) {
  final jd = _jdn(g.year, g.month, g.day) + corr;
  final l0 = jd - 1948440 + 10632;
  final n = (l0 - 1) ~/ 10631;
  final l1 = l0 - 10631 * n + 354;
  final j = ((10985 - l1) ~/ 5316) * ((50 * l1) ~/ 17719) +
      (l1 ~/ 5670) * ((43 * l1) ~/ 15238);
  final l2 = l1 -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final m = (24 * l2) ~/ 709;
  final d = l2 - (709 * m) ~/ 24;
  final y = 30 * n + j - 30;
  return [y, m, d];
}

String arDigits(String s) {
  const west = '0123456789';
  const east = '٠١٢٣٤٥٦٧٨٩';
  return s.split('').map((ch) {
    final i = west.indexOf(ch);
    return i < 0 ? ch : east[i];
  }).join();
}

// ---------------- الإشعارات ----------------
final FlutterLocalNotificationsPlugin notif = FlutterLocalNotificationsPlugin();
const String channelId = 'adhan_channel_v1';

Future<void> initNotifications() async {
  tzdata.initializeTimeZones();
  const init = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await notif.initialize(settings: init);
  final a = notif.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await a?.createNotificationChannel(const AndroidNotificationChannel(
    channelId,
    'الأذان',
    description: 'تنبيهات الأذان في أوقات الصلاة',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('adhan'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
    enableVibration: true,
  ));
}

Future<void> askPermissions() async {
  final a = notif.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await a?.requestNotificationsPermission();
  final can = await a?.canScheduleExactNotifications() ?? false;
  if (!can) await a?.requestExactAlarmsPermission();
}

NotificationDetails adhanDetails() => const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'الأذان',
        channelDescription: 'تنبيهات الأذان في أوقات الصلاة',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
    );

Future<AndroidScheduleMode> scheduleMode() async {
  final a = notif.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  final can = await a?.canScheduleExactNotifications() ?? false;
  return can
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;
}

// ---------------- الموقع ----------------
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

// ---------------- رسم المسجد ----------------
class SkylinePainter extends CustomPainter {
  final Color color;
  const SkylinePainter(this.color);

  void _dome(Canvas canvas, Paint p, double cx, double y, double r) {
    final path = Path()
      ..moveTo(cx - r, y)
      ..arcToPoint(Offset(cx + r, y), radius: Radius.circular(r))
      ..close();
    canvas.drawPath(path, p);
    canvas.drawRect(
        Rect.fromLTWH(cx - r * 0.06, y - r * 1.35, r * 0.12, r * 0.45), p);
  }

  void _minaret(
      Canvas canvas, Paint p, double cx, double base, double w, double hgt) {
    canvas.drawRect(Rect.fromLTWH(cx - w / 2, base - hgt, w, hgt), p);
    canvas.drawRect(
        Rect.fromLTWH(cx - w * 0.85, base - hgt * 0.78, w * 1.7, w * 0.35), p);
    _dome(canvas, p, cx, base - hgt, w * 0.75);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(200), color.withAlpha(0)],
      ).createShader(Rect.fromLTWH(0, h * 0.1, w, h * 0.9));
    final base = h;
    const heights = [
      0.12, 0.2, 0.16, 0.26, 0.14, 0.22, 0.1, 0.18, 0.24, 0.13, 0.19, 0.15
    ];
    final bw = w / heights.length;
    for (int i = 0; i < heights.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * bw, base - h * heights[i], bw * 0.9, h * heights[i]),
        paint,
      );
    }
    canvas.drawRect(
        Rect.fromLTWH(w * 0.32, base - h * 0.3, w * 0.36, h * 0.3), paint);
    _dome(canvas, paint, w * 0.5, base - h * 0.3, w * 0.18);
    _dome(canvas, paint, w * 0.36, base - h * 0.3, w * 0.06);
    _dome(canvas, paint, w * 0.64, base - h * 0.3, w * 0.06);
    _minaret(canvas, paint, w * 0.12, base, w * 0.045, h * 0.7);
    _minaret(canvas, paint, w * 0.24, base, w * 0.03, h * 0.46);
    _minaret(canvas, paint, w * 0.78, base, w * 0.03, h * 0.5);
    _minaret(canvas, paint, w * 0.88, base, w * 0.045, h * 0.66);
    _minaret(canvas, paint, w * 0.96, base, w * 0.03, h * 0.45);
  }

  @override
  bool shouldRepaint(covariant SkylinePainter old) => old.color != color;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getInt('theme') ?? 0;
    if (t >= 0 && t < palettes.length) themeIdx.value = t;
  } catch (_) {}
  try {
    await initNotifications();
  } catch (_) {}
  runApp(const AdhanApp());
}

class AdhanApp extends StatelessWidget {
  const AdhanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeIdx,
      builder: (context, i, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0B6E4F),
          brightness: isDarkTheme(i) ? Brightness.dark : Brightness.light,
          useMaterial3: true,
        ),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _sk = GlobalKey<ScaffoldState>();
  Place? _place;
  String _method = 'رابطة العالم الإسلامي';
  bool _hanafi = false;
  bool _adhanOn = true;
  bool _use24 = true;
  int _hcorr = 0;
  List<bool> _prayerOn = [true, true, true, true, true];
  List<DateTime> _times = [];
  DateTime? _tomorrowFajr;
  int _calcDay = -1;
  DateTime _wallNow = DateTime.now().toUtc();
  Timer? _timer;
  bool _busy = false;
  String? _msg;
  bool _sched = false;
  bool _schedAgain = false;

  Duration _offset(Place p) =>
      p.gps ? DateTime.now().timeZoneOffset : Duration(seconds: p.offsetSec);

  DateTime _wall(DateTime t, Duration off) =>
      t.isUtc ? t : t.toUtc().add(off);

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _soon(String s) => _snack('$s: قريباً بإذن الله');

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
        if (p != null && now.day != _calcDay) {
          _recalc();
          _scheduleAll();
        }
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
    _adhanOn = sp.getBool('adhanOn') ?? true;
    _use24 = sp.getBool('use24') ?? true;
    _hcorr = sp.getInt('hcorr') ?? 0;
    final po = sp.getStringList('prayerOn');
    if (po != null && po.length == 5) {
      _prayerOn = po.map((e) => e == '1').toList();
    }
    if (raw != null) {
      try {
        _place = Place.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _recalc());
    try {
      await askPermissions();
    } catch (_) {}
    await _scheduleAll();
    final pl = _place;
    if (pl != null && !pl.gps) {
      final off = await fetchOffset(pl.lat, pl.lng);
      if (off != null && off != pl.offsetSec && mounted) {
        _place = pl.withOffset(off);
        await _savePlace();
        setState(() => _recalc());
        await _scheduleAll();
      }
    }
    if (_place != null) await _batteryHintOnce();
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
    await sp.setBool('adhanOn', _adhanOn);
    await sp.setBool('use24', _use24);
    await sp.setInt('hcorr', _hcorr);
    await sp.setStringList(
        'prayerOn', _prayerOn.map((e) => e ? '1' : '0').toList());
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

  // ---------------- جدولة الأذان ----------------
  Future<void> _scheduleAll() async {
    if (_sched) {
      _schedAgain = true;
      return;
    }
    _sched = true;
    try {
      do {
        _schedAgain = false;
        await _doSchedule();
      } while (_schedAgain);
    } finally {
      _sched = false;
    }
  }

  Future<void> _doSchedule() async {
    final p = _place;
    if (p == null) return;
    try {
      await notif.cancelAll();
      if (!_adhanOn) return;
      final off = _offset(p);
      final coords = Coordinates(p.lat, p.lng);
      final params = methods[_method]!.getParameters();
      params.madhab = _hanafi ? Madhab.hanafi : Madhab.shafi;
      final nowUtc = DateTime.now().toUtc();
      final wallNow = nowUtc.add(off);
      final mode = await scheduleMode();
      for (int d = 0; d < 7; d++) {
        final date = wallNow.add(Duration(days: d));
        final pt = PrayerTimes(coords, DateComponents.from(date), params,
            utcOffset: off);
        final list = [pt.fajr, pt.dhuhr, pt.asr, pt.maghrib, pt.isha];
        for (int i = 0; i < 5; i++) {
          if (!_prayerOn[i]) continue;
          final wall = _wall(list[i], off);
          final instant = wall.subtract(off);
          if (!instant.isAfter(nowUtc)) continue;
          await notif.zonedSchedule(
            id: d * 10 + i,
            title: 'حان الآن موعد أذان ${adhanNames[i]}',
            body: p.gps ? 'حسب موقعك الحالي' : 'حسب توقيت ${p.name}',
            scheduledDate: tz.TZDateTime.from(instant, tz.UTC),
            notificationDetails: adhanDetails(),
            androidScheduleMode: mode,
          );
        }
      }
    } catch (e) {
      _snack('تعذرت جدولة الأذان: $e');
    }
  }

  Future<void> _testNow() async {
    try {
      await notif.show(
        id: 999,
        title: 'تجربة الأذان',
        body: 'الله أكبر الله أكبر',
        notificationDetails: adhanDetails(),
      );
    } catch (e) {
      _snack('تعذرت التجربة: $e');
    }
  }

  Future<void> _testLater() async {
    try {
      await notif.zonedSchedule(
        id: 998,
        title: 'تجربة الأذان',
        body: 'الله أكبر الله أكبر',
        scheduledDate:
            tz.TZDateTime.now(tz.UTC).add(const Duration(seconds: 60)),
        notificationDetails: adhanDetails(),
        androidScheduleMode: await scheduleMode(),
      );
      _snack('سيصلك الأذان بعد دقيقة. اقفل الشاشة الآن');
    } catch (e) {
      _snack('تعذرت التجربة: $e');
    }
  }

  Future<void> _batterySettings() async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.example.adhan_app',
      );
      await intent.launch();
    } catch (_) {
      try {
        final intent2 = AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
        await intent2.launch();
      } catch (_) {}
    }
  }

  Future<void> _batteryHintOnce() async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool('batteryHint') ?? false) return;
    if (!mounted) return;
    await sp.setBool('batteryHint', true);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مهم لعمل الأذان'),
        content: const Text(
            'حتى يعمل الأذان والهاتف مقفل، اسمح للتطبيق بالعمل في الخلفية '
            'وبدون تقييد البطارية. في بعض الهواتف (Xiaomi وHuawei وSamsung) '
            'فعّل أيضاً "التشغيل التلقائي" من إعدادات التطبيق.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('لاحقاً')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _batterySettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  // ---------------- اختيار الموقع ----------------
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
      await _scheduleAll();
      await _batteryHintOnce();
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
    await _scheduleAll();
    await _batteryHintOnce();
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

  // ---------------- اختيار الثيم ----------------
  Widget _themePreview(AppPalette p, bool selected) {
    return Container(
      width: 96,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF0A9A0A) : Colors.black26,
          width: selected ? 3 : 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: p.bg,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 50,
              child: CustomPaint(painter: SkylinePainter(p.skyline)),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 22,
              height: 8,
              child: ColoredBox(color: p.row),
            ),
            const Positioned(
              left: 8,
              right: 8,
              bottom: 11,
              height: 8,
              child: ColoredBox(color: Color(0xFF0A9A0A)),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 0,
              height: 8,
              child: ColoredBox(color: p.row),
            ),
          ],
        ),
      ),
    );
  }

  void _themeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('اختر الثيم'),
        children: [
          for (int i = 0; i < palettes.length; i++)
            SimpleDialogOption(
              onPressed: () async {
                themeIdx.value = i;
                Navigator.pop(ctx);
                if (mounted) setState(() {});
                final sp = await SharedPreferences.getInstance();
                await sp.setInt('theme', i);
              },
              child: Row(
                children: [
                  _themePreview(palettes[i], themeIdx.value == i),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(palettes[i].name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  if (themeIdx.value == i)
                    const Icon(Icons.check_circle, color: Color(0xFF0A9A0A)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- الإعدادات ----------------
  void _settings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          void upd(VoidCallback f) {
            setState(f);
            setS(() {});
            _saveSettings();
            _scheduleAll();
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('طريقة الحساب',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _method,
                    items: [
                      for (final k in methods.keys)
                        DropdownMenuItem(value: k, child: Text(k)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      upd(() {
                        _method = v;
                        _recalc();
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('المذهب الحنفي في العصر'),
                    value: _hanafi,
                    onChanged: (v) => upd(() {
                      _hanafi = v;
                      _recalc();
                    }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('نظام 24 ساعة'),
                    value: _use24,
                    onChanged: (v) => upd(() => _use24 = v),
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('تصحيح التاريخ الهجري')),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _hcorr > -3 ? () => upd(() => _hcorr--) : null,
                      ),
                      Text(_hcorr > 0 ? '+$_hcorr' : '$_hcorr',
                          style: const TextStyle(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _hcorr < 3 ? () => upd(() => _hcorr++) : null,
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text('الأذان',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تفعيل الأذان'),
                    value: _adhanOn,
                    onChanged: (v) => upd(() => _adhanOn = v),
                  ),
                  for (int i = 0; i < 5; i++)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(adhanNames[i]),
                      value: _prayerOn[i],
                      onChanged: _adhanOn
                          ? (v) => upd(() => _prayerOn[i] = v ?? true)
                          : null,
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _testNow();
                    },
                    icon: const Icon(Icons.volume_up),
                    label: const Text('تجربة الأذان الآن'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _testLater();
                    },
                    icon: const Icon(Icons.timer),
                    label: const Text('تجربة بعد دقيقة (اقفل الشاشة)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _batterySettings,
                    icon: const Icon(Icons.battery_saver),
                    label: const Text('السماح بالعمل في الخلفية (مهم)'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- الواجهة ----------------
  String _fmt(DateTime t) {
    final mm = t.minute.toString().padLeft(2, '0');
    if (_use24) return '${t.hour.toString().padLeft(2, '0')}:$mm';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:$mm ${t.hour < 12 ? 'ص' : 'م'}';
  }

  String _hijriText() {
    final g = _wallNow;
    final h = hijriOf(g, _hcorr);
    final month = hijriMonths[(h[1] - 1).clamp(0, 11)];
    final wd = weekdayNames[g.weekday - 1];
    return arDigits('$wd ${h[2]} $month ${h[0]}');
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

  Widget _row(String name, String time, AppPalette c,
      {bool hl = false, bool small = false}) {
    final fg = hl ? Colors.white : c.text;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: small ? 6 : 4),
      color: hl ? const Color(0xFF0A9A0A) : c.row,
      child: Row(
        children: [
          Text(name,
              style: TextStyle(
                  fontSize: small ? 20 : 28,
                  fontWeight: FontWeight.w800,
                  color: fg)),
          const Spacer(),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(time,
                style: TextStyle(
                    fontSize: small ? 26 : 40,
                    fontWeight: FontWeight.w400,
                    color: fg)),
          ),
        ],
      ),
    );
  }

  Widget _cdWidget(Duration d, AppPalette c) {
    final x = d.isNegative ? Duration.zero : d;
    String two(int n) => n.toString().padLeft(2, '0');
    Widget unit(String v, String l, {bool thin = false}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(v,
                style: TextStyle(
                    fontSize: 60,
                    height: 1.0,
                    fontWeight: thin ? FontWeight.w200 : FontWeight.w800,
                    color: thin ? c.soft : c.text)),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 2, right: 12),
              child: Text(l,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.text)),
            ),
          ],
        );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              unit(two(x.inHours), 'H'),
              unit(two(x.inMinutes % 60), 'M'),
              unit(two(x.inSeconds % 60), 'S', thin: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(AppPalette c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: c.pill,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: c.text, size: 30),
            onPressed: () => _sk.currentState?.openDrawer(),
          ),
          Expanded(
            child: Center(
              child: Text(_hijriText(),
                  style: TextStyle(
                      color: c.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.explore_outlined, color: c.text, size: 30),
            onPressed: () => _soon('القبلة'),
          ),
        ],
      ),
    );
  }

  Widget _home() {
    if (_times.length != 6) {
      return const Center(child: CircularProgressIndicator());
    }
    final c = palettes[themeIdx.value];
    final size = MediaQuery.of(context).size;
    int nextIdx = -1;
    for (final i in [0, 2, 3, 4, 5]) {
      if (_times[i].isAfter(_wallNow)) {
        nextIdx = i;
        break;
      }
    }
    final tomorrow = nextIdx == -1;
    final tmrFajr =
        _tomorrowFajr ?? _times[0].add(const Duration(days: 1));
    final target = tomorrow ? tmrFajr : _times[nextIdx];
    final left = target.difference(_wallNow);
    final friday = _wallNow.weekday == DateTime.friday;

    final rows = <Widget>[];
    for (int i = 0; i < 6; i++) {
      final hl = !tomorrow && i == nextIdx;
      if (hl) rows.add(_cdWidget(left, c));
      final nm = (i == 2 && friday) ? 'الجمعة' : names[i];
      rows.add(_row(nm, _fmt(_times[i]), c, hl: hl));
    }
    if (tomorrow) rows.add(_cdWidget(left, c));
    rows.add(_row('الفجر', _fmt(tmrFajr), c, hl: tomorrow, small: true));

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: c.bg,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.5,
          child: CustomPaint(painter: SkylinePainter(c.skyline)),
        ),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _pill(c),
              SizedBox(height: size.height * 0.2),
              ...rows,
              if (_busy) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _adhanOn ? 'الأذان مفعّل 🔔' : 'الأذان متوقف 🔕',
                  style: TextStyle(color: c.soft),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dItem(IconData ic, String t, VoidCallback f) => ListTile(
        leading: Icon(ic),
        title: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        onTap: () {
          _sk.currentState?.closeDrawer();
          f();
        },
      );

  Widget _drawer() {
    final p = _place;
    String coords = '';
    if (p != null) {
      final ns = p.lat >= 0 ? 'N' : 'S';
      final ew = p.lng >= 0 ? 'E' : 'W';
      final gmt = (_offset(p).inMinutes / 60).toStringAsFixed(1);
      coords =
          '${p.lat.abs().toStringAsFixed(2)} $ns ${p.lng.abs().toStringAsFixed(3)} $ew\n$gmt GMT';
    }
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF18A31A),
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الموقع الحالي',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(coords,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.white),
                      onPressed: () {
                        _sk.currentState?.closeDrawer();
                        _useGps();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF0B5E10),
                      child: IconButton(
                        icon: const Icon(Icons.sync, color: Colors.white),
                        onPressed: () {
                          setState(() => _recalc());
                          _scheduleAll();
                          _snack('تم تحديث المواقيت');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p?.name ?? 'لم يتم تحديد الموقع',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _dItem(Icons.volunteer_activism, 'الأذكار',
                    () => _soon('الأذكار')),
                _dItem(Icons.alarm, 'التذكير', () => _soon('التذكير')),
                _dItem(Icons.calendar_month, 'التقويم الهجري',
                    () => _soon('التقويم الهجري')),
                const Divider(),
                _dItem(Icons.calendar_view_month, 'شهري',
                    () => _soon('الجدول الشهري')),
                _dItem(Icons.place, 'المواقع', _placeSheet),
                _dItem(Icons.music_note, 'أصوات الأذان',
                    () => _soon('أصوات الأذان')),
                _dItem(Icons.palette, 'الثيمات', _themeDialog),
                const Divider(),
                _dItem(Icons.settings, 'الإعدادات', _settings),
                _dItem(Icons.help, 'إقتراح أو مشكلة',
                    () => _soon('الاقتراحات')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _sk,
      drawer: _place == null ? null : _drawer(),
      body: _place == null ? SafeArea(child: _welcome()) : _home(),
    );
  }
}

// ---------------- صفحة البحث ----------------
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
