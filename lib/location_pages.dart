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
  final String ar;
  final String en;
  final String fr;
  final int group;
  const Country(this.code, this.ar, this.en, this.fr, this.group);

  String get name => isAr ? ar : (currentLang == 'en' ? en : fr);
  String get flag =>
      String.fromCharCodes(code.codeUnits.map((u) => 0x1F1E6 + u - 65));
}

// المجموعات: 0 عربية، 1 إسلامية، 2 أوروبا، 3 أخرى
const countries = <Country>[
  Country('SA', 'السعودية', 'Saudi Arabia', 'Arabie saoudite', 0),
  Country('AE', 'الإمارات', 'United Arab Emirates', 'Émirats arabes unis', 0),
  Country('QA', 'قطر', 'Qatar', 'Qatar', 0),
  Country('KW', 'الكويت', 'Kuwait', 'Koweït', 0),
  Country('BH', 'البحرين', 'Bahrain', 'Bahreïn', 0),
  Country('OM', 'عُمان', 'Oman', 'Oman', 0),
  Country('YE', 'اليمن', 'Yemen', 'Yémen', 0),
  Country('IQ', 'العراق', 'Iraq', 'Irak', 0),
  Country('SY', 'سوريا', 'Syria', 'Syrie', 0),
  Country('LB', 'لبنان', 'Lebanon', 'Liban', 0),
  Country('JO', 'الأردن', 'Jordan', 'Jordanie', 0),
  Country('PS', 'فلسطين', 'Palestine', 'Palestine', 0),
  Country('EG', 'مصر', 'Egypt', 'Égypte', 0),
  Country('SD', 'السودان', 'Sudan', 'Soudan', 0),
  Country('LY', 'ليبيا', 'Libya', 'Libye', 0),
  Country('TN', 'تونس', 'Tunisia', 'Tunisie', 0),
  Country('DZ', 'الجزائر', 'Algeria', 'Algérie', 0),
  Country('MA', 'المغرب', 'Morocco', 'Maroc', 0),
  Country('MR', 'موريتانيا', 'Mauritania', 'Mauritanie', 0),
  Country('SO', 'الصومال', 'Somalia', 'Somalie', 0),
  Country('DJ', 'جيبوتي', 'Djibouti', 'Djibouti', 0),
  Country('KM', 'جزر القمر', 'Comoros', 'Comores', 0),
  Country('TR', 'تركيا', 'Türkiye', 'Turquie', 1),
  Country('IR', 'إيران', 'Iran', 'Iran', 1),
  Country('PK', 'باكستان', 'Pakistan', 'Pakistan', 1),
  Country('AF', 'أفغانستان', 'Afghanistan', 'Afghanistan', 1),
  Country('BD', 'بنغلاديش', 'Bangladesh', 'Bangladesh', 1),
  Country('ID', 'إندونيسيا', 'Indonesia', 'Indonésie', 1),
  Country('MY', 'ماليزيا', 'Malaysia', 'Malaisie', 1),
  Country('BN', 'بروناي', 'Brunei', 'Brunéi', 1),
  Country('MV', 'المالديف', 'Maldives', 'Maldives', 1),
  Country('SN', 'السنغال', 'Senegal', 'Sénégal', 1),
  Country('ML', 'مالي', 'Mali', 'Mali', 1),
  Country('NE', 'النيجر', 'Niger', 'Niger', 1),
  Country('TD', 'تشاد', 'Chad', 'Tchad', 1),
  Country('NG', 'نيجيريا', 'Nigeria', 'Nigéria', 1),
  Country('GM', 'غامبيا', 'Gambia', 'Gambie', 1),
  Country('GN', 'غينيا', 'Guinea', 'Guinée', 1),
  Country('SL', 'سيراليون', 'Sierra Leone', 'Sierra Leone', 1),
  Country('BF', 'بوركينا فاسو', 'Burkina Faso', 'Burkina Faso', 1),
  Country('CI', 'ساحل العاج', "Côte d'Ivoire", "Côte d'Ivoire", 1),
  Country('GH', 'غانا', 'Ghana', 'Ghana', 1),
  Country('ET', 'إثيوبيا', 'Ethiopia', 'Éthiopie', 1),
  Country('ER', 'إريتريا', 'Eritrea', 'Érythrée', 1),
  Country('KE', 'كينيا', 'Kenya', 'Kenya', 1),
  Country('TZ', 'تنزانيا', 'Tanzania', 'Tanzanie', 1),
  Country('UG', 'أوغندا', 'Uganda', 'Ouganda', 1),
  Country('AZ', 'أذربيجان', 'Azerbaijan', 'Azerbaïdjan', 1),
  Country('KZ', 'كازاخستان', 'Kazakhstan', 'Kazakhstan', 1),
  Country('UZ', 'أوزبكستان', 'Uzbekistan', 'Ouzbékistan', 1),
  Country('TM', 'تركمانستان', 'Turkmenistan', 'Turkménistan', 1),
  Country('TJ', 'طاجيكستان', 'Tajikistan', 'Tadjikistan', 1),
  Country('KG', 'قيرغيزستان', 'Kyrgyzstan', 'Kirghizistan', 1),
  Country('AL', 'ألبانيا', 'Albania', 'Albanie', 1),
  Country('XK', 'كوسوفو', 'Kosovo', 'Kosovo', 1),
  Country('BA', 'البوسنة والهرسك', 'Bosnia and Herzegovina', 'Bosnie-Herzégovine', 1),
  Country('LK', 'سريلانكا', 'Sri Lanka', 'Sri Lanka', 1),
  Country('IN', 'الهند', 'India', 'Inde', 1),
  Country('CN', 'الصين', 'China', 'Chine', 1),
  Country('DE', 'ألمانيا', 'Germany', 'Allemagne', 2),
  Country('FR', 'فرنسا', 'France', 'France', 2),
  Country('GB', 'بريطانيا', 'United Kingdom', 'Royaume-Uni', 2),
  Country('ES', 'إسبانيا', 'Spain', 'Espagne', 2),
  Country('IT', 'إيطاليا', 'Italy', 'Italie', 2),
  Country('NL', 'هولندا', 'Netherlands', 'Pays-Bas', 2),
  Country('BE', 'بلجيكا', 'Belgium', 'Belgique', 2),
  Country('CH', 'سويسرا', 'Switzerland', 'Suisse', 2),
  Country('AT', 'النمسا', 'Austria', 'Autriche', 2),
  Country('SE', 'السويد', 'Sweden', 'Suède', 2),
  Country('NO', 'النرويج', 'Norway', 'Norvège', 2),
  Country('DK', 'الدنمارك', 'Denmark', 'Danemark', 2),
  Country('FI', 'فنلندا', 'Finland', 'Finlande', 2),
  Country('IE', 'أيرلندا', 'Ireland', 'Irlande', 2),
  Country('PT', 'البرتغال', 'Portugal', 'Portugal', 2),
  Country('GR', 'اليونان', 'Greece', 'Grèce', 2),
  Country('PL', 'بولندا', 'Poland', 'Pologne', 2),
  Country('CZ', 'التشيك', 'Czechia', 'Tchéquie', 2),
  Country('HU', 'المجر', 'Hungary', 'Hongrie', 2),
  Country('RO', 'رومانيا', 'Romania', 'Roumanie', 2),
  Country('BG', 'بلغاريا', 'Bulgaria', 'Bulgarie', 2),
  Country('RS', 'صربيا', 'Serbia', 'Serbie', 2),
  Country('HR', 'كرواتيا', 'Croatia', 'Croatie', 2),
  Country('SI', 'سلوفينيا', 'Slovenia', 'Slovénie', 2),
  Country('SK', 'سلوفاكيا', 'Slovakia', 'Slovaquie', 2),
  Country('UA', 'أوكرانيا', 'Ukraine', 'Ukraine', 2),
  Country('RU', 'روسيا', 'Russia', 'Russie', 2),
  Country('LU', 'لوكسمبورغ', 'Luxembourg', 'Luxembourg', 2),
  Country('IS', 'آيسلندا', 'Iceland', 'Islande', 2),
  Country('MK', 'مقدونيا الشمالية', 'North Macedonia', 'Macédoine du Nord', 2),
  Country('ME', 'الجبل الأسود', 'Montenegro', 'Monténégro', 2),
  Country('MD', 'مولدوفا', 'Moldova', 'Moldavie', 2),
  Country('BY', 'بيلاروسيا', 'Belarus', 'Biélorussie', 2),
  Country('LT', 'ليتوانيا', 'Lithuania', 'Lituanie', 2),
  Country('LV', 'لاتفيا', 'Latvia', 'Lettonie', 2),
  Country('EE', 'إستونيا', 'Estonia', 'Estonie', 2),
  Country('CY', 'قبرص', 'Cyprus', 'Chypre', 2),
  Country('MT', 'مالطا', 'Malta', 'Malte', 2),
  Country('US', 'الولايات المتحدة', 'United States', 'États-Unis', 3),
  Country('CA', 'كندا', 'Canada', 'Canada', 3),
  Country('AU', 'أستراليا', 'Australia', 'Australie', 3),
  Country('NZ', 'نيوزيلندا', 'New Zealand', 'Nouvelle-Zélande', 3),
  Country('ZA', 'جنوب أفريقيا', 'South Africa', 'Afrique du Sud', 3),
  Country('BR', 'البرازيل', 'Brazil', 'Brésil', 3),
  Country('AR', 'الأرجنتين', 'Argentina', 'Argentine', 3),
  Country('MX', 'المكسيك', 'Mexico', 'Mexique', 3),
  Country('JP', 'اليابان', 'Japan', 'Japon', 3),
  Country('KR', 'كوريا الجنوبية', 'South Korea', 'Corée du Sud', 3),
  Country('SG', 'سنغافورة', 'Singapore', 'Singapour', 3),
  Country('TH', 'تايلاند', 'Thailand', 'Thaïlande', 3),
  Country('PH', 'الفلبين', 'Philippines', 'Philippines', 3),
  Country('VN', 'فيتنام', 'Vietnam', 'Viêt Nam', 3),
  Country('MM', 'ميانمار', 'Myanmar', 'Myanmar', 3),
];

