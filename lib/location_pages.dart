import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'main.dart';

class Country {
  final String code;
  final String name;
  final int group;
  const Country(this.code, this.name, this.group);

  String get flag => String.fromCharCodes(
      code.codeUnits.map((u) => 0x1F1E6 + u - 65));
}

// المجموعات: 0 عربية، 1 إسلامية، 2 أوروبا، 3 أخرى
const countries = <Country>[
  Country('SA', 'السعودية', 0),
  Country('AE', 'الإمارات', 0),
  Country('QA', 'قطر', 0),
  Country('KW', 'الكويت', 0),
  Country('BH', 'البحرين', 0),
  Country('OM', 'عُمان', 0),
  Country('YE', 'اليمن', 0),
  Country('IQ', 'العراق', 0),
  Country('SY', 'سوريا', 0),
  Country('LB', 'لبنان', 0),
  Country('JO', 'الأردن', 0),
  Country('PS', 'فلسطين', 0),
  Country('EG', 'مصر', 0),
  Country('SD', 'السودان', 0),
  Country('LY', 'ليبيا', 0),
  Country('TN', 'تونس', 0),
  Country('DZ', 'الجزائر', 0),
  Country('MA', 'المغرب', 0),
  Country('MR', 'موريتانيا', 0),
  Country('SO', 'الصومال', 0),
  Country('DJ', 'جيبوتي', 0),
  Country('KM', 'جزر القمر', 0),
  Country('TR', 'تركيا', 1),
  Country('IR', 'إيران', 1),
  Country('PK', 'باكستان', 1),
  Country('AF', 'أفغانستان', 1),
  Country('BD', 'بنغلاديش', 1),
  Country('ID', 'إندونيسيا', 1),
  Country('MY', 'ماليزيا', 1),
  Country('BN', 'بروناي', 1),
  Country('MV', 'المالديف', 1),
  Country('SN', 'السنغال', 1),
  Country('ML', 'مالي', 1),
  Country('NE', 'النيجر', 1),
  Country('TD', 'تشاد', 1),
  Country('NG', 'نيجيريا', 1),
  Country('GM', 'غامبيا', 1),
  Country('GN', 'غينيا', 1),
  Country('SL', 'سيراليون', 1),
  Country('BF', 'بوركينا فاسو', 1),
  Country('CI', 'ساحل العاج', 1),
  Country('GH', 'غانا', 1),
  Country('ET', 'إثيوبيا', 1),
  Country('ER', 'إريتريا', 1),
  Country('KE', 'كينيا', 1),
  Country('TZ', 'تنزانيا', 1),
  Country('UG', 'أوغندا', 1),
  Country('AZ', 'أذربيجان', 1),
  Country('KZ', 'كازاخستان', 1),
  Country('UZ', 'أوزبكستان', 1),
  Country('TM', 'تركمانستان', 1),
  Country('TJ', 'طاجيكستان', 1),
  Country('KG', 'قيرغيزستان', 1),
  Country('AL', 'ألبانيا', 1),
  Country('XK', 'كوسوفو', 1),
  Country('BA', 'البوسنة والهرسك', 1),
  Country('LK', 'سريلانكا', 1),
  Country('IN', 'الهند', 1),
  Country('CN', 'الصين', 1),
  Country('DE', 'ألمانيا', 2),
  Country('FR', 'فرنسا', 2),
  Country('GB', 'بريطانيا', 2),
  Country('ES', 'إسبانيا', 2),
  Country('IT', 'إيطاليا', 2),
  Country('NL', 'هولندا', 2),
  Country('BE', 'بلجيكا', 2),
  Country('CH', 'سويسرا', 2),
  Country('AT', 'النمسا', 2),
  Country('SE', 'السويد', 2),
  Country('NO', 'النرويج', 2),
  Country('DK', 'الدنمارك', 2),
  Country('FI', 'فنلندا', 2),
  Country('IE', 'أيرلندا', 2),
  Country('PT', 'البرتغال', 2),
  Country('GR', 'اليونان', 2),
  Country('PL', 'بولندا', 2),
  Country('CZ', 'التشيك', 2),
  Country('HU', 'المجر', 2),
  Country('RO', 'رومانيا', 2),
  Country('BG', 'بلغاريا', 2),
  Country('RS', 'صربيا', 2),
  Country('HR', 'كرواتيا', 2),
  Country('SI', 'سلوفينيا', 2),
  Country('SK', 'سلوفاكيا', 2),
  Country('UA', 'أوكرانيا', 2),
  Country('RU', 'روسيا', 2),
  Country('LU', 'لوكسمبورغ', 2),
  Country('IS', 'آيسلندا', 2),
  Country('MK', 'مقدونيا الشمالية', 2),
  Country('ME', 'الجبل الأسود', 2),
  Country('MD', 'مولدوفا', 2),
  Country('BY', 'بيلاروسيا', 2),
  Country('LT', 'ليتوانيا', 2),
  Country('LV', 'لاتفيا', 2),
  Country('EE', 'إستونيا', 2),
  Country('CY', 'قبرص', 2),
  Country('MT', 'مالطا', 2),
  Country('US', 'الولايات المتحدة', 3),
  Country('CA', 'كندا', 3),
  Country('AU', 'أستراليا', 3),
  Country('NZ', 'نيوزيلندا', 3),
  Country('ZA', 'جنوب أفريقيا', 3),
  Country('BR', 'البرازيل', 3),
  Country('AR', 'الأرجنتين', 3),
  Country('MX', 'المكسيك', 3),
  Country('JP', 'اليابان', 3),
  Country('KR', 'كوريا الجنوبية', 3),
  Country('SG', 'سنغافورة', 3),
  Country('TH', 'تايلاند', 3),
  Country('PH', 'الفلبين', 3),
  Country('VN', 'فيتنام', 3),
  Country('MM', 'ميانمار', 3),
];

