import 'dart:typed_data';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kUygulamaAdi = 'PDF Okuyucu';

void main() {
  runApp(const DevSecOpsReader());
}

class DevSecOpsReader extends StatefulWidget {
  const DevSecOpsReader({super.key});

  @override
  State<DevSecOpsReader> createState() => _DevSecOpsReaderState();
}

class _DevSecOpsReaderState extends State<DevSecOpsReader> {
  ThemeMode _themeMode = ThemeMode.light;

  void _temaDegistir() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueGrey,
      ),
      themeMode: _themeMode,
      home: AnaEkran(
        karanlikMod: _themeMode == ThemeMode.dark,
        onTemaDegistir: _temaDegistir,
      ),
    );
  }
}

class PdfReader extends DevSecOpsReader {
  const PdfReader({super.key});
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({
    super.key,
    required this.karanlikMod,
    required this.onTemaDegistir,
  });

  final bool karanlikMod;
  final VoidCallback onTemaDegistir;

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  Duration _pasiflikSuresi = const Duration(minutes: 3);
  Duration _pasiflikTekrarSuresi = const Duration(seconds: 45);
  Duration _otomatikKaydirmaAraligi = const Duration(seconds: 12);
  Duration _ekranAcikTutmaSuresi = const Duration(minutes: 15);

  final PdfViewerController _pdfController = PdfViewerController();
  final TextEditingController _aramaController = TextEditingController();

  Timer? _pasiflikZamanlayicisi;
  Timer? _okumaSuresiZamanlayicisi;
  Timer? _otomatikKaydirmaZamanlayicisi;
  Timer? _flasKapatmaZamanlayicisi;
  Timer? _secimBeklemeZamanlayicisi;
  Timer? _idleEmojiZamanlayicisi;
  Timer? _ekranAcikTutmaZamanlayicisi;

  Uint8List? _pdfBytes;
  String? _aktifDosyaAdi;
  String? _bekleyenSecimMetni;
  String _dilKodu = 'tr';

  bool _cekmeceAcikMi = false;
  bool _okumaModu = false;
  bool _otomatikKaydirmaAktif = false;
  bool _flasAktif = false;
  bool _idleEmojiAktif = false;

  int _aktifSayfa = 1;
  int _toplamSayfa = 0;
  int _okumaSaniyesi = 0;
  int _gumus = 0;
  int _altin = 0;
  int _idleEmojiSaniyesi = 0;

  DateTime _sonEtkilesimZamani = DateTime.now();
  DateTime? _sonSayfaGecisZamani;
  StreamSubscription<AccelerometerEvent>? _hareketAboneligi;
  String _idleEmoji = '🙂';
  bool _ekranAcikTutmaAktif = false;
  int? _kayitliSayfaAdayi;

  static const String _sonSayfaAnahtariOnEki = 'son_sayfa_';

  static const Map<int, String> _idleEmojiCizelgesi = <int, String>{
    0: '🤨',
    2: '🧐',
    4: '🥸',
    6: '🤩',
    8: '🫣',
    10: '🤗',
    12: '🫣',
    14: '🤗',
    16: '🫵',
    18: '🥱',
    20: '😴',
    22: '🤤',
    24: '😪',
    26: '😮‍💨',
    28: '🙋',
    30: '😛',
    32: '😝',
    34: '😜',
    36: '🤪',
    38: '😏',
    40: '😵‍💫',
    42: '🥴',
    44: '👻',
    46: '💩',
    48: '🤡',
    50: '🫵',
    52: '👎',
    54: '😈',
    56: '👾',
    58: '👾👾👾👾',
    60: '🤨',
    62: '😡',
    64: '😈',
    66: '🔥📚',
    70: '📚🔥',
    72: '🔥📚',
    74: '✂️📚',
    76: '🗑️🗑️',
    78: '🧹🧹',
    80: '📄',
    81: '😴',
  };

  PdfTextSearchResult? _aramaSonucu;
  final Set<int> _yerImleri = <int>{};
  final List<_NotKaydi> _notlar = <_NotKaydi>[];
  final List<_IsaretKaydi> _isaretler = <_IsaretKaydi>[];
  final List<_GecmisDosya> _sonDosyalar = <_GecmisDosya>[];
  final Set<String> _kelimeDefteri = <String>{};

  @override
  void initState() {
    super.initState();
    _ekranAcikTutmaSayaciniSifirla();
    _okumaSuresiTakibiniBaslat();
    _pasiflikSayaciniSifirla();
    _hareketIzlemeBaslat();
  }

  Future<void> _ekranAcikTutmayiEtkinlestir() async {
    if (_ekranAcikTutmaAktif) {
      return;
    }
    await WakelockPlus.enable();
    _ekranAcikTutmaAktif = true;
  }

  Future<void> _ekranAcikTutmayiKapat() async {
    if (!_ekranAcikTutmaAktif) {
      return;
    }
    await WakelockPlus.disable();
    _ekranAcikTutmaAktif = false;
  }

  void _ekranAcikTutmaSayaciniSifirla() {
    _ekranAcikTutmaZamanlayicisi?.cancel();
    unawaited(_ekranAcikTutmayiEtkinlestir());
    _ekranAcikTutmaZamanlayicisi = Timer(_ekranAcikTutmaSuresi, () {
      unawaited(_ekranAcikTutmayiKapat());
    });
  }

