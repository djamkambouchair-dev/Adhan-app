import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'main.dart';
import 'pages.dart';

const double kaabaLat = 21.422487;
const double kaabaLng = 39.826206;

double qiblaBearing(double lat, double lng) {
  final p1 = lat * math.pi / 180;
  final p2 = kaabaLat * math.pi / 180;
  final dl = (kaabaLng - lng) * math.pi / 180;
  final y = math.sin(dl) * math.cos(p2);
  final x = math.cos(p1) * math.sin(p2) -
      math.sin(p1) * math.cos(p2) * math.cos(dl);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

double distanceToKaabaKm(double lat, double lng) {
  const r = 6371.0;
  final p1 = lat * math.pi / 180;
  final p2 = kaabaLat * math.pi / 180;
  final dp = p2 - p1;
  final dl = (kaabaLng - lng) * math.pi / 180;
  final a = math.pow(math.sin(dp / 2), 2) +
      math.cos(p1) * math.cos(p2) * math.pow(math.sin(dl / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

class QiblaPage extends StatefulWidget {
  final Place place;
  const QiblaPage({super.key, required this.place});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<AccelerometerEvent>? _aSub;
  StreamSubscription<MagnetometerEvent>? _mSub;
  Timer? _chk;
  List<double>? _g;
  List<double>? _m;
  double? _heading;
  bool _noSensor = false;
  bool _wasAligned = false;
  late final double _qibla;
  late final double _dist;

  @override
  void initState() {
    super.initState();
    _qibla = qiblaBearing(widget.place.lat, widget.place.lng);
    _dist = distanceToKaabaKm(widget.place.lat, widget.place.lng);
    try {
      _aSub = accelerometerEventStream(
              samplingPeriod: SensorInterval.uiInterval)
          .listen((e) {
        _g = _smooth(_g, [e.x, e.y, e.z]);
        _update();
      }, onError: (_) {
        if (mounted) setState(() => _noSensor = true);
      });
      _mSub = magnetometerEventStream(
              samplingPeriod: SensorInterval.uiInterval)
          .listen((e) {
        _m = _smooth(_m, [e.x, e.y, e.z]);
        _update();
      }, onError: (_) {
        if (mounted) setState(() => _noSensor = true);
      });
    } catch (_) {
      _noSensor = true;
    }
    _chk = Timer(const Duration(seconds: 3), () {
      if (mounted && _heading == null) setState(() => _noSensor = true);
    });
  }

  @override
  void dispose() {
    _aSub?.cancel();
    _mSub?.cancel();
    _chk?.cancel();
    super.dispose();
  }

  List<double> _smooth(List<double>? old, List<double> v) {
    if (old == null) return v;
    const a = 0.15;
    return [for (int i = 0; i < 3; i++) old[i] + a * (v[i] - old[i])];
  }

  void _update() {
    final g = _g;
    final m = _m;
    if (g == null || m == null) return;
    final ax = g[0];
    final ay = g[1];
    final az = g[2];
    final ex = m[0];
    final ey = m[1];
    final ez = m[2];
    var hx = ey * az - ez * ay;
    var hy = ez * ax - ex * az;
    var hz = ex * ay - ey * ax;
    final nh = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (nh < 0.1) return;
    hx /= nh;
    hy /= nh;
    hz /= nh;
    final na = math.sqrt(ax * ax + ay * ay + az * az);
    if (na == 0) return;
    final nax = ax / na;
    final naz = az / na;
    final my = naz * hx - nax * hz;
    final deg = (math.atan2(hy, my) * 180 / math.pi + 360) % 360;
    final diff = ((_qibla - deg + 540) % 360) - 180;
    final al = diff.abs() <= 4;
    if (al && !_wasAligned) HapticFeedback.mediumImpact();
    _wasAligned = al;
    if (!mounted) return;
    setState(() {
      _heading = deg;
      _noSensor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = palettes[themeIdx.value];
    final h = _heading;
    final diff = h == null ? null : ((_qibla - h + 540) % 360) - 180;
    final aligned = diff != null && diff.abs() <= 4;
    final qDeg = arDigits(_qibla.round().toString());
    String status;
    if (aligned) {
      status = t('q_aligned');
    } else if (h == null) {
      status = _noSensor ? t('q_no_sensor') : t('q_reading');
    } else {
      status = t('q_rotate');
    }
    final pname = widget.place.gps ? t('my_location') : widget.place.name;
    return Scaffold(
      appBar: AppBar(title: Text(t('qibla_title', [pname]))),
      body: Container(
        decoration: pageBg(c),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: aligned ? const Color(0xFF0A9A0A) : c.text)),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: CustomPaint(
                        painter: CompassPainter(
                          heading: h ?? 0,
                          qibla: _qibla,
                          aligned: aligned,
                          text: c.text,
                          soft: c.soft,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.row,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(t('q_bearing', [qDeg]),
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: c.text)),
                    const SizedBox(height: 4),
                    Text(
                        t('q_distance',
                            [arDigits(_dist.round().toString())]),
                        style: TextStyle(fontSize: 15, color: c.text)),
                    if (h != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          t('q_heading', [arDigits(h.round().toString())]),
                          style: TextStyle(fontSize: 14, color: c.soft)),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Text(
                    (_noSensor && h == null)
                        ? t('q_help_nosensor', [qDeg])
                        : t('q_note'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: c.soft)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  final double heading;
  final double qibla;
  final bool aligned;
  final Color text;
  final Color soft;
  const CompassPainter({
    required this.heading,
    required this.qibla,
    required this.aligned,
    required this.text,
    required this.soft,
  });

  void _label(Canvas canvas, String s, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
            color: color, fontSize: size, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);
    final center = Offset(cx, cy);
    canvas.drawCircle(center, r, Paint()..color = soft.withAlpha(30));
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = text.withAlpha(120)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-heading * math.pi / 180);

    for (int i = 0; i < 72; i++) {
      final a = i * 5 * math.pi / 180;
      final major = i % 6 == 0;
      final len = major ? r * 0.10 : r * 0.05;
      final p = Paint()
        ..color = text.withAlpha(major ? 220 : 110)
        ..strokeWidth = major ? 2.5 : 1.2;
      canvas.drawLine(
        Offset(math.sin(a) * (r - 4), -math.cos(a) * (r - 4)),
        Offset(math.sin(a) * (r - 4 - len), -math.cos(a) * (r - 4 - len)),
        p,
      );
    }

    const letters = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final ang = i * 90 * math.pi / 180;
      canvas.save();
      canvas.translate(math.sin(ang) * r * 0.74, -math.cos(ang) * r * 0.74);
      canvas.rotate(heading * math.pi / 180);
      _label(canvas, letters[i], r * 0.13, i == 0 ? Colors.red : text);
      canvas.restore();
    }

    final qa = qibla * math.pi / 180;
    final tip = Offset(math.sin(qa) * r * 0.58, -math.cos(qa) * r * 0.58);
    final needleColor =
        aligned ? const Color(0xFF0A9A0A) : const Color(0xFF1B7F3B);
    canvas.drawLine(
        Offset.zero,
        tip,
        Paint()
          ..color = needleColor
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);

    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(heading * math.pi / 180);
    final s = r * 0.14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 2),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black,
    );
    canvas.drawRect(
      Rect.fromLTWH(-s, -s * 0.45, s * 2, s * 0.28),
      Paint()..color = const Color(0xFFE0B040),
    );
    canvas.restore();
    canvas.restore();

    final tri = Path()
      ..moveTo(cx, cy - r - 2)
      ..lineTo(cx - 12, cy - r + 22)
      ..lineTo(cx + 12, cy - r + 22)
      ..close();
    canvas.drawPath(
        tri,
        Paint()
          ..color = aligned ? const Color(0xFF0A9A0A) : Colors.red.shade700);
    canvas.drawCircle(center, 6, Paint()..color = text);
  }

  @override
  bool shouldRepaint(covariant CompassPainter old) => true;
}