const groupNames = ['الدول العربية', 'الدول الإسلامية', 'أوروبا', 'دول أخرى'];

// ======================= أدوات مساعدة =======================
String norm(String s) {
  var t = s.toLowerCase();
  t = t.replaceAll(RegExp('[\u064B-\u065F\u0670\u0640]'), '');
  t = t
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');
  const fr = {
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'û': 'u',
    'ù': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  for (final e in fr.entries) {
    t = t.replaceAll(e.key, e.value);
  }
  return t.trim();
}

int zoneOffsetSec(String zone) {
  try {
    return tz.TZDateTime.now(tz.getLocation(zone)).timeZoneOffset.inSeconds;
  } catch (_) {
    return DateTime.now().timeZoneOffset.inSeconds;
  }
}

class GeoPlace {
  final String ar;
  final String la;
  final String admin;
  final String key;
  final double lat;
  final double lng;
  final int pop;
  final int zone;
  const GeoPlace(this.ar, this.la, this.admin, this.key, this.lat, this.lng,
      this.pop, this.zone);

  String get name => ar.isNotEmpty ? ar : la;
}

class GeoData {
  final List<String> zones;
  final Map<String, List<String>> admins;
  final Map<String, int> counts;
  final List<GeoPlace> places;
  const GeoData(this.zones, this.admins, this.counts, this.places);
}

GeoData parseGeo(String txt) {
  final m = jsonDecode(txt) as Map<String, dynamic>;
  final zones = (m['z'] as List).map((e) => e.toString()).toList();
  final admins = <String, List<String>>{};
  (m['a'] as Map<String, dynamic>).forEach((k, v) {
    final l = v as List;
    admins[k] = [l[0].toString(), l[1].toString()];
  });
  final counts = <String, int>{};
  final places = <GeoPlace>[];
  for (final r in (m['p'] as List)) {
    final l = r as List;
    final ar = l[0].toString();
    final la = l[1].toString();
    var a = l[4].toString();
    if (!admins.containsKey(a)) a = '';
    counts[a] = (counts[a] ?? 0) + 1;
    places.add(GeoPlace(
      ar,
      la,
      a,
      norm('$ar $la'),
      (l[2] as num).toDouble(),
      (l[3] as num).toDouble(),
      (l[5] as num).toInt(),
      (l[6] as num).toInt(),
    ));
  }
  return GeoData(zones, admins, counts, places);
}

Future<Place?> manualPlaceDialog(
    BuildContext context, String countryName, String initial) {
  final nameC = TextEditingController(text: initial);
  final latC = TextEditingController();
  final lngC = TextEditingController();
  return showDialog<Place>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('إدخال موقع يدوياً'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration:
                  const InputDecoration(labelText: 'اسم المدينة أو البلدية'),
            ),
            TextField(
              controller: latC,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration:
                  const InputDecoration(labelText: 'خط العرض (مثال 36.45)'),
            ),
            TextField(
              controller: lngC,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration:
                  const InputDecoration(labelText: 'خط الطول (مثال 6.26)'),
            ),
            const SizedBox(height: 10),
            const Text(
              'تجد الإحداثيات في خرائط جوجل: اضغط مطولاً على مكانك فتظهر الأرقام.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            final lat = double.tryParse(latC.text.trim().replaceAll(',', '.'));
            final lng = double.tryParse(lngC.text.trim().replaceAll(',', '.'));
            final nm = nameC.text.trim();
            if (nm.isEmpty ||
                lat == null ||
                lng == null ||
                lat.abs() > 90 ||
                lng.abs() > 180) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تأكد من الاسم ومن صحة الأرقام')));
              return;
            }
            Navigator.pop(
                ctx, Place(name: nm, sub: countryName, lat: lat, lng: lng));
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}

// ======================= قائمة الدول =======================
class CountryPage extends StatefulWidget {
  const CountryPage({super.key});

  @override
  State<CountryPage> createState() => _CountryPageState();
}

class _CountryPageState extends State<CountryPage> {
  String _q = '';

  Future<void> _open(Country c) async {
    final res = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => GeoCountryPage(country: c)),
    );
    if (res != null && mounted) Navigator.pop(context, res);
  }

  Future<void> _global() async {
    final res = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
    if (res != null && mounted) Navigator.pop(context, res);
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim();
    final primary = Theme.of(context).colorScheme.primary;
    final children = <Widget>[
      ListTile(
        leading: const Icon(Icons.public),
        title: const Text('ابحث عن مدينة في كل الدول'),
        trailing: const Icon(Icons.chevron_left),
        onTap: _global,
      ),
      const Divider(),
    ];
    for (int g = 0; g < 4; g++) {
      final list = countries
          .where((x) => x.group == g && (q.isEmpty || x.name.contains(q)))
          .toList();
      if (list.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(groupNames[g],
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: primary)),
      ));
      for (final x in list) {
        children.add(ListTile(
          leading: Text(x.flag, style: const TextStyle(fontSize: 28)),
          title: Text(x.name, style: const TextStyle(fontSize: 18)),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => _open(x),
        ));
      }
    }
    children.add(const Padding(
      padding: EdgeInsets.all(16),
      child: Text('بيانات المواقع: GeoNames (CC BY 4.0)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey)),
    ));
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: const InputDecoration(
            hintText: 'اختر الدولة أو ابحث عنها',
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView(
        padding:
            EdgeInsets.only(bottom: 24 + MediaQuery.of(context).padding.bottom),
        children: children,
      ),
    );
  }
}