  void _hareketIzlemeBaslat() {
    _hareketAboneligi?.cancel();
    _hareketAboneligi = accelerometerEvents.listen((AccelerometerEvent event) {
      if (!_idleEmojiAktif) {
        return;
      }

      final double hareketPuani = event.x.abs() + event.y.abs() + event.z.abs();
      if (hareketPuani > 14) {
        _idleEmojiSisteminiDurdur();
      }
    });
  }

  void _idleEmojiSisteminiBaslat() {
    if (_idleEmojiAktif) {
      return;
    }

    _idleEmojiZamanlayicisi?.cancel();
    setState(() {
      _idleEmojiAktif = true;
      _idleEmojiSaniyesi = 0;
      _idleEmoji = _idleEmojiCizelgesi[0] ?? '🙂';
    });

    _idleEmojiZamanlayicisi = Timer.periodic(const Duration(seconds: 1), (
      Timer timer,
    ) {
      if (!mounted || !_idleEmojiAktif) {
        timer.cancel();
        return;
      }

      final int yeniSure = _idleEmojiSaniyesi + 1;
      final int esik = _idleEmojiCizelgesi.keys
          .where((int deger) => deger <= yeniSure)
          .fold<int>(
            0,
            (int onceki, int deger) => deger > onceki ? deger : onceki,
          );
      final String yeniEmoji = _idleEmojiCizelgesi[esik] ?? _idleEmoji;
      final bool emojiDegisti = yeniEmoji != _idleEmoji;

      setState(() {
        _idleEmojiSaniyesi = yeniSure;
        _idleEmoji = yeniEmoji;
      });

      if (emojiDegisti) {
        unawaited(_idleEmojiGecisTitresimi(yeniSure));
      }

      if (yeniSure >= 81) {
        timer.cancel();
      }
    });
  }

  String _sonSayfaAnahtari(String dosyaAdi) {
    return '$_sonSayfaAnahtariOnEki$dosyaAdi';
  }

