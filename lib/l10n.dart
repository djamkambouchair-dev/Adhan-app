import 'package:flutter/material.dart';

const langs = ['ar', 'en', 'fr'];
const langNames = ['العربية', 'English', 'Français'];

String currentLang = 'ar';

int get _li {
  final i = langs.indexOf(currentLang);
  return i < 0 ? 0 : i;
}

bool get isAr => currentLang == 'ar';
TextDirection get appDir => isAr ? TextDirection.rtl : TextDirection.ltr;

String t(String key, [List<String> args = const []]) {
  final v = _tr[key];
  var s = v == null ? key : v[_li];
  for (int i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', args[i]);
  }
  return s;
}

String prayerName(int i) =>
    t(const ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'][i]);

String adhanName(int i) =>
    t(const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'][i]);

String abbr(String s) => isAr ? s : (s.length > 3 ? s.substring(0, 3) : s);

const _wd = [
  ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
  ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
];

const _hm = [
  [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني', 'جمادى الأولى',
    'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ],
  [
    'Muharram', 'Safar', "Rabi' al-awwal", "Rabi' al-thani",
    'Jumada al-awwal', 'Jumada al-thani', 'Rajab', "Sha'ban", 'Ramadan',
    'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah',
  ],
  [
    'Mouharram', 'Safar', "Rabi' al-awwal", "Rabi' ath-thani",
    'Joumada al-oula', 'Joumada ath-thania', 'Rajab', 'Chaabane', 'Ramadan',
    'Chawwal', "Dhou al-qi'da", 'Dhou al-hijja',
  ],
];

const _gm = [
  [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ],
  [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ],
  [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ],
];

List<String> get weekdayNames => _wd[_li];
List<String> get hijriMonths => _hm[_li];
List<String> get gregMonths => _gm[_li];

String arDigits(String s) {
  if (!isAr) return s;
  const west = '0123456789';
  const east = '٠١٢٣٤٥٦٧٨٩';
  return s.split('').map((ch) {
    final i = west.indexOf(ch);
    return i < 0 ? ch : east[i];
  }).join();
}

// [عربي, English, Français]
const Map<String, List<String>> _tr = {
  'app_name': ['الأذان', 'Adhan', 'Adhan'],
  'fajr': ['الفجر', 'Fajr', 'Fajr'],
  'sunrise': ['الشروق', 'Sunrise', 'Lever du soleil'],
  'dhuhr': ['الظهر', 'Dhuhr', 'Dhuhr'],
  'jumua': ['الجمعة', "Jumu'ah", "Joumou'a"],
  'asr': ['العصر', 'Asr', 'Asr'],
  'maghrib': ['المغرب', 'Maghrib', 'Maghrib'],
  'isha': ['العشاء', 'Isha', 'Icha'],
  'am': ['ص', 'AM', 'AM'],
  'pm': ['م', 'PM', 'PM'],
  'adhan_on_label': ['الأذان مفعّل 🔔', 'Adhan enabled 🔔', 'Adhan activé 🔔'],
  'adhan_off_label': ['الأذان متوقف 🔕', 'Adhan disabled 🔕', 'Adhan désactivé 🔕'],
  'bismillah': ['بسم الله', 'Bismillah', 'Bismillah'],
  'choose_location_msg': [
    'اختر موقعك لحساب مواقيت الصلاة',
    'Choose your location to calculate prayer times',
    'Choisissez votre position pour calculer les horaires de prière',
  ],
  'choose_country_city': [
    'اختر الدولة ثم المدينة',
    'Choose country, then city',
    'Choisir le pays puis la ville',
  ],
  'use_my_location': [
    'استخدم موقعي الحالي',
    'Use my current location',
    'Utiliser ma position actuelle',
  ],
  'my_location_gps': [
    'موقعي الحالي (GPS)',
    'My current location (GPS)',
    'Ma position actuelle (GPS)',
  ],
  'current_location': ['الموقع الحالي', 'Current location', 'Position actuelle'],
  'no_location': [
    'لم يتم تحديد الموقع',
    'No location selected',
    'Aucune position choisie',
  ],
  'my_location': ['موقعي الحالي', 'My location', 'Ma position'],
  'adhkar': ['الأذكار', 'Adhkar', 'Adhkar'],
  'reminder': ['التذكير', 'Reminders', 'Rappels'],
  'hijri_calendar': ['التقويم الهجري', 'Hijri calendar', 'Calendrier hégirien'],
  'monthly': ['شهري', 'Monthly', 'Mensuel'],
  'qibla': ['القبلة', 'Qibla', 'Qibla'],
  'locations': ['المواقع', 'Locations', 'Lieux'],
  'adhan_sounds': ['أصوات الأذان', 'Adhan sounds', "Sons de l'adhan"],
  'themes': ['الثيمات', 'Themes', 'Thèmes'],
  'settings': ['الإعدادات', 'Settings', 'Paramètres'],
  'feedback': [
    'إقتراح أو مشكلة',
    'Suggestion or issue',
    'Suggestion ou problème',
  ],
  'soon': [
    '{0}: قريباً بإذن الله',
    '{0}: coming soon',
    '{0} : bientôt disponible',
  ],
  'times_updated': [
    'تم تحديث المواقيت',
    'Prayer times updated',
    'Horaires mis à jour',
  ],
  'gps_off': [
    'فعّل خدمة الموقع (GPS) في هاتفك ثم أعد المحاولة',
    'Turn on location (GPS) on your phone and try again',
    'Activez la localisation (GPS) puis réessayez',
  ],
  'gps_denied': [
    'لم يتم السماح بالوصول للموقع. فعّله من إعدادات التطبيق',
    'Location access was denied. Enable it in the app settings',
    "Accès à la position refusé. Activez-le dans les paramètres",
  ],
  'gps_fail': [
    'تعذر تحديد موقعك. جرّب في مكان مفتوح',
    'Could not get your location. Try somewhere open',
    "Impossible d'obtenir votre position. Essayez en extérieur",
  ],
  'adhan_title': [
    'حان الآن موعد أذان {0}',
    'It is time for the {0} adhan',
    "C'est l'heure de l'adhan de {0}",
  ],
  'by_gps': [
    'حسب موقعك الحالي',
    'Based on your current location',
    'Selon votre position actuelle',
  ],
  'by_place': [
    'حسب توقيت {0}',
    'Based on {0} time',
    "Selon l'heure de {0}",
  ],
  'next_title': [
    'الصلاة القادمة: {0}',
    'Next prayer: {0}',
    'Prochaine prière : {0}',
  ],
  'test_title': ['تجربة الأذان', 'Adhan test', "Test de l'adhan"],
  'test_body': [
    'الله أكبر الله أكبر',
    'Allahu Akbar Allahu Akbar',
    'Allahu Akbar Allahu Akbar',
  ],
  'test_in_1min': [
    'سيصلك الأذان بعد دقيقة. اقفل الشاشة الآن',
    'The adhan will play in one minute. Lock your screen now',
    "L'adhan sonnera dans une minute. Verrouillez l'écran maintenant",
  ],
  'test_failed': ['تعذرت التجربة: {0}', 'Test failed: {0}', 'Échec du test : {0}'],
  'schedule_failed': [
    'تعذرت الجدولة: {0}',
    'Scheduling failed: {0}',
    'Échec de la planification : {0}',
  ],
  'battery_title': [
    'مهم لعمل الأذان',
    'Important for the adhan',
    "Important pour l'adhan",
  ],
  'battery_body': [
    'حتى يعمل الأذان والهاتف مقفل، اسمح للتطبيق بالعمل في الخلفية وبدون تقييد البطارية. في بعض الهواتف (Xiaomi وHuawei وSamsung) فعّل أيضاً "التشغيل التلقائي" من إعدادات التطبيق.',
    'For the adhan to work while the phone is locked, allow the app to run in the background without battery restrictions. On some phones (Xiaomi, Huawei, Samsung) also enable "Autostart" in the app settings.',
    "Pour que l'adhan fonctionne téléphone verrouillé, autorisez l'application à tourner en arrière-plan sans restriction de batterie. Sur certains téléphones (Xiaomi, Huawei, Samsung), activez aussi le « Démarrage automatique ».",
  ],
  'later': ['لاحقاً', 'Later', 'Plus tard'],
  'open_settings': ['فتح الإعدادات', 'Open settings', 'Ouvrir les paramètres'],
  'close': ['إغلاق', 'Close', 'Fermer'],
  'cancel': ['إلغاء', 'Cancel', 'Annuler'],
  'save': ['حفظ', 'Save', 'Enregistrer'],
  // ---- الإعدادات ----
  'sec_appearance': ['المظهر واللغة', 'Appearance & language', 'Apparence et langue'],
  'sec_times': ['مواقيت الصلاة', 'Prayer times', 'Horaires de prière'],
  'sec_adhan': ['الأذان والإشعارات', 'Adhan & notifications', 'Adhan et notifications'],
  'sec_about': ['حول', 'About', 'À propos'],
  'change_location': ['تغيير الموقع', 'Change location', 'Changer de lieu'],
  'theme': ['الثيم', 'Theme', 'Thème'],
  'language': ['اللغة', 'Language', 'Langue'],
  'th0': ['ذهبي', 'Gold', 'Or'],
  'th1': ['أخضر', 'Green', 'Vert'],
  'th2': ['ليلي', 'Night', 'Nuit'],
  'th3': ['أزرق', 'Blue', 'Bleu'],
  'th4': ['وردي', 'Pink', 'Rose'],
  'th5': ['رملي', 'Sand', 'Sable'],
  'th6': ['ليلي أخضر', 'Night green', 'Nuit verte'],
  'calc_method': ['طريقة الحساب', 'Calculation method', 'Méthode de calcul'],
  'juristic': ['المذهب في وقت العصر', 'Asr juristic method', "Méthode de l'Asr"],
  'asr_standard': ['الجمهور', 'Standard', 'Standard'],
  'asr_hanafi': ['الحنفي', 'Hanafi', 'Hanafite'],
  'hijri_adjust': [
    'تصحيح التاريخ الهجري',
    'Hijri date adjustment',
    'Ajustement de la date hégirienne',
  ],
  'hijri_adjust_sub': [
    'زِد أو انقص يوماً ليطابق رؤية بلدك',
    "Add or subtract days to match your country's sighting",
    "Ajoutez ou retirez des jours selon l'observation de votre pays",
  ],
  'time24': ['نظام 24 ساعة', '24-hour format', 'Format 24 heures'],
  'time24_sub': [
    'عرض 17:30 بدل 5:30 م',
    'Show 17:30 instead of 5:30 PM',
    'Afficher 17:30 au lieu de 5:30 PM',
  ],
  'adhan_enable': ['تفعيل الأذان', 'Enable adhan', "Activer l'adhan"],
  'adhan_enable_sub': [
    'تنبيه صوتي عند دخول وقت الصلاة',
    'Sound alert when prayer time begins',
    "Alerte sonore à l'heure de la prière",
  ],
  'persist_enable': [
    'إشعار دائم بالصلاة القادمة',
    'Persistent next-prayer notification',
    'Notification permanente de la prochaine prière',
  ],
  'persist_sub': [
    'عدّاد تنازلي في شريط الإشعارات',
    'Live countdown in the notification bar',
    'Compte à rebours dans la barre de notifications',
  ],
  'alert_prayers': [
    'الصلوات التي ينبّه لها الأذان',
    'Prayers with adhan alert',
    'Prières avec alerte adhan',
  ],
  'test_now': ['تجربة الأذان الآن', 'Test adhan now', "Tester l'adhan"],
  'test_1min': ['بعد دقيقة', 'In 1 minute', 'Dans 1 minute'],
  'bg_perm': [
    'السماح بالعمل في الخلفية',
    'Allow background activity',
    "Autoriser l'activité en arrière-plan",
  ],
  'bg_perm_sub': [
    'مهم حتى يعمل الأذان والهاتف مقفل',
    'Important so the adhan works while the phone is locked',
    "Important pour que l'adhan fonctionne téléphone verrouillé",
  ],
  'about_app': ['حول التطبيق', 'About the app', "À propos de l'application"],
  'about_body': [
    'الأذان\nالإصدار 1.0.0\n\nبيانات المواقع: GeoNames (CC BY 4.0)\nالمناطق الزمنية: Open-Meteo',
    'Adhan\nVersion 1.0.0\n\nLocation data: GeoNames (CC BY 4.0)\nTime zones: Open-Meteo',
    "Adhan\nVersion 1.0.0\n\nDonnées de lieux : GeoNames (CC BY 4.0)\nFuseaux horaires : Open-Meteo",
  ],
  'm_mwl': ['رابطة العالم الإسلامي', 'Muslim World League', 'Ligue islamique mondiale'],
  'm_umm': ['أم القرى (مكة)', 'Umm al-Qura (Makkah)', 'Oumm al-Qura (La Mecque)'],
  'm_egy': ['الهيئة المصرية', 'Egyptian General Authority', 'Autorité égyptienne'],
  'm_kar': ['جامعة كراتشي', 'University of Karachi', 'Université de Karachi'],
  'm_isna': ['أمريكا الشمالية (ISNA)', 'North America (ISNA)', 'Amérique du Nord (ISNA)'],
  'm_dxb': ['الإمارات', 'United Arab Emirates', 'Émirats arabes unis'],
  'm_qat': ['قطر', 'Qatar', 'Qatar'],
  'm_kwt': ['الكويت', 'Kuwait', 'Koweït'],
  'm_sgp': ['سنغافورة', 'Singapore', 'Singapour'],
  // ---- الجدول والتقويم ----
  'monthly_title': ['المواقيت - {0}', 'Prayer times - {0}', 'Horaires - {0}'],
  'occ_year': ['مناسبات عام {0} هـ', 'Occasions of {0} AH', 'Occasions de {0} H'],
  'oc0': ['رأس السنة الهجرية', 'Islamic New Year', 'Nouvel an hégirien'],
  'oc1': ['يوم عاشوراء', 'Day of Ashura', 'Jour de Achoura'],
  'oc2': ['المولد النبوي الشريف', "Mawlid (Prophet's birthday)", 'Mawlid (naissance du Prophète)'],
  'oc3': ['ذكرى الإسراء والمعراج', "Isra and Mi'raj", "Isra et Mi'raj"],
  'oc4': ['ليلة النصف من شعبان', "Mid-Sha'ban night", 'Nuit de la mi-Chaabane'],
  'oc5': ['أول رمضان', 'First of Ramadan', 'Premier Ramadan'],
  'oc6': ['ليلة القدر', 'Laylat al-Qadr', 'Nuit du Destin'],
  'oc7': ['عيد الفطر', 'Eid al-Fitr', "Aïd al-Fitr"],
  'oc8': ['يوم عرفة', 'Day of Arafah', 'Jour de Arafat'],
  'oc9': ['عيد الأضحى', 'Eid al-Adha', "Aïd al-Adha"],
  // ---- القبلة ----
  'qibla_title': ['اتجاه القبلة - {0}', 'Qibla direction - {0}', 'Direction de la Qibla - {0}'],
  'q_aligned': ['أنت في اتجاه القبلة ✓', 'You are facing the Qibla ✓', 'Vous faites face à la Qibla ✓'],
  'q_no_sensor': [
    'مستشعر البوصلة غير متوفر في هذا الهاتف',
    'No compass sensor on this phone',
    'Pas de capteur de boussole sur ce téléphone',
  ],
  'q_reading': ['جارٍ قراءة البوصلة...', 'Reading the compass...', 'Lecture de la boussole...'],
  'q_rotate': [
    'أدر الهاتف حتى يشير السهم الأخضر للأعلى',
    'Rotate the phone until the green arrow points up',
    "Tournez le téléphone jusqu'à ce que la flèche verte pointe vers le haut",
  ],
  'q_bearing': [
    'اتجاه القبلة: {0}° من الشمال',
    'Qibla bearing: {0}° from north',
    'Direction de la Qibla : {0}° depuis le nord',
  ],
  'q_distance': [
    'المسافة إلى الكعبة: {0} كم',
    'Distance to the Kaaba: {0} km',
    "Distance jusqu'à la Kaaba : {0} km",
  ],
  'q_heading': [
    'اتجاه هاتفك الآن: {0}°',
    'Phone heading now: {0}°',
    'Cap du téléphone : {0}°',
  ],
  'q_note': [
    'ضع الهاتف أفقياً بعيداً عن المعادن والمغناطيس، وحرّكه على شكل رقم 8 لمعايرة البوصلة.',
    'Hold the phone flat, away from metal and magnets, and move it in a figure 8 to calibrate.',
    "Tenez le téléphone à plat, loin des métaux et aimants, et faites un 8 pour calibrer.",
  ],
  'q_help_nosensor': [
    'هاتفك بلا مستشعر بوصلة، فتظهر زاوية القبلة فقط: {0}° من الشمال مع عقارب الساعة. حدّد الشمال بخرائط جوجل أو ببوصلة أخرى.',
    'Your phone has no compass sensor, so only the angle is shown: {0}° clockwise from north. Find north with Google Maps or another compass.',
    "Votre téléphone n'a pas de boussole : seul l'angle est affiché, {0}° dans le sens horaire depuis le nord. Trouvez le nord avec Google Maps ou une autre boussole.",
  ],
  // ---- اختيار الموقع ----
  'g_arab': ['الدول العربية', 'Arab countries', 'Pays arabes'],
  'g_islamic': ['الدول الإسلامية', 'Islamic countries', 'Pays musulmans'],
  'g_europe': ['أوروبا', 'Europe', 'Europe'],
  'g_other': ['دول أخرى', 'Other countries', 'Autres pays'],
  'search_all_world': [
    'ابحث عن مدينة في كل الدول',
    'Search a city in all countries',
    'Rechercher une ville dans tous les pays',
  ],
  'pick_country_hint': [
    'اختر الدولة أو ابحث عنها',
    'Choose or search a country',
    'Choisir ou rechercher un pays',
  ],
  'geo_credit': [
    'بيانات المواقع: GeoNames (CC BY 4.0)',
    'Location data: GeoNames (CC BY 4.0)',
    'Données de lieux : GeoNames (CC BY 4.0)',
  ],
  'search_in': ['ابحث في {0}', 'Search in {0}', 'Rechercher en {0}'],
  'online_search': ['بحث عبر الإنترنت', 'Online search', 'Recherche en ligne'],
  'manual_coords': ['إحداثيات يدوية', 'Manual coordinates', 'Coordonnées manuelles'],
  'tap_back_list': [
    'اضغط للرجوع إلى القائمة',
    'Tap to go back to the list',
    'Appuyez pour revenir à la liste',
  ],
  'other': ['أخرى', 'Other', 'Autres'],
  'manual_title': ['إدخال موقع يدوياً', 'Enter a location manually', 'Saisir un lieu manuellement'],
  'place_name_label': ['اسم المدينة أو البلدية', 'City or town name', 'Nom de la ville ou commune'],
  'lat_label': ['خط العرض (مثال 36.45)', 'Latitude (e.g. 36.45)', 'Latitude (ex. 36.45)'],
  'lng_label': ['خط الطول (مثال 6.26)', 'Longitude (e.g. 6.26)', 'Longitude (ex. 6.26)'],
  'coords_help': [
    'تجد الإحداثيات في خرائط جوجل: اضغط مطولاً على مكانك فتظهر الأرقام.',
    'Find the coordinates in Google Maps: long-press your place and the numbers appear.',
    "Trouvez les coordonnées dans Google Maps : appuyez longuement sur votre lieu.",
  ],
  'check_inputs': [
    'تأكد من الاسم ومن صحة الأرقام',
    'Check the name and the numbers',
    'Vérifiez le nom et les nombres',
  ],
  'type_city_hint': [
    'اكتب اسم المدينة أو البلدية',
    'Type the city or town name',
    'Saisissez le nom de la ville ou commune',
  ],
  'city_search_help': [
    'ابحث في {0}: اكتب حرفين على الأقل. وإن لم يظهر الاسم بالعربية فجرّب بالحروف اللاتينية.',
    'Search in {0}: type at least two letters. If the name is not found, try another spelling.',
    "Recherche en {0} : saisissez au moins deux lettres. Si le nom est introuvable, essayez une autre orthographe.",
  ],
  'no_results': [
    'لا توجد نتائج. جرّب كتابة الاسم بشكل آخر، أو أدخل الإحداثيات يدوياً.',
    'No results. Try another spelling, or enter the coordinates manually.',
    "Aucun résultat. Essayez une autre orthographe, ou saisissez les coordonnées manuellement.",
  ],
  'not_found_manual': [
    'لم تجد مدينتك؟ أدخل إحداثياتها يدوياً',
    "Can't find your city? Enter its coordinates manually",
    "Ville introuvable ? Saisissez ses coordonnées",
  ],
  'search_failed': [
    'تعذر البحث. تأكد من اتصالك بالإنترنت',
    'Search failed. Check your internet connection',
    'Échec de la recherche. Vérifiez votre connexion',
  ],
  'global_hint': [
    'اكتب اسم المدينة في أي دولة',
    'Type a city name in any country',
    "Saisissez le nom d'une ville dans n'importe quel pays",
  ],
};