// ======================= ولايات الدولة وبلدياتها (بدون إنترنت) =======================
class GeoCountryPage extends StatefulWidget {
  final Country country;
  const GeoCountryPage({super.key, required this.country});

  @override
  State<GeoCountryPage> createState() => _GeoCountryPageState();
}

class _GeoCountryPageState extends State<GeoCountryPage> {
  GeoData? _data;
  bool _loading = true;
  bool _failed = false;
  String _q = '';
  String? _admin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final txt = await rootBundle
          .loadString('assets/geo/${widget.country.code}.json');
      final d = await compute(parseGeo, txt);
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  String _adminName(GeoData d, String code) {
    final a = d.admins[code];
    if (a == null) return 'أخرى';
    return a[0].isNotEmpty ? a[0] : a[1];
  }

  Place _toPlace(GeoPlace g, GeoData d) {
    final parts = <String>[];
    if (g.ar.isNotEmpty && g.la.isNotEmpty) parts.add(g.la);
    final an = _adminName(d, g.admin);
    if (an != g.name && an != 'أخرى') parts.add(an);
    parts.add(widget.country.name);
    final zone =
        (g.zone >= 0 && g.zone < d.zones.length) ? d.zones[g.zone] : '';
    return Place(
      name: g.name,
      sub: parts.join('، '),
      lat: g.lat,
      lng: g.lng,
      offsetSec: zoneOffsetSec(zone),
    );
  }

  Widget _placeTile(GeoPlace g, GeoData d, {bool withAdmin = false}) {
    final sub = <String>[];
    if (g.ar.isNotEmpty && g.la.isNotEmpty) sub.add(g.la);
    if (withAdmin) {
      final an = _adminName(d, g.admin);
      if (an != g.name) sub.add(an);
    }
    return ListTile(
      leading: const Icon(Icons.location_city),
      title: Text(g.name, style: const TextStyle(fontSize: 17)),
      subtitle: sub.isEmpty ? null : Text(sub.join(' • ')),
      onTap: () => Navigator.pop(context, _toPlace(g, d)),
    );
  }

