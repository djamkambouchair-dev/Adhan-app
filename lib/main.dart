import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;
import 'package:adhan/adhan.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'l10n.dart';
import 'location_pages.dart';
import 'pages.dart';
import 'qibla_page.dart';
import 'settings_page.dart';

export 'l10n.dart';

// ---------------- طرق الحساب ----------------
const methodKeys = ['mwl', 'umm', 'egy', 'kar', 'isna', 'dxb', 'qat', 'kwt', 'sgp'];

final Map<String, CalculationMethod> methods = {
  'mwl': CalculationMethod.muslim_world_league,
  'umm': CalculationMethod.umm_al_qura,
  'egy': CalculationMethod.egyptian,
  'kar': CalculationMethod.karachi,
  'isna': CalculationMethod.north_america,
  'dxb': CalculationMethod.dubai,
  'qat': CalculationMethod.qatar,
  'kwt': CalculationMethod.kuwait,
  'sgp': CalculationMethod.singapore,
};

const legacyMethods = {
  'رابطة العالم الإسلامي': 'mwl',
  'أم القرى (مكة)': 'umm',
  'الهيئة المصرية': 'egy',
  'جامعة كراتشي': 'kar',
  'أمريكا الشمالية (ISNA)': 'isna',
  'الإمارات': 'dxb',
  'قطر': 'qat',
  'الكويت': 'kwt',
  'سنغافورة': 'sgp',
};

// جسر الخدمة الأصلية للإشعار الدائم
const MethodChannel fgs = MethodChannel('adhan/fgs');
const Color notifGreen = Color(0xFF12B76A);

// ---------------- الإعدادات ----------------
class AppSettings extends ChangeNotifier {
  String method = 'mwl';
  bool hanafi = false;
  bool adhanOn = true;
  bool persistOn = true;
  bool use24 = true;
  int hcorr = 0;
  List<bool> prayerOn = [true, true, true, true, true];
  String lang = 'ar';

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final m = sp.getString('method');
    if (m != null) {
      method = methods.containsKey(m) ? m : (legacyMethods[m] ?? 'mwl');
    }
    hanafi = sp.getBool('hanafi') ?? false;
    adhanOn = sp.getBool('adhanOn') ?? true;
    persistOn = sp.getBool('persistOn') ?? true;
    use24 = sp.getBool('use24') ?? true;
    hcorr = sp.getInt('hcorr') ?? 0;
    final po = sp.getStringList('prayerOn');
    if (po != null && po.length == 5) {
      prayerOn = po.map((e) => e == '1').toList();
    }
    final l = sp.getString('lang');
    if (l != null && langs.contains(l)) {
      lang = l;
    } else {
      final dl = PlatformDispatcher.instance.locale.languageCode;
      lang = langs.contains(dl) ? dl : 'ar';
    }
    currentLang = lang;
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('method', method);
    await sp.setBool('hanafi', hanafi);
    await sp.setBool('adhanOn', adhanOn);
    await sp.setBool('persistOn', persistOn);
    await sp.setBool('use24', use24);
    await sp.setInt('hcorr', hcorr);
    await sp.setString('lang', lang);
    await sp.setStringList(
        'prayerOn', prayerOn.map((e) => e ? '1' : '0').toList());
  }

  void update(VoidCallback f) {
    f();
    currentLang = lang;
    save();
    notifyListeners();
  }
}

final AppSettings cfg = AppSettings();
final ValueNotifier<String> placeLabel = ValueNotifier<String>('');

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

// ---------------- الإشعارات ----------------
final FlutterLocalNotificationsPlugin notif = FlutterLocalNotificationsPlugin();
const String channelId = 'adhan_channel_v1';
const String persistChannelId = 'next_prayer_v1';