  Future<void> _kayitliSayfayiHazirla(String dosyaAdi) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _kayitliSayfaAdayi = prefs.getInt(_sonSayfaAnahtari(dosyaAdi));
  }

  Future<void> _sonSayfayiKaydet() async {
    final String? dosyaAdi = _aktifDosyaAdi;
    if (dosyaAdi == null || _toplamSayfa <= 0) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sonSayfaAnahtari(dosyaAdi), _aktifSayfa);
  }

  Future<void> _idleEmojiGecisTitresimi(int saniye) async {
    try {
      await HapticFeedback.heavyImpact();
      if (saniye >= 50) {
        await HapticFeedback.vibrate();
      }
    } catch (_) {}

    try {
      final bool? cihazDestekliyor = await Vibration.hasVibrator();
      if (cihazDestekliyor != true) {
        return;
      }
      final bool? genlikDestegi = await Vibration.hasAmplitudeControl();
      if (genlikDestegi == true) {
        await Vibration.vibrate(
          pattern: saniye >= 50 ? <int>[0, 120, 60, 140] : <int>[0, 100],
          intensities: saniye >= 50 ? <int>[0, 255, 0, 255] : <int>[0, 220],
        );
      } else {
        await Vibration.vibrate(
          pattern: saniye >= 50 ? <int>[0, 120, 60, 140] : <int>[0, 100],
        );
      }
    } catch (_) {}
  }

  void _idleEmojiSisteminiDurdur() {
    _idleEmojiZamanlayicisi?.cancel();
    if (!_idleEmojiAktif) {
      return;
    }
    setState(() {
      _idleEmojiAktif = false;
      _idleEmojiSaniyesi = 0;
      _idleEmoji = _idleEmojiCizelgesi[0] ?? '🙂';
    });
  }

  void _pasifEfektleriTemizle() {}

  void _okumaOturumunuSifirla() {
    _okumaSaniyesi = 0;
    _gumus = 0;
    _altin = 0;
    _toplamSayfa = 0;
    _aktifSayfa = 1;
    _sonSayfaGecisZamani = null;
    _flasAktif = false;
    _pasifEfektleriTemizle();
  }

  String _t(String key) {
    const Map<String, Map<String, String>> metinler =
        <String, Map<String, String>>{
          'tr': <String, String>{
            'title': 'PDF Okuyucu',
            'selectPdf': 'Bilgisayardan / Telefondan PDF Seç',
            'settings': 'Ayarlar',
            'language': 'Dil',
            'feedback': 'Geri Bildirim / Destek',
            'feedbackSoon': 'Bu bölüm yakında doldurulacak.',
          },
          'en': <String, String>{
            'title': 'PDF Reader',
            'selectPdf': 'Select PDF from Computer / Phone',
            'settings': 'Settings',
            'language': 'Language',
            'feedback': 'Feedback / Support',
            'feedbackSoon': 'This section will be added soon.',
          },
          'es': <String, String>{
            'title': 'Lector PDF',
            'selectPdf': 'Seleccionar PDF desde PC / Teléfono',
            'settings': 'Configuración',
            'language': 'Idioma',
            'feedback': 'Comentarios / Soporte',
            'feedbackSoon': 'Esta sección se completará pronto.',
          },
        };

    return metinler[_dilKodu]?[key] ?? metinler['tr']![key] ?? key;
  }

  Future<void> _uygulamaIciWebAc(String urlString) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UygulamaIciWebSayfasi(
          url: urlString,
          baslik: Uri.parse(urlString).host,
        ),
      ),
    );
  }

  void _ayarlarPaneliAc() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _t('settings'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _dilKodu,
                      decoration: InputDecoration(labelText: _t('language')),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                      ],
                      onChanged: (String? value) {
                        if (value == null) return;
                        setState(() {
                          _dilKodu = value;
                        });
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pasiflik başlangıcı (dk)'),
                      subtitle: Slider(
                        value: _pasiflikSuresi.inMinutes.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '${_pasiflikSuresi.inMinutes} dk',
                        onChanged: (double value) {
                          setState(() {
                            _pasiflikSuresi = Duration(minutes: value.round());
                          });
                          _pasiflikSayaciniSifirla();
                          setModalState(() {});
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Otomatik kaydırma (sn)'),
                      subtitle: Slider(
                        value: _otomatikKaydirmaAraligi.inSeconds.toDouble(),
                        min: 5,
                        max: 25,
                        divisions: 20,
                        label: '${_otomatikKaydirmaAraligi.inSeconds} sn',
                        onChanged: (double value) {
                          setState(() {
                            _otomatikKaydirmaAraligi = Duration(
                              seconds: value.round(),
                            );
                          });
                          if (_otomatikKaydirmaAktif) {
                            _otomatikKaydirmaBaslat();
                          }
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_t('feedbackSoon'))),
                        );
                      },
                      icon: const Icon(Icons.support_agent),
                      label: Text(_t('feedback')),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _kullaniciEtkilesimiAlgila() {
    _sonEtkilesimZamani = DateTime.now();
    _ekranAcikTutmaSayaciniSifirla();
    _idleEmojiSisteminiDurdur();

    _pasiflikSayaciniSifirla();
  }

  void _pasiflikSayaciniSifirla() {
    _idleEmojiSisteminiDurdur();
    if (_pdfBytes == null) {
      _pasiflikZamanlayicisi?.cancel();
      return;
    }
    _pasiflikZamanlayicisi?.cancel();
    _pasiflikZamanlayicisi = Timer(_pasiflikSuresi, _pasiflikUyarisiVer);
  }

  Future<void> _pasiflikUyarisiVer() async {
    if (!mounted || _pdfBytes == null) {
      return;
    }

    await _pasiflikTitresiminiCal();
    _idleEmojiSisteminiBaslat();

    _pasiflikZamanlayicisi?.cancel();
    _pasiflikZamanlayicisi = Timer(_pasiflikTekrarSuresi, _pasiflikUyarisiVer);
  }

  Future<void> _pasiflikTitresiminiCal() async {
    try {
      await HapticFeedback.heavyImpact();
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    try {
      final bool? cihazDestekliyor = await Vibration.hasVibrator();
      if (cihazDestekliyor != true) {
        return;
      }

      final bool? genlikDestegi = await Vibration.hasAmplitudeControl();
      if (genlikDestegi == true) {
        await Vibration.vibrate(
          pattern: <int>[0, 110, 90, 140],
          intensities: <int>[0, 200, 0, 255],
        );
      } else {
        await Vibration.vibrate(pattern: <int>[0, 110, 90, 140]);
      }
    } catch (_) {}
  }

  void _okumaSuresiTakibiniBaslat() {
    _okumaSuresiZamanlayicisi?.cancel();
    _okumaSuresiZamanlayicisi = Timer.periodic(const Duration(seconds: 1), (
      Timer timer,
    ) {
      if (!mounted || _pdfBytes == null) {
        return;
      }

      final bool aktifOkuma =
          _otomatikKaydirmaAktif ||
          DateTime.now().difference(_sonEtkilesimZamani) < _pasiflikSuresi;

      if (!aktifOkuma) {
        return;
      }

      setState(() {
        _okumaSaniyesi++;
        _gumus++;
        if (_okumaSaniyesi % 60 == 0) {
          _altin++;
        }
      });
    });
  }

  void _hizliKaydirmaFlasiKontrolEt(PdfPageChangedDetails details) {
    final DateTime simdi = DateTime.now();

    if (_otomatikKaydirmaAktif) {
      _sonSayfaGecisZamani = simdi;
      return;
    }

    if (_sonSayfaGecisZamani != null) {
      final int ms = simdi.difference(_sonSayfaGecisZamani!).inMilliseconds;
      final int fark = (details.newPageNumber - details.oldPageNumber).abs();
      if (fark >= 1 && ms < 450) {
        _flasiTetikle();
      }
    }

    _sonSayfaGecisZamani = simdi;
  }

  void _flasiTetikle() {
    _flasKapatmaZamanlayicisi?.cancel();
    setState(() {
      _flasAktif = true;
    });
    _flasKapatmaZamanlayicisi = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _flasAktif = false;
      });
    });
  }

  void _otomatikKaydirmaDegistir() {
    setState(() {
      _otomatikKaydirmaAktif = !_otomatikKaydirmaAktif;

      if (_otomatikKaydirmaAktif) {
        _pasifEfektleriTemizle();
      }
    });

    if (_otomatikKaydirmaAktif) {
      _otomatikKaydirmaBaslat();
      return;
    }

    _otomatikKaydirmaZamanlayicisi?.cancel();
    _pasiflikSayaciniSifirla();
  }

  void _otomatikKaydirmaBaslat() {
    _otomatikKaydirmaZamanlayicisi?.cancel();
    _otomatikKaydirmaZamanlayicisi = Timer.periodic(_otomatikKaydirmaAraligi, (
      Timer timer,
    ) {
      if (!mounted || !_otomatikKaydirmaAktif || _pdfBytes == null) {
        return;
      }

      if (_toplamSayfa <= 0) {
        return;
      }

      if (_aktifSayfa >= _toplamSayfa) {
        setState(() {
          _otomatikKaydirmaAktif = false;
        });
        timer.cancel();
        _pasiflikSayaciniSifirla();
        return;
      }

      _pdfController.jumpToPage(_aktifSayfa + 1);
    });
  }

  String _sureFormatla(int saniye) {
    final int dakika = saniye ~/ 60;
    final int kalan = saniye % 60;
    return '${dakika.toString().padLeft(2, '0')}:${kalan.toString().padLeft(2, '0')}';
  }

  double _okumaIlerlemeOrani() {
    if (_toplamSayfa <= 0) {
      return 0;
    }
    if (_toplamSayfa == 1) {
      return 1;
    }
    return ((_aktifSayfa - 1) / (_toplamSayfa - 1)).clamp(0, 1);
  }

  String _solucanKitapYolu() {
    const int adim = 20;
    final int konum = (_okumaIlerlemeOrani() * adim).round().clamp(0, adim);
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i <= adim; i++) {
      if (i == konum) {
        sb.write('🐛');
      } else if (i == adim) {
        sb.write('📚');
      } else if (i < konum) {
        sb.write('▫️');
      } else {
        sb.write('📄');
      }
    }
    return sb.toString();
  }

  @override
  void dispose() {
    unawaited(_sonSayfayiKaydet());
    _ekranAcikTutmaZamanlayicisi?.cancel();
    unawaited(_ekranAcikTutmayiKapat());
    _pasiflikZamanlayicisi?.cancel();
    _okumaSuresiZamanlayicisi?.cancel();
    _otomatikKaydirmaZamanlayicisi?.cancel();
    _flasKapatmaZamanlayicisi?.cancel();
    _secimBeklemeZamanlayicisi?.cancel();
    _idleEmojiZamanlayicisi?.cancel();
    _hareketAboneligi?.cancel();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _dosyaSec() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      final PlatformFile secilen = result.files.first;
      setState(() {
        _okumaOturumunuSifirla();
        _pdfBytes = secilen.bytes;
        _aktifDosyaAdi = secilen.name;
        _aramaSonucu?.clear();
      });
      await _kayitliSayfayiHazirla(secilen.name);
      _kullaniciEtkilesimiAlgila();
      _gecmiseEkle(secilen.name);
    }
  }

  Future<void> _linkeGit(
    String urlString, {
    List<String> yerelUrlAdaylari = const <String>[],
    bool tercihenDisUygulama = false,
  }) async {
    if (tercihenDisUygulama) {
      for (final String aday in yerelUrlAdaylari) {
        final Uri adayUri = Uri.parse(aday);
        if (await canLaunchUrl(adayUri)) {
          final bool acildi = await launchUrl(
            adayUri,
            mode: LaunchMode.externalApplication,
          );
          if (acildi) {
            return;
          }
        }
      }

      final Uri url = Uri.parse(urlString);
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        return;
      }
    }

    await _uygulamaIciWebAc(urlString);
  }

  Future<void> _tdkdeAra(String seciliMetin) async {
    final String sorgu = Uri.encodeQueryComponent(seciliMetin.trim());
    await _linkeGit('https://sozluk.gov.tr/?ara=$sorgu');
  }

  String _promptUret(String seciliMetin, String istek) {
    switch (istek) {
      case 'açıkla':
        return 'Aşağıdaki metni sade bir dille açıkla:\n\n"$seciliMetin"';
      case 'özetle':
        return 'Aşağıdaki metni kısa maddeler halinde özetle:\n\n"$seciliMetin"';
      case 'konuş':
        return 'Bu metin hakkında benimle sohbet eder gibi konuş, önce ana fikri söyle sonra yorumla:\n\n"$seciliMetin"';
      default:
        return seciliMetin;
    }
  }

  Future<void> _aiyeGonder({
    required String seciliMetin,
    required String istek,
    required bool chatGpt,
  }) async {
    final String prompt = _promptUret(seciliMetin, istek);
    final String encoded = Uri.encodeQueryComponent(prompt);

    if (chatGpt) {
      await _linkeGit(
        'https://chatgpt.com/?q=$encoded',
        tercihenDisUygulama: false,
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: prompt));
    await _linkeGit(
      'https://gemini.google.com/app?q=$encoded',
      tercihenDisUygulama: false,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Gemini için prompt da panoya kopyalandı (gerekirse yapıştırabilirsiniz).',
        ),
      ),
    );
  }

  Future<void> _paylas(String seciliMetin) async {
    final String baslik = _aktifDosyaAdi ?? 'PDF Alıntısı';
    final String icerik = '"$seciliMetin"\n\nKaynak: $baslik';
    await Share.share(icerik, subject: baslik);
  }

  Future<void> _hizliOkumaTumBelgeAc() async {
    if (_pdfBytes == null || !mounted) {
      return;
    }

    final sfpdf.PdfDocument belge = sfpdf.PdfDocument(inputBytes: _pdfBytes!);
    final String metin = sfpdf.PdfTextExtractor(belge).extractText();
    belge.dispose();

    final String temiz = metin.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (temiz.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => HizliOkumaEkrani(metin: temiz)),
    );
  }

  void _aiAksiyonMenusuAc(String seciliMetin) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'AI Aksiyonu Seç',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(context);
                        _aiyeGonder(
                          seciliMetin: seciliMetin,
                          istek: 'açıkla',
                          chatGpt: true,
                        );
                      },
                      child: const Text('ChatGPT • Açıkla'),
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(context);
                        _aiyeGonder(
                          seciliMetin: seciliMetin,
                          istek: 'özetle',
                          chatGpt: true,
                        );
                      },
                      child: const Text('ChatGPT • Özetle'),
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(context);
                        _aiyeGonder(
                          seciliMetin: seciliMetin,
                          istek: 'konuş',
                          chatGpt: true,
                        );
                      },
                      child: const Text('ChatGPT • Konuşalım'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _aiyeGonder(
                          seciliMetin: seciliMetin,
                          istek: 'açıkla',
                          chatGpt: false,
                        );
                      },
                      child: const Text('Gemini • Açıkla'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _aiyeGonder(
                          seciliMetin: seciliMetin,
                          istek: 'özetle',
                          chatGpt: false,
                        );
                      },
                      child: const Text('Gemini • Özetle'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _aiyeGonder(
                          seciliMetin: seciliMetin,
                          istek: 'konuş',
                          chatGpt: false,
                        );
                      },
                      child: const Text('Gemini • Konuşalım'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _gecmiseEkle(String dosyaAdi) {
    _sonDosyalar.removeWhere((item) => item.dosyaAdi == dosyaAdi);
    _sonDosyalar.insert(
      0,
      _GecmisDosya(dosyaAdi: dosyaAdi, acilisZamani: DateTime.now()),
    );
    if (_sonDosyalar.length > 10) {
      _sonDosyalar.removeRange(10, _sonDosyalar.length);
    }
    setState(() {});
  }

  void _yerImiEkleCikar() {
    setState(() {
      if (_yerImleri.contains(_aktifSayfa)) {
        _yerImleri.remove(_aktifSayfa);
      } else {
        _yerImleri.add(_aktifSayfa);
      }
    });
  }

  void _aramaYap() {
    final String anahtar = _aramaController.text.trim();
    if (anahtar.isEmpty) {
      return;
    }
    final PdfTextSearchResult sonuc = _pdfController.searchText(anahtar);
    setState(() {
      _aramaSonucu = sonuc;
    });
  }

  void _aramaPaneliAc() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PDF İçinde Ara'),
          content: TextField(
            controller: _aramaController,
            decoration: const InputDecoration(hintText: 'Aranacak metni yazın'),
            onSubmitted: (_) {
              _aramaYap();
              Navigator.pop(context);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _aramaSonucu?.previousInstance();
              },
              child: const Text('Önceki'),
            ),
            TextButton(
              onPressed: () {
                _aramaSonucu?.nextInstance();
              },
              child: const Text('Sonraki'),
            ),
            TextButton(
              onPressed: () {
                _aramaSonucu?.clear();
              },
              child: const Text('Temizle'),
            ),
            FilledButton(
              onPressed: () {
                _aramaYap();
                Navigator.pop(context);
              },
              child: const Text('Ara'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _notEkleDialoguAc(String secilenKelime) async {
    final TextEditingController controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Not Ekle'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Seçili metin için not yazın',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final String notIcerigi = controller.text.trim();
                if (notIcerigi.isNotEmpty) {
                  setState(() {
                    _notlar.add(
                      _NotKaydi(
                        seciliMetin: secilenKelime,
                        notIcerigi: notIcerigi,
                        sayfa: _aktifSayfa,
                        zaman: DateTime.now(),
                      ),
                    );
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  String _txtRaporuOlustur() {
    final StringBuffer sb = StringBuffer();
    sb.writeln('$kUygulamaAdi Dışa Aktarım');
    sb.writeln('Dosya: ${_aktifDosyaAdi ?? 'Seçilmedi'}');
    sb.writeln('Tarih: ${DateTime.now()}');
    sb.writeln('');

    sb.writeln('[Yer İmleri]');
    for (final int sayfa in _yerImleri.toList()..sort()) {
      sb.writeln('- Sayfa $sayfa');
    }
    sb.writeln('');

    sb.writeln('[Kelime Defteri]');
    for (final String kelime in _kelimeDefteri) {
      sb.writeln('- $kelime');
    }
    sb.writeln('');

    sb.writeln('[Notlar]');
    for (final _NotKaydi not in _notlar) {
      sb.writeln(
        '- Sayfa ${not.sayfa} | ${not.seciliMetin} | ${not.notIcerigi}',
      );
    }
    sb.writeln('');

    sb.writeln('[İşaretler]');
    for (final _IsaretKaydi isaret in _isaretler) {
      sb.writeln(
        '- Sayfa ${isaret.sayfa} | ${isaret.seciliMetin} | ${isaret.renkAdi}',
      );
    }

    return sb.toString();
  }

  String _csvRaporuOlustur() {
    final StringBuffer sb = StringBuffer();
    sb.writeln('tur,sayfa,metin,detay');

    for (final int sayfa in _yerImleri.toList()..sort()) {
      sb.writeln('yer_imi,$sayfa,,');
    }
    for (final String kelime in _kelimeDefteri) {
      sb.writeln('kelime,,$kelime,');
    }
    for (final _NotKaydi not in _notlar) {
      final String temizNot = not.notIcerigi.replaceAll(',', ' ');
      final String temizMetin = not.seciliMetin.replaceAll(',', ' ');
      sb.writeln('not,${not.sayfa},$temizMetin,$temizNot');
    }
    for (final _IsaretKaydi isaret in _isaretler) {
      final String temizMetin = isaret.seciliMetin.replaceAll(',', ' ');
      sb.writeln('isaret,${isaret.sayfa},$temizMetin,${isaret.renkAdi}');
    }

    return sb.toString();
  }

  Future<void> _panoyaKopyala(String veri, String etiket) async {
    await Clipboard.setData(ClipboardData(text: veri));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$etiket panoya kopyalandı.')));
  }

  void _yardimciPanelAc() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  _aktifDosyaAdi ?? 'Dosya seçilmedi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () =>
                          _panoyaKopyala(_txtRaporuOlustur(), 'TXT raporu'),
                      icon: const Icon(Icons.copy),
                      label: const Text('TXT Dışa Aktar'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          _panoyaKopyala(_csvRaporuOlustur(), 'CSV raporu'),
                      icon: const Icon(Icons.table_chart),
                      label: const Text('CSV Dışa Aktar'),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Text(
                  'Yer İmleri',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (_yerImleri.isEmpty)
                  const ListTile(title: Text('Kayıt yok'))
                else
                  ...(_yerImleri.toList()..sort()).map(
                    (sayfa) => ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text('Sayfa $sayfa'),
                      onTap: () {
                        _pdfController.jumpToPage(sayfa);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                const Divider(height: 28),
                Text(
                  'Kelime Defteri',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (_kelimeDefteri.isEmpty)
                  const ListTile(title: Text('Kayıt yok'))
                else
                  ..._kelimeDefteri.map(
                    (kelime) => ListTile(
                      leading: const Icon(Icons.translate),
                      title: Text(kelime),
                      onTap: () {
                        _aramaController.text = kelime;
                        _aramaYap();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                const Divider(height: 28),
                Text('Notlar', style: Theme.of(context).textTheme.titleSmall),
                if (_notlar.isEmpty)
                  const ListTile(title: Text('Kayıt yok'))
                else
                  ..._notlar.reversed.map(
                    (not) => ListTile(
                      leading: const Icon(Icons.note_alt_outlined),
                      title: Text(not.seciliMetin),
                      subtitle: Text('Sayfa ${not.sayfa} • ${not.notIcerigi}'),
                      onTap: () {
                        _pdfController.jumpToPage(not.sayfa);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                const Divider(height: 28),
                Text(
                  'Son Açılan Dosyalar',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (_sonDosyalar.isEmpty)
                  const ListTile(title: Text('Kayıt yok'))
                else
                  ..._sonDosyalar.map(
                    (gecmis) => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(gecmis.dosyaAdi),
                      subtitle: Text(gecmis.acilisZamani.toLocal().toString()),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _altCekmeceyiAc(String secilenKelime) {
    if (_cekmeceAcikMi) {
      return;
    }
    _cekmeceAcikMi = true;

    final String cevirIcinSifreli = Uri.encodeComponent(secilenKelime);
    final String aramaIcinSifreli = Uri.encodeQueryComponent(
      '$secilenKelime nedir',
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.blueGrey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        bool renkPaletiAcik = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Seçilen: "$secilenKelime"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!renkPaletiAcik)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _kelimeDefteri.add(secilenKelime);
                            });
                            _linkeGit(
                              'https://translate.google.com/?sl=en&tl=tr&text=$cevirIcinSifreli&op=translate',
                            );
                          },
                          icon: const Icon(
                            Icons.translate,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Çevir',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _linkeGit(
                              'https://www.google.com/search?q=$aramaIcinSifreli',
                            );
                          },
                          icon: const Icon(Icons.search, color: Colors.white),
                          label: const Text(
                            'Ara',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _tdkdeAra(secilenKelime);
                          },
                          icon: const Icon(
                            Icons.menu_book,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'TDK',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setModalState(() {
                              renkPaletiAcik = true;
                            });
                          },
                          icon: const Icon(Icons.palette, color: Colors.black),
                          label: const Text(
                            'İşaretle',
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _notEkleDialoguAc(secilenKelime);
                          },
                          icon: const Icon(Icons.note_add, color: Colors.white),
                          label: const Text(
                            'Not',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _aiAksiyonMenusuAc(secilenKelime);
                          },
                          icon: const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'AI',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _paylas(secilenKelime);
                          },
                          icon: const Icon(Icons.share, color: Colors.white),
                          label: const Text(
                            'Paylaş',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                        ),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Renk Seç:',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isaretler.add(
                                _IsaretKaydi(
                                  seciliMetin: secilenKelime,
                                  renkAdi: 'Sarı',
                                  renk: Colors.yellow,
                                  sayfa: _aktifSayfa,
                                  zaman: DateTime.now(),
                                ),
                              );
                            });
                            Navigator.pop(context);
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.yellow,
                            radius: 20,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isaretler.add(
                                _IsaretKaydi(
                                  seciliMetin: secilenKelime,
                                  renkAdi: 'Yeşil',
                                  renk: Colors.greenAccent,
                                  sayfa: _aktifSayfa,
                                  zaman: DateTime.now(),
                                ),
                              );
                            });
                            Navigator.pop(context);
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.greenAccent,
                            radius: 20,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isaretler.add(
                                _IsaretKaydi(
                                  seciliMetin: secilenKelime,
                                  renkAdi: 'Pembe',
                                  renk: Colors.pinkAccent,
                                  sayfa: _aktifSayfa,
                                  zaman: DateTime.now(),
                                ),
                              );
                            });
                            Navigator.pop(context);
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.pinkAccent,
                            radius: 20,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _kelimeDefteri.add(secilenKelime);
                            });
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.bookmark_add,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Deftere Ekle',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _cekmeceAcikMi = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget anaIcerik = _pdfBytes == null
        ? Center(
            child: ElevatedButton.icon(
              onPressed: _dosyaSec,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _t('selectPdf'),
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          )
        : SfPdfViewer.memory(
            _pdfBytes!,
            controller: _pdfController,
            enableTextSelection: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _toplamSayfa = details.document.pages.count;
              });

              final int? kayitliSayfa = _kayitliSayfaAdayi;
              if (kayitliSayfa != null) {
                final int hedefSayfa = kayitliSayfa.clamp(1, _toplamSayfa);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _pdfBytes == null) {
                    return;
                  }
                  _pdfController.jumpToPage(hedefSayfa);
                });
                _kayitliSayfaAdayi = null;
              }
            },
            onPageChanged: (PdfPageChangedDetails details) {
              _hizliKaydirmaFlasiKontrolEt(details);
              setState(() {
                _aktifSayfa = details.newPageNumber;
              });
              _ekranAcikTutmaSayaciniSifirla();
              unawaited(_sonSayfayiKaydet());
            },
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              final String? secilen = details.selectedText?.trim();
              if (secilen == null || secilen.isEmpty) {
                _bekleyenSecimMetni = null;
                _secimBeklemeZamanlayicisi?.cancel();
                return;
              }

              _bekleyenSecimMetni = secilen;
              _secimBeklemeZamanlayicisi?.cancel();
              _secimBeklemeZamanlayicisi = Timer(
                const Duration(milliseconds: 900),
                () {
                  if (!mounted || _cekmeceAcikMi) {
                    return;
                  }
                  final String? metin = _bekleyenSecimMetni;
                  if (metin != null && metin.isNotEmpty) {
                    _pdfController.clearSelection();
                    _altCekmeceyiAc(metin);
                  }
                },
              );
            },
          );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _kullaniciEtkilesimiAlgila(),
      onPointerMove: (_) => _kullaniciEtkilesimiAlgila(),
      onPointerSignal: (_) => _kullaniciEtkilesimiAlgila(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _okumaModu
            ? null
            : AppBar(
                title: Text(
                  _aktifDosyaAdi == null
                      ? _t('title')
                      : '${_t('title')} • Sayfa $_aktifSayfa',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                actions: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.folder_open,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'PDF seç',
                    onPressed: _dosyaSec,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'PDF içinde ara',
                    onPressed: _pdfBytes == null ? null : _aramaPaneliAc,
                  ),
                  IconButton(
                    icon: Icon(
                      _yerImleri.contains(_aktifSayfa)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'Yer imi ekle/kaldır',
                    onPressed: _pdfBytes == null ? null : _yerImiEkleCikar,
                  ),
                  IconButton(
                    icon: Icon(
                      widget.karanlikMod
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'Tema değiştir',
                    onPressed: widget.onTemaDegistir,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.speed,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'Hızlı okuma (tüm belge)',
                    onPressed: _pdfBytes == null ? null : _hizliOkumaTumBelgeAc,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.dashboard_customize,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'Yardımcı panel',
                    onPressed: _yardimciPanelAc,
                  ),
                  IconButton(
                    icon: Icon(
                      _otomatikKaydirmaAktif
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'Otomatik kaydırma',
                    onPressed: _pdfBytes == null
                        ? null
                        : _otomatikKaydirmaDegistir,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'Ayarlar',
                    onPressed: _ayarlarPaneliAc,
                  ),
                ],
              ),
        body: Stack(
          children: <Widget>[
            Positioned.fill(child: anaIcerik),
            if (_idleEmojiAktif)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.92),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.82,
                                  end: 1,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                      child: Builder(
                        key: ValueKey<String>(
                          '$_idleEmoji-$_idleEmojiSaniyesi',
                        ),
                        builder: (BuildContext context) {
                          final double boyut =
                              MediaQuery.of(context).size.shortestSide * 0.48;
                          return Text(
                            _idleEmoji,
                            style: TextStyle(fontSize: boyut, height: 1),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            if (_flasAktif)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _flasAktif ? 0.75 : 0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _pdfBytes == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Okuma: ${_sureFormatla(_okumaSaniyesi)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '🥈 $_gumus',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '🥇 $_altin',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _solucanKitapYolu(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sayfa $_aktifSayfa/${_toplamSayfa == 0 ? '?' : _toplamSayfa}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        floatingActionButton: _okumaModu
            ? FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _okumaModu = false;
                  });
                },
                label: const Text('Okuma Modundan Çık'),
                icon: const Icon(Icons.fullscreen_exit),
              )
            : null,
      ),
    );
  }
}

class UygulamaIciWebSayfasi extends StatefulWidget {
  const UygulamaIciWebSayfasi({
    super.key,
    required this.url,
    required this.baslik,
  });

  final String url;
  final String baslik;

  @override
  State<UygulamaIciWebSayfasi> createState() => _UygulamaIciWebSayfasiState();
}

class _UygulamaIciWebSayfasiState extends State<UygulamaIciWebSayfasi> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.baslik),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () async {
              if (await _controller.canGoForward()) {
                await _controller.goForward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class _NotKaydi {
  _NotKaydi({
    required this.seciliMetin,
    required this.notIcerigi,
    required this.sayfa,
    required this.zaman,
  });

  final String seciliMetin;
  final String notIcerigi;
  final int sayfa;
  final DateTime zaman;
}

class _IsaretKaydi {
  _IsaretKaydi({
    required this.seciliMetin,
    required this.renkAdi,
    required this.renk,
    required this.sayfa,
    required this.zaman,
  });

  final String seciliMetin;
  final String renkAdi;
  final Color renk;
  final int sayfa;
  final DateTime zaman;
}

class _GecmisDosya {
  _GecmisDosya({required this.dosyaAdi, required this.acilisZamani});

  final String dosyaAdi;
  final DateTime acilisZamani;
}

class HizliOkumaEkrani extends StatefulWidget {
  const HizliOkumaEkrani({super.key, required this.metin});

  final String metin;

  @override
  State<HizliOkumaEkrani> createState() => _HizliOkumaEkraniState();
}

class _HizliOkumaEkraniState extends State<HizliOkumaEkrani> {
  late final List<String> _kelimeler;

  Timer? _timer;
  int _index = 0;
  double _hizWpm = 220;
  bool _oynuyor = true;

  @override
  void initState() {
    super.initState();
    _kelimeler = widget.metin
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _akisiBaslat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _adimSuresi() {
    final int ms = (60000 / _hizWpm).round().clamp(60, 1200);
    return Duration(milliseconds: ms);
  }

  void _akisiBaslat() {
    _timer?.cancel();
    if (!_oynuyor || _kelimeler.isEmpty) {
      return;
    }

    _timer = Timer.periodic(_adimSuresi(), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_index < _kelimeler.length - 1) {
          _index++;
        } else {
          _oynuyor = false;
          timer.cancel();
        }
      });
    });
  }

  void _oynatDurdur() {
    setState(() {
      _oynuyor = !_oynuyor;
    });
    _akisiBaslat();
  }

  void _basaSar() {
    setState(() {
      _index = 0;
      _oynuyor = true;
    });
    _akisiBaslat();
  }

  @override
  Widget build(BuildContext context) {
    final int toplam = _kelimeler.length;
    final String aktifKelime = toplam == 0
        ? 'Metin yok'
        : _kelimeler[_index.clamp(0, toplam - 1)];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Hızlı Okuma Modu'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              LinearProgressIndicator(
                value: toplam == 0 ? 0 : (_index + 1) / toplam,
                backgroundColor: Colors.white24,
                color: Colors.cyanAccent,
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Text(
                'Kelime ${toplam == 0 ? 0 : _index + 1} / $toplam',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Container(
                  key: ValueKey<String>(aktifKelime),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade300,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    aktifKelime,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 38,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gözün kelimeyi takip etsin; hız ayarını aşağıdan değiştir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  const Text('Hız', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: _hizWpm,
                      min: 100,
                      max: 700,
                      divisions: 60,
                      label: '${_hizWpm.round()} WPM',
                      onChanged: (double value) {
                        setState(() {
                          _hizWpm = value;
                        });
                        _akisiBaslat();
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _basaSar,
                    icon: const Icon(Icons.replay),
                    label: const Text('Başa Sar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _oynatDurdur,
                    icon: Icon(_oynuyor ? Icons.pause : Icons.play_arrow),
                    label: Text(_oynuyor ? 'Duraklat' : 'Oynat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
