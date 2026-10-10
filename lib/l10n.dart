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

const _wd = [
  ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
  [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ],
  ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
];

const _hm = [
  [
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
  ],
  [
    'Muharram',
    'Safar',
    "Rabi' al-awwal",
    "Rabi' al-thani",
    'Jumada al-awwal',
    'Jumada al-thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ],
  [
    'Mouharram',
    'Safar',
    "Rabi' al-awwal",
    "Rabi' ath-thani",
    'Joumada al-oula',
    'Joumada ath-thania',
    'Rajab',
    'Chaabane',
    'Ramadan',
    'Chawwal',
    "Dhou al-qi'da",
    'Dhou al-hijja',
  ],
];

List<String> get weekdayNames => _wd[_li];
List<String> get hijriMonths => _hm[_li];

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
  'fajr_tomorrow': ['الفجر (غداً)', 'Fajr (tomorrow)', 'Fajr (demain)'],
  'am': ['ص', 'AM', 'AM'],
  'pm': ['م', 'PM', 'PM'],
  'adhan_on_label': ['الأذان مفعّل 🔔', 'Adhan enabled 🔔', 'Adhan activé 🔔'],
  'adhan_off_label': [
    'الأذان متوقف 🔕',
    'Adhan disabled 🔕',
    'Adhan désactivé 🔕'
  ],
  'bismillah': ['بسم الله', 'Bismillah', 'Bismillah'],
  'choose_location_msg': [
    'اختر موقعك لحساب مواقيت الصلاة',
    'Choose your location to calculate prayer times',
    'Choisissez votre position pour calculer les horaires de prière'
  ],
  'choose_country_city': [
    'اختر الدولة ثم المدينة',
    'Choose country, then city',
    'Choisir le pays puis la ville'
  ],
  'use_my_location': [
    'استخدم موقعي الحالي',
    'Use my current location',
    'Utiliser ma position actuelle'
  ],
  'my_location_gps': [
    'موقعي الحالي (GPS)',
    'My current location (GPS)',
    'Ma position actuelle (GPS)'
  ],
  'current_location': ['الموقع الحالي', 'Current location', 'Position actuelle'],
  'no_location': [
    'لم يتم تحديد الموقع',
    'No location selected',
    'Aucune position choisie'
  ],
  'my_location': ['موقعي الحالي', 'My location', 'Ma position'],
  'adhkar': ['الأذكار', 'Adhkar', 'Adhkar'],
  'reminder': ['التذكير', 'Reminders', 'Rappels'],
  'hijri_calendar': [
    'التقويم الهجري',
    'Hijri calendar',
    'Calendrier hégirien'
  ],
  'monthly': ['شهري', 'Monthly', 'Mensuel'],
  'qibla': ['القبلة', 'Qibla', 'Qibla'],
  'locations': ['المواقع', 'Locations', 'Lieux'],
  'adhan_sounds': ['أصوات الأذان', 'Adhan sounds', "Sons de l'adhan"],
  'themes': ['الثيمات', 'Themes', 'Thèmes'],
  'settings': ['الإعدادات', 'Settings', 'Paramètres'],
  'feedback': [
    'إقتراح أو مشكلة',
    'Suggestion or issue',
    'Suggestion ou problème'
  ],
  'soon': [
    '{0}: قريباً بإذن الله',
    '{0}: coming soon',
    '{0} : bientôt disponible'
  ],
  'times_updated': [
    'تم تحديث المواقيت',
    'Prayer times updated',
    'Horaires mis à jour'
  ],
  'gps_off': [
    'فعّل خدمة الموقع (GPS) في هاتفك ثم أعد المحاولة',
    'Turn on location (GPS) on your phone and try again',
    'Activez la localisation (GPS) puis réessayez'
  ],
  'gps_denied': [
    'لم يتم السماح بالوصول للموقع. فعّله من إعدادات التطبيق',
    'Location access was denied. Enable it in the app settings',
    "Accès à la position refusé. Activez-le dans les paramètres"
  ],
  'gps_fail': [
    'تعذر تحديد موقعك. جرّب في مكان مفتوح',
    'Could not get your location. Try somewhere open',
    "Impossible d'obtenir votre position. Essayez en extérieur"
  ],
  'adhan_title': [
    'حان الآن موعد أذان {0}',
    'It is time for the {0} adhan',
    "C'est l'heure de l'adhan de {0}"
  ],
  'by_gps': [
    'حسب موقعك الحالي',
    'Based on your current location',
    'Selon votre position actuelle'
  ],
  'by_place': [
    'حسب توقيت {0}',
    'Based on {0} time',
    "Selon l'heure de {0}"
  ],
  'next_title': [
    'الصلاة القادمة: {0}',
    'Next prayer: {0}',
    'Prochaine prière : {0}'
  ],
  'test_title': ['تجربة الأذان', 'Adhan test', "Test de l'adhan"],
  'test_body': [
    'الله أكبر الله أكبر',
    'Allahu Akbar Allahu Akbar',
    'Allahu Akbar Allahu Akbar'
  ],
  'test_in_1min': [
    'سيصلك الأذان بعد دقيقة. اقفل الشاشة الآن',
    'The adhan will play in one minute. Lock your screen now',
    "L'adhan sonnera dans une minute. Verrouillez l'écran maintenant"
  ],
  'test_failed': [
    'تعذرت التجربة: {0}',
    'Test failed: {0}',
    'Échec du test : {0}'
  ],
  'schedule_failed': [
    'تعذرت الجدولة: {0}',
    'Scheduling failed: {0}',
    'Échec de la planification : {0}'
  ],
  'battery_title': [
    'مهم لعمل الأذان',
    'Important for the adhan',
    "Important pour l'adhan"
  ],
  'battery_body': [
    'حتى يعمل الأذان والهاتف مقفل، اسمح للتطبيق بالعمل في الخلفية وبدون تقييد البطارية. في بعض الهواتف (Xiaomi وHuawei وSamsung) فعّل أيضاً "التشغيل التلقائي" من إعدادات التطبيق.',
    'For the adhan to work while the phone is locked, allow the app to run in the background without battery restrictions. On some phones (Xiaomi, Huawei, Samsung) also enable "Autostart" in the app settings.',
    "Pour que l'adhan fonctionne téléphone verrouillé, autorisez l'application à tourner en arrière-plan sans restriction de batterie. Sur certains téléphones (Xiaomi, Huawei, Samsung), activez aussi le « Démarrage automatique »."
  ],
  'later': ['لاحقاً', 'Later', 'Plus tard'],
  'open_settings': ['فتح الإعدادات', 'Open settings', 'Ouvrir les paramètres'],
  'close': ['إغلاق', 'Close', 'Fermer'],
  // ---- الإعدادات ----
  'sec_appearance': [
    'المظهر واللغة',
    'Appearance & language',
    'Apparence et langue'
  ],
  'sec_times': ['مواقيت الصلاة', 'Prayer times', 'Horaires de prière'],
  'sec_adhan': [
    'الأذان والإشعارات',
    'Adhan & notifications',
    'Adhan et notifications'
  ],
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
  'juristic': [
    'المذهب في وقت العصر',
    'Asr juristic method',
    "Méthode de l'Asr"
  ],
  'asr_standard': ['الجمهور', 'Standard', 'Standard'],
  'asr_hanafi': ['الحنفي', 'Hanafi', 'Hanafite'],
  'hijri_adjust': [
    'تصحيح التاريخ الهجري',
    'Hijri date adjustment',
    'Ajustement de la date hégirienne'
  ],
  'hijri_adjust_sub': [
    'زِد أو انقص يوماً ليطابق رؤية بلدك',
    "Add or subtract days to match your country's sighting",
    "Ajoutez ou retirez des jours selon l'observation de votre pays"
  ],
  'time24': ['نظام 24 ساعة', '24-hour format', 'Format 24 heures'],
  'time24_sub': [
    'عرض 17:30 بدل 5:30 م',
    'Show 17:30 instead of 5:30 PM',
    'Afficher 17:30 au lieu de 5:30 PM'
  ],
  'adhan_enable': ['تفعيل الأذان', 'Enable adhan', "Activer l'adhan"],
  'adhan_enable_sub': [
    'تنبيه صوتي عند دخول وقت الصلاة',
    'Sound alert when prayer time begins',
    "Alerte sonore à l'heure de la prière"
  ],
  'persist_enable': [
    'إشعار دائم بالصلاة القادمة',
    'Persistent next-prayer notification',
    'Notification permanente de la prochaine prière'
  ],
  'persist_sub': [
    'عدّاد تنازلي في شريط الإشعارات',
    'Live countdown in the notification bar',
    'Compte à rebours dans la barre de notifications'
  ],
  'alert_prayers': [
    'الصلوات التي ينبّه لها الأذان',
    'Prayers with adhan alert',
    'Prières avec alerte adhan'
  ],
  'test_now': ['تجربة الأذان الآن', 'Test adhan now', "Tester l'adhan"],
  'test_1min': ['بعد دقيقة', 'In 1 minute', 'Dans 1 minute'],
  'bg_perm': [
    'السماح بالعمل في الخلفية',
    'Allow background activity',
    "Autoriser l'activité en arrière-plan"
  ],
  'bg_perm_sub': [
    'مهم حتى يعمل الأذان والهاتف مقفل',
    'Important so the adhan works while the phone is locked',
    "Important pour que l'adhan fonctionne téléphone verrouillé"
  ],
  'about_app': [
    'حول التطبيق',
    'About the app',
    "À propos de l'application"
  ],
  'about_body': [
    'الأذان\nالإصدار 1.0.0\n\nبيانات المواقع: GeoNames (CC BY 4.0)\nالمناطق الزمنية: Open-Meteo',
    'Adhan\nVersion 1.0.0\n\nLocation data: GeoNames (CC BY 4.0)\nTime zones: Open-Meteo',
    "Adhan\nVersion 1.0.0\n\nDonnées de lieux : GeoNames (CC BY 4.0)\nFuseaux horaires : Open-Meteo"
  ],
  'm_mwl': [
    'رابطة العالم الإسلامي',
    'Muslim World League',
    'Ligue islamique mondiale'
  ],
  'm_umm': [
    'أم القرى (مكة)',
    'Umm al-Qura (Makkah)',
    'Oumm al-Qura (La Mecque)'
  ],
  'm_egy': [
    'الهيئة المصرية',
    'Egyptian General Authority',
    'Autorité égyptienne'
  ],
  'm_kar': ['جامعة كراتشي', 'University of Karachi', 'Université de Karachi'],
  'm_isna': [
    'أمريكا الشمالية (ISNA)',
    'North America (ISNA)',
    'Amérique du Nord (ISNA)'
  ],
  'm_dxb': ['الإمارات', 'United Arab Emirates', 'Émirats arabes unis'],
  'm_qat': ['قطر', 'Qatar', 'Qatar'],
  'm_kwt': ['الكويت', 'Kuwait', 'Koweït'],
  'm_sgp': ['سنغافورة', 'Singapore', 'Singapour'],
};