Future<void> initNotifications() async {
  tzdata.initializeTimeZones();
  const init = InitializationSettings(
    android: AndroidInitializationSettings('ic_stat_mosque'),
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
  await a?.createNotificationChannel(const AndroidNotificationChannel(
    persistChannelId,
    'الصلاة القادمة',
    description: 'إشعار دائم بالصلاة القادمة والوقت المتبقي',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
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
        icon: 'ic_stat_mosque',
        color: notifGreen,
      ),
    );

NotificationDetails persistDetails(DateTime target, int timeoutMs) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      persistChannelId,
      'الصلاة القادمة',
      channelDescription: 'إشعار دائم بالصلاة القادمة والوقت المتبقي',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      showWhen: true,
      when: target.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: true,
      timeoutAfter: timeoutMs,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      icon: 'ic_stat_mosque',
      color: notifGreen,
      colorized: true,
    ),
  );
}

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
    await cfg.load();
  } catch (_) {}
  try {
    final sp = await SharedPreferences.getInstance();
    final th = sp.getInt('theme') ?? 0;
    if (th >= 0 && th < palettes.length) themeIdx.value = th;
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
    return ListenableBuilder(
      listenable: Listenable.merge([cfg, themeIdx]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: t('app_name'),
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0B6E4F),
          brightness: isDarkTheme(themeIdx.value)
              ? Brightness.dark
              : Brightness.light,
          useMaterial3: true,
        ),
        builder: (context, child) =>
            Directionality(textDirection: appDir, child: child!),
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

  DateTime _wall(DateTime x, Duration off) => x.isUtc ? x : x.toUtc().add(off);

  void _setPlace(Place p) {
    _place = p;
    placeLabel.value = p.gps ? '' : p.name;
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _soon(String s) => _snack(t('soon', [s]));

  void _onCfg() {
    if (!mounted) return;
    setState(() => _recalc());
    _scheduleAll();
  }

  void _onTheme() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    cfg.addListener(_onCfg);
    themeIdx.addListener(_onTheme);
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
    cfg.removeListener(_onCfg);
    themeIdx.removeListener(_onTheme);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('place');
    if (raw != null) {
      try {
        _setPlace(Place.fromJson(jsonDecode(raw) as Map<String, dynamic>));
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
    final params = methods[cfg.method]!.getParameters();
    params.madhab = cfg.hanafi ? Madhab.hanafi : Madhab.shafi;
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

  // ---------------- جدولة الأذان والإشعار الدائم ----------------
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

  List<List<DateTime>> _upcoming(int days) {
    final p = _place!;
    final off = _offset(p);
    final coords = Coordinates(p.lat, p.lng);
    final params = methods[cfg.method]!.getParameters();
    params.madhab = cfg.hanafi ? Madhab.hanafi : Madhab.shafi;
    final wallNow = DateTime.now().toUtc().add(off);
    final out = <List<DateTime>>[];
    for (int d = 0; d < days; d++) {
      final date = wallNow.add(Duration(days: d));
      final pt = PrayerTimes(coords, DateComponents.from(date), params,
          utcOffset: off);
      final list = [pt.fajr, pt.dhuhr, pt.asr, pt.maghrib, pt.isha];
      out.add(list.map((x) => _wall(x, off).subtract(off)).toList());
    }
    return out;
  }

  Future<void> _doSchedule() async {
    final p = _place;
    if (p == null) return;
    try {
      await notif.cancelAll();
      final off = _offset(p);
      final nowUtc = DateTime.now().toUtc();
      final days = _upcoming(14);
      final mode = await scheduleMode();
      if (cfg.adhanOn) {
        for (int d = 0; d < 7; d++) {
          for (int i = 0; i < 5; i++) {
            if (!cfg.prayerOn[i]) continue;
            final instant = days[d][i];
            if (!instant.isAfter(nowUtc)) continue;
            await notif.zonedSchedule(
              id: d * 10 + i,
              title: t('adhan_title', [adhanName(i)]),
              body: p.gps ? t('by_gps') : t('by_place', [p.name]),
              scheduledDate: tz.TZDateTime.from(instant, tz.UTC),
              notificationDetails: adhanDetails(),
              androidScheduleMode: mode,
            );
          }
        }
      }
      if (cfg.persistOn) {
        final ok = await _syncPersistentNative(days, off);
        if (!ok) {
          await _schedulePersistent(
              days.take(7).toList(), off, nowUtc, mode);
        }
      } else {
        try {
          await fgs.invokeMethod('stop');
        } catch (_) {}
      }
    } catch (e) {
      _snack(t('schedule_failed', [e.toString()]));
    }
  }

  // الخدمة الأصلية: تعيد الإشعار فور مسحه وتحدّثه عند كل صلاة
  Future<bool> _syncPersistentNative(
      List<List<DateTime>> days, Duration off) async {
    try {
      final p = _place!;
      final where = p.gps ? t('my_location') : p.name;
      final nowUtc = DateTime.now().toUtc();
      final list = <Map<String, dynamic>>[];
      for (final d in days) {
        for (int i = 0; i < 5; i++) {
          final inst = d[i];
          if (!inst.isAfter(nowUtc)) continue;
          list.add({
            't': inst.millisecondsSinceEpoch,
            'title': t('next_title', [adhanName(i)]),
            'body': '${_fmt(inst.add(off))}  •  $where',
          });
        }
      }
      final sp = await SharedPreferences.getInstance();
      await sp.setString('persistEvents', jsonEncode(list));
      await sp.setBool('persistOn', true);
      await fgs.invokeMethod('start');
      return true;
    } catch (_) {
      return false;
    }
  }

  // بديل احتياطي إن تعذر وجود الخدمة الأصلية
  Future<void> _schedulePersistent(List<List<DateTime>> days, Duration off,
      DateTime nowUtc, AndroidScheduleMode mode) async {
    final p = _place!;
    final where = p.gps ? t('my_location') : p.name;
    final ev = <MapEntry<int, DateTime>>[];
    for (final d in days) {
      for (int i = 0; i < 5; i++) {
        ev.add(MapEntry(i, d[i]));
      }
    }
    int firstNext = -1;
    for (int k = 0; k < ev.length; k++) {
      if (ev[k].value.isAfter(nowUtc)) {
        firstNext = k;
        break;
      }
    }
    if (firstNext == -1) return;
    final cur = ev[firstNext];
    await notif.show(
      id: 199,
      title: t('next_title', [adhanName(cur.key)]),
      body: '${_fmt(cur.value.add(off))}  •  $where',
      notificationDetails: persistDetails(
        cur.value,
        cur.value.difference(nowUtc).inMilliseconds,
      ),
    );
    for (int k = firstNext; k < ev.length - 1; k++) {
      final start = ev[k].value;
      final nxt = ev[k + 1];
      await notif.zonedSchedule(
        id: 200 + k - firstNext,
        title: t('next_title', [adhanName(nxt.key)]),
        body: '${_fmt(nxt.value.add(off))}  •  $where',
        scheduledDate: tz.TZDateTime.from(start, tz.UTC),
        notificationDetails: persistDetails(
          nxt.value,
          nxt.value.difference(start).inMilliseconds,
        ),
        androidScheduleMode: mode,
      );
    }
  }

  Future<void> _testNow() async {
    try {
      await notif.show(
        id: 999,
        title: t('test_title'),
        body: t('test_body'),
        notificationDetails: adhanDetails(),
      );
    } catch (e) {
      _snack(t('test_failed', [e.toString()]));
    }
  }

  Future<void> _testLater() async {
    try {
      await notif.zonedSchedule(
        id: 998,
        title: t('test_title'),
        body: t('test_body'),
        scheduledDate:
            tz.TZDateTime.now(tz.UTC).add(const Duration(seconds: 60)),
        notificationDetails: adhanDetails(),
        androidScheduleMode: await scheduleMode(),
      );
      _snack(t('test_in_1min'));
    } catch (e) {
      _snack(t('test_failed', [e.toString()]));
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
        title: Text(t('battery_title')),
        content: Text(t('battery_body')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(t('later'))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _batterySettings();
            },
            child: Text(t('open_settings')),
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
        throw 'gps_off';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'gps_denied';
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
      if (pos == null) throw 'gps_fail';
      _setPlace(Place(
        name: 'GPS',
        sub: '',
        lat: pos.latitude,
        lng: pos.longitude,
        gps: true,
      ));
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
      MaterialPageRoute(builder: (_) => const CountryPage()),
    );
    if (res == null || !mounted) return;
    setState(() {
      _busy = true;
      _msg = null;
    });
    final off = await fetchOffset(res.lat, res.lng);
    _setPlace(
        res.withOffset(off ?? DateTime.now().timeZoneOffset.inSeconds));
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
              leading: const Icon(Icons.public),
              title: Text(t('choose_country_city')),
              onTap: () {
                Navigator.pop(ctx);
                _pickCity();
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: Text(t('my_location_gps')),
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

  void _openHijri() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HijriCalendarPage(hcorr: cfg.hcorr, today: _wallNow),
    ));
  }

  void _openMonthly() {
    final p = _place;
    if (p == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MonthlyPage(
        place: p,
        method: cfg.method,
        hanafi: cfg.hanafi,
        use24: cfg.use24,
      ),
    ));
  }

  void _openQibla() {
    final p = _place;
    if (p == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QiblaPage(place: p),
    ));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsPage(
        onChangeLocation: _placeSheet,
        onTestNow: _testNow,
        onTestLater: _testLater,
        onBattery: _batterySettings,
      ),
    ));
  }

  // ---------------- الواجهة ----------------
  String _fmt(DateTime x) {
    final mm = x.minute.toString().padLeft(2, '0');
    if (cfg.use24) return '${x.hour.toString().padLeft(2, '0')}:$mm';
    final h = x.hour % 12 == 0 ? 12 : x.hour % 12;
    return '$h:$mm ${x.hour < 12 ? t('am') : t('pm')}';
  }

  String _hijriText() {
    final g = _wallNow;
    final h = hijriOf(g, cfg.hcorr);
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
            Text(t('bismillah'),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(t('choose_location_msg'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            if (_busy)
              const CircularProgressIndicator()
            else ...[
              FilledButton.icon(
                onPressed: _pickCity,
                icon: const Icon(Icons.public),
                label: Text(t('choose_country_city')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _useGps,
                icon: const Icon(Icons.my_location),
                label: Text(t('use_my_location')),
              ),
            ],
            if (_msg != null) ...[
              const SizedBox(height: 16),
              Text(t(_msg!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.translate),
              label: Text(t('language')),
            ),
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
            child: GestureDetector(
              onTap: _openHijri,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_hijriText(),
                      style: TextStyle(
                          color: c.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.explore_outlined, color: c.text, size: 30),
            onPressed: _openQibla,
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
      final nm = (i == 2 && friday) ? t('jumua') : prayerName(i);
      rows.add(_row(nm, _fmt(_times[i]), c, hl: hl));
    }
    if (tomorrow) rows.add(_cdWidget(left, c));
    rows.add(_row(prayerName(0), _fmt(tmrFajr), c, hl: tomorrow, small: true));

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
                  cfg.adhanOn ? t('adhan_on_label') : t('adhan_off_label'),
                  style: TextStyle(color: c.soft),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dItem(IconData ic, String label, VoidCallback f) => ListTile(
        leading: Icon(ic),
        title: Text(label,
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
    final title = p == null
        ? t('no_location')
        : (p.gps ? t('my_location') : p.name);
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
                Text(t('current_location'),
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
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
                          _snack(t('times_updated'));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                _dItem(Icons.volunteer_activism, t('adhkar'),
                    () => _soon(t('adhkar'))),
                _dItem(Icons.alarm, t('reminder'), () => _soon(t('reminder'))),
                _dItem(Icons.calendar_month, t('hijri_calendar'), _openHijri),
                const Divider(),
                _dItem(Icons.calendar_view_month, t('monthly'), _openMonthly),
                _dItem(Icons.explore, t('qibla'), _openQibla),
                _dItem(Icons.place, t('locations'), _placeSheet),
                _dItem(Icons.music_note, t('adhan_sounds'),
                    () => _soon(t('adhan_sounds'))),
                _dItem(Icons.palette, t('themes'), _openSettings),
                const Divider(),
                _dItem(Icons.settings, t('settings'), _openSettings),
                _dItem(Icons.help, t('feedback'), () => _soon(t('feedback'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: appDir,
      child: Scaffold(
        key: _sk,
        drawer: _place == null ? null : _drawer(),
        body: _place == null ? SafeArea(child: _welcome()) : _home(),
      ),
    );
  }
}