  Future<void> _online() async {
    final res = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => CityPage(country: widget.country)),
    );
    if (res != null && mounted) Navigator.pop(context, res);
  }

  Future<void> _manual() async {
    final res =
        await manualPlaceDialog(context, widget.country.name, _q.trim());
    if (res != null && mounted) Navigator.pop(context, res);
  }

  Widget _tools() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.cloud_outlined, size: 18),
              label: const Text('بحث عبر الإنترنت'),
              onPressed: _online,
            ),
            ActionChip(
              avatar: const Icon(Icons.edit_location_alt, size: 18),
              label: const Text('إحداثيات يدوية'),
              onPressed: _manual,
            ),
          ],
        ),
      );

  Widget _content(GeoData d) {
    final nq = norm(_q);
    final bottom = MediaQuery.of(context).padding.bottom;
    final flat = d.admins.length <= 1;
    Widget? top;
    late int count;
    late Widget Function(int) builder;

    if (nq.isNotEmpty) {
      final res = d.places.where((p) => p.key.contains(nq)).toList()
        ..sort((a, b) => b.pop.compareTo(a.pop));
      final shown = res.take(200).toList();
      count = shown.length;
      builder = (i) => _placeTile(shown[i], d, withAdmin: true);
    } else if (_admin == null && !flat) {
      final keys = d.admins.keys.where((k) => (d.counts[k] ?? 0) > 0).toList();
      keys.sort((a, b) =>
          norm(_adminName(d, a)).compareTo(norm(_adminName(d, b))));
      if ((d.counts[''] ?? 0) > 0) keys.add('');
      count = keys.length;
      builder = (i) {
        final k = keys[i];
        final a = d.admins[k];
        final latin = (a != null && a[0].isNotEmpty) ? a[1] : '';
        return ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(_adminName(d, k), style: const TextStyle(fontSize: 18)),
          subtitle: latin.isEmpty ? null : Text(latin),
          trailing: Text(arDigits('${d.counts[k] ?? 0}'),
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          onTap: () => setState(() => _admin = k),
        );
      };
    } else {
      final list = d.places.where((p) => flat || p.admin == _admin).toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      if (!flat) {
        top = ListTile(
          leading: const Icon(Icons.arrow_forward),
          title: Text(_adminName(d, _admin ?? ''),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('اضغط للرجوع إلى القائمة'),
          onTap: () => setState(() => _admin = null),
        );
      }
      count = list.length;
      builder = (i) => _placeTile(list[i], d);
    }

    return Column(
      children: [
        if (top != null) top,
        _tools(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 24 + bottom),
            itemCount: count,
            itemBuilder: (ctx, i) => builder(i),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return CityPage(country: widget.country);
    final d = _data;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            hintText: '${widget.country.flag} ابحث في ${widget.country.name}',
            border: InputBorder.none,
          ),
        ),
      ),
      body: (_loading || d == null)
          ? const Center(child: CircularProgressIndicator())
          : _content(d),
    );
  }
}

// ======================= البحث عبر الإنترنت داخل دولة =======================
class CityPage extends StatefulWidget {
  final Country country;
  const CityPage({super.key, required this.country});

  @override
  State<CityPage> createState() => _CityPageState();
}

class _CityPageState extends State<CityPage> {
  final _c = TextEditingController();
  Timer? _deb;
  List<Place> _res = [];
  bool _loading = false;
  bool _searched = false;
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
        _searched = false;
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
        'count': '50',
        'language': 'ar',
        'format': 'json',
        'countryCode': widget.country.code,
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final list = (data['results'] as List?) ?? [];
      final out = list.map((e) {
        final m = e as Map<String, dynamic>;
        final nm = m['name'].toString();
        final parts = <String>[];
        for (final k in ['admin2', 'admin1']) {
          final v = m[k]?.toString();
          if (v != null && v != nm && !parts.contains(v)) parts.add(v);
        }
        parts.add(widget.country.name);
        return Place(
          name: nm,
          sub: parts.join('، '),
          lat: (m['latitude'] as num).toDouble(),
          lng: (m['longitude'] as num).toDouble(),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _res = out;
        _loading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذر البحث. تأكد من اتصالك بالإنترنت';
        _loading = false;
      });
    }
  }

  Future<void> _manual() async {
    final res = await manualPlaceDialog(
        context, widget.country.name, _c.text.trim());
    if (res != null && mounted) Navigator.pop(context, res);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _c,
          autofocus: true,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: '${widget.country.flag} اكتب اسم المدينة أو البلدية',
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 24 + bottom),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_err!, style: const TextStyle(color: Colors.red)),
            ),
          if (!_searched && _res.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'ابحث في ${widget.country.name}: اكتب حرفين على الأقل. وإن لم يظهر الاسم بالعربية فجرّب بالحروف اللاتينية.',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          if (_searched && _res.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                  'لا توجد نتائج. جرّب كتابة الاسم بشكل آخر، أو أدخل الإحداثيات يدوياً.',
                  style: TextStyle(fontSize: 15)),
            ),
          for (final p in _res)
            ListTile(
              leading: const Icon(Icons.location_city),
              title: Text(p.name),
              subtitle: p.sub.isEmpty ? null : Text(p.sub),
              onTap: () => Navigator.pop(context, p),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_location_alt),
            title: const Text('لم تجد مدينتك؟ أدخل إحداثياتها يدوياً'),
            onTap: _manual,
          ),
        ],
      ),
    );
  }
}

// ======================= البحث في كل الدول =======================
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
        'count': '30',
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
            hintText: 'اكتب اسم المدينة في أي دولة',
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
              padding: EdgeInsets.only(
                  bottom: 24 + MediaQuery.of(context).padding.bottom),
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
