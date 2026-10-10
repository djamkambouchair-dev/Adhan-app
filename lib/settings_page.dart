import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

const Color _green = Color(0xFF0B8F5F);

class ThemePreview extends StatelessWidget {
  final AppPalette p;
  final bool selected;
  const ThemePreview({super.key, required this.p, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _green : Colors.black26,
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
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 52,
              child: CustomPaint(painter: SkylinePainter(p.skyline)),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 24,
              height: 8,
              child: ColoredBox(color: p.row),
            ),
            const Positioned(
              left: 8,
              right: 8,
              bottom: 12,
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
            if (selected)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.check_circle, color: _green, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final VoidCallback onChangeLocation;
  final VoidCallback onTestNow;
  final VoidCallback onTestLater;
  final VoidCallback onBattery;
  const SettingsPage({
    super.key,
    required this.onChangeLocation,
    required this.onTestNow,
    required this.onTestLater,
    required this.onBattery,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([cfg, themeIdx, placeLabel]),
      builder: (context, _) => _body(context),
    );
  }

  Future<void> _setTheme(int i) async {
    themeIdx.value = i;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('theme', i);
  }

  void _pickMethod(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: appDir,
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final k in methodKeys)
                ListTile(
                  title: Text(t('m_$k')),
                  trailing: cfg.method == k
                      ? const Icon(Icons.check_circle, color: _green)
                      : null,
                  onTap: () {
                    cfg.update(() => cfg.method = k);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _about(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: appDir,
        child: AlertDialog(
          title: Text(t('about_app')),
          content: Text(t('about_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('close')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final c = palettes[themeIdx.value];
    final dark = isDarkTheme(themeIdx.value);
    final cardColor = dark ? const Color(0x24FFFFFF) : const Color(0xD9FFFFFF);
    final border = dark ? const Color(0x22FFFFFF) : const Color(0x12000000);
    final bottom = MediaQuery.of(context).padding.bottom;
    final rtl = appDir == TextDirection.rtl;
    final label =
        placeLabel.value.isEmpty ? t('my_location') : placeLabel.value;

    Widget card(List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: cardColor,
            elevation: dark ? 0 : 1.5,
            shadowColor: const Color(0x22000000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        );

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: _green,
            ),
          ),
        );

    Widget badge(IconData ic, Color col) => Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: col.withAlpha(36),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(ic, color: col, size: 21),
        );

    Widget divider() =>
        Divider(height: 1, indent: 62, endIndent: 0, color: border);

    Widget tile({
      IconData icon = Icons.circle,
      Color color = _green,
      Widget? leading,
      required String title,
      String? sub,
      Widget? trailing,
      VoidCallback? onTap,
    }) =>
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                leading ?? badge(icon, color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.text)),
                      if (sub != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(sub,
                              style: TextStyle(
                                  fontSize: 12.5, height: 1.3, color: c.soft)),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),
        );

    Widget switchTile(IconData ic, Color col, String title, String sub,
            bool v, void Function(bool) f) =>
        tile(
          icon: ic,
          color: col,
          title: title,
          sub: sub,
          onTap: () => f(!v),
          trailing: Switch(value: v, onChanged: f, activeColor: _green),
        );

    Widget chevron() => Icon(
          rtl ? Icons.chevron_left : Icons.chevron_right,
          color: c.soft,
        );

    Widget stepBtn(IconData ic, VoidCallback? f) => IconButton.filledTonal(
          icon: Icon(ic, size: 18),
          onPressed: f,
          visualDensity: VisualDensity.compact,
        );

    return Directionality(
      textDirection: appDir,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: c.bg,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + bottom),
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: c.text),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(t('settings'),
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: c.text)),
                  ],
                ),
                const SizedBox(height: 8),

                // ---------- بطاقة الموقع ----------
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onChangeLocation,
                    borderRadius: BorderRadius.circular(22),
                    child: Ink(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Color(0xFF0B6E4F), Color(0xFF12A37A)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0x33FFFFFF),
                            child: Icon(Icons.mosque,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t('current_location'),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(t('change_location'),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_location_alt,
                              color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---------- المظهر واللغة ----------
                section(t('sec_appearance')),
                card([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Row(
                      children: [
                        badge(Icons.palette, const Color(0xFFEC4899)),
                        const SizedBox(width: 12),
                        Text(t('theme'),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.text)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: palettes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) => GestureDetector(
                        onTap: () => _setTheme(i),
                        child: Column(
                          children: [
                            ThemePreview(
                                p: palettes[i], selected: themeIdx.value == i),
                            const SizedBox(height: 6),
                            Text(t('th$i'),
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: themeIdx.value == i
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: c.text)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Row(
                      children: [
                        badge(Icons.translate, _green),
                        const SizedBox(width: 12),
                        Text(t('language'),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.text)),
                      ],
                    ),
                  ),
                  for (int i = 0; i < langs.length; i++)
                    InkWell(
                      onTap: () => cfg.update(() => cfg.lang = langs[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cfg.lang == langs[i]
                                    ? _green
                                    : _green.withAlpha(30),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                const ['ع', 'EN', 'FR'][i],
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: cfg.lang == langs[i]
                                        ? Colors.white
                                        : _green),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(langNames[i],
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: cfg.lang == langs[i]
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: c.text)),
                            ),
                            if (cfg.lang == langs[i])
                              const Icon(Icons.check_circle, color: _green),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ]),

                // ---------- مواقيت الصلاة ----------
                section(t('sec_times')),
                card([
                  tile(
                    icon: Icons.calculate,
                    color: const Color(0xFF8B5CF6),
                    title: t('calc_method'),
                    sub: t('m_${cfg.method}'),
                    trailing: chevron(),
                    onTap: () => _pickMethod(context),
                  ),
                  divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            badge(Icons.wb_twilight, const Color(0xFF14B8A6)),
                            const SizedBox(width: 12),
                            Text(t('juristic'),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: c.text)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                  value: false, label: Text(t('asr_standard'))),
                              ButtonSegment(
                                  value: true, label: Text(t('asr_hanafi'))),
                            ],
                            selected: {cfg.hanafi},
                            onSelectionChanged: (s) =>
                                cfg.update(() => cfg.hanafi = s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                  divider(),
                  tile(
                    icon: Icons.event,
                    color: const Color(0xFFF59E0B),
                    title: t('hijri_adjust'),
                    sub: t('hijri_adjust_sub'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        stepBtn(Icons.remove,
                            cfg.hcorr > -3 ? () => cfg.update(() => cfg.hcorr--) : null),
                        SizedBox(
                          width: 34,
                          child: Center(
                            child: Text(
                              cfg.hcorr > 0 ? '+${cfg.hcorr}' : '${cfg.hcorr}',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: c.text),
                            ),
                          ),
                        ),
                        stepBtn(Icons.add,
                            cfg.hcorr < 3 ? () => cfg.update(() => cfg.hcorr++) : null),
                      ],
                    ),
                  ),
                  divider(),
                  switchTile(
                    Icons.schedule,
                    const Color(0xFF3B82F6),
                    t('time24'),
                    t('time24_sub'),
                    cfg.use24,
                    (v) => cfg.update(() => cfg.use24 = v),
                  ),
                ]),

                // ---------- الأذان والإشعارات ----------
                section(t('sec_adhan')),
                card([
                  switchTile(
                    Icons.notifications_active,
                    _green,
                    t('adhan_enable'),
                    t('adhan_enable_sub'),
                    cfg.adhanOn,
                    (v) => cfg.update(() => cfg.adhanOn = v),
                  ),
                  divider(),
                  switchTile(
                    Icons.timer_outlined,
                    const Color(0xFF3B82F6),
                    t('persist_enable'),
                    t('persist_sub'),
                    cfg.persistOn,
                    (v) => cfg.update(() => cfg.persistOn = v),
                  ),
                  divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('alert_prayers'),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.soft)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (int i = 0; i < 5; i++)
                              FilterChip(
                                label: Text(adhanName(i)),
                                selected: cfg.prayerOn[i],
                                selectedColor: _green.withAlpha(60),
                                checkmarkColor: _green,
                                onSelected: cfg.adhanOn
                                    ? (v) => cfg.update(() => cfg.prayerOn[i] = v)
                                    : null,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onTestNow,
                            icon: const Icon(Icons.volume_up, size: 18),
                            label: Text(t('test_now'),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onTestLater,
                            icon: const Icon(Icons.timer, size: 18),
                            label: Text(t('test_1min'),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ),
                  divider(),
                  tile(
                    icon: Icons.battery_saver,
                    color: const Color(0xFFEF4444),
                    title: t('bg_perm'),
                    sub: t('bg_perm_sub'),
                    trailing: chevron(),
                    onTap: onBattery,
                  ),
                ]),

                // ---------- حول ----------
                section(t('sec_about')),
                card([
                  tile(
                    icon: Icons.info_outline,
                    color: const Color(0xFF64748B),
                    title: t('about_app'),
                    sub: '1.0.0',
                    trailing: chevron(),
                    onTap: () => _about(context),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