// ======================= أدوات مساعدة =======================
String norm(String s) {
  var x = s.toLowerCase();
  x = x.replaceAll(RegExp('[\u064B-\u065F\u0670\u0640]'), '');
  x = x
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');
  const fr = {
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'à': 'a', 'â': 'a', 'ä': 'a',
    'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'û': 'u', 'ù': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };
  for (final e in fr.entries) {
    x = x.replaceAll(e.key, e.value);
  }
  return x.trim();
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

  String get name =>
      isAr ? (ar.isNotEmpty ? ar : la) : (la.isNotEmpty ? la : ar);
  String get alt => isAr ? la : ar;
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
  const kb = TextInputType.numberWithOptions(decimal: true, signed: true);
  return showDialog<Place>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('manual_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: InputDecoration(labelText: t('place_name_label')),
            ),
            TextField(
              controller: latC,
              keyboardType: kb,
              decoration: InputDecoration(labelText: t('lat_label')),
            ),
            TextField(
              controller: lngC,
              keyboardType: kb,
              decoration: InputDecoration(labelText: t('lng_label')),
            ),
            const SizedBox(height: 10),
            Text(t('coords_help'), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
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
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('check_inputs'))));
              return;
            }
            Navigator.pop(
                ctx, Place(name: nm, sub: countryName, lat: lat, lng: lng));
          },
          child: Text(t('save')),
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
    final nq = norm(q);
    final primary = Theme.of(context).colorScheme.primary;
    final groupNames = [
      t('g_arab'),
      t('g_islamic'),
      t('g_europe'),
      t('g_other'),
    ];
    final children = <Widget>[
      ListTile(
        leading: const Icon(Icons.public),
        title: Text(t('search_all_world')),
        trailing: Icon(isAr ? Icons.chevron_left : Icons.chevron_right),
        onTap: _global,
      ),
      const Divider(),
    ];
    for (int g = 0; g < 4; g++) {
      final list = countries
          .where((x) =>
              x.group == g &&
              (q.isEmpty ||
                  x.ar.contains(q) ||
                  norm(x.en).contains(nq) ||
                  norm(x.fr).contains(nq)))
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
          trailing: Icon(isAr ? Icons.chevron_left : Icons.chevron_right),
          onTap: () => _open(x),
        ));
      }
    }
    children.add(Padding(
      padding: const EdgeInsets.all(16),
      child: Text(t('geo_credit'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ));
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            hintText: t('pick_country_hint'),
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
    if (a == null) return t('other');
    if (isAr) return a[0].isNotEmpty ? a[0] : a[1];
    return a[1].isNotEmpty ? a[1] : a[0];
  }

  Place _toPlace(GeoPlace g, GeoData d) {
    final parts = <String>[];
    if (g.alt.isNotEmpty && g.alt != g.name) parts.add(g.alt);
    final an = _adminName(d, g.admin);
    if (an != g.name && g.admin.isNotEmpty) parts.add(an);
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
    if (g.alt.isNotEmpty && g.alt != g.name) sub.add(g.alt);
    if (withAdmin && g.admin.isNotEmpty) {
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
              label: Text(t('online_search')),
              onPressed: _online,
            ),
            ActionChip(
              avatar: const Icon(Icons.edit_location_alt, size: 18),
              label: Text(t('manual_coords')),
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
        String alt = '';
        if (a != null) {
          alt = isAr ? a[1] : a[0];
          if (alt == _adminName(d, k)) alt = '';
        }
        return ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(_adminName(d, k), style: const TextStyle(fontSize: 18)),
          subtitle: alt.isEmpty ? null : Text(alt),
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
          leading: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back),
          title: Text(_adminName(d, _admin ?? ''),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(t('tap_back_list')),
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
            hintText:
                '${widget.country.flag} ${t('search_in', [widget.country.name])}',
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
  bool _err = false;

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
        _err = false;
        _searched = false;
      });
      return;
    }
    _deb = Timer(const Duration(milliseconds: 500), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _err = false;
    });
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': q,
        'count': '50',
        'language': isAr ? 'ar' : currentLang,
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
        _err = true;
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
            hintText: '${widget.country.flag} ${t('type_city_hint')}',
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 24 + bottom),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_err)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t('search_failed'),
                  style: const TextStyle(color: Colors.red)),
            ),
          if (!_searched && _res.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(t('city_search_help', [widget.country.name]),
                  style: const TextStyle(fontSize: 15)),
            ),
          if (_searched && _res.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(t('no_results'),
                  style: const TextStyle(fontSize: 15)),
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
            title: Text(t('not_found_manual')),
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
  bool _err = false;

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
        _err = false;
      });
      return;
    }
    _deb = Timer(const Duration(milliseconds: 500), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _err = false;
    });
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': q,
        'count': '30',
        'language': isAr ? 'ar' : currentLang,
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
        _err = true;
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
          decoration: InputDecoration(
            hintText: t('global_hint'),
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_err)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t('search_failed'),
                  style: const TextStyle(color: Colors.red)),
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
