import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

// Çekirdek Dosyalarımız
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_box.dart';
import '../../../core/providers/game_provider.dart';
import 'package:focus_rpg/features/market/screens/market_sheet.dart';
import 'package:focus_rpg/features/settings/screens/settings_dialog.dart';

class AnaOyunEkrani extends StatefulWidget {
  const AnaOyunEkrani({super.key});

  @override
  State<AnaOyunEkrani> createState() => _AnaOyunEkraniState();
}

class _AnaOyunEkraniState extends State<AnaOyunEkrani> with WidgetsBindingObserver, TickerProviderStateMixin {
  final Random _random = Random();

  // --- UI ve Timer Durumları (Sadece bu ekranı ilgilendirenler) ---
  int saniyeSayaci = 0; 
  int xpSayaci = 0; 
  int goldSayaci = 0; 
  int hedefGoldSuresi = 5; 
  final int reklamOdulu = 50; 
  double secilenDakika = 25;
  int kalanSaniye = 25 * 60;
  Timer? zamanlayici;
  Timer? cezaZamanlayicisi;
  bool calisiyorMu = false;

  // --- PET VE DİĞER LOKAL VERİLER ---
  bool yumurtaVar = false;
  bool petAcildi = false;
  String petTuru = "";
  int petLevel = 1;
  int yumurtaSayaci = 0; 
  final int yumurtaHedefSure = 600; 
  List<String> calismaGunleri = []; 

  // Listeler ve Ayarlar
  final List<Map<String, dynamic>> canavarlar = [
    {"isim": "Jöle", "emoji": "🦠", "hp": 200},
    {"isim": "Yarasa", "emoji": "🦇", "hp": 400},
    {"isim": "Kurt", "emoji": "🐺", "hp": 700},
    {"isim": "Goblin", "emoji": "👺", "hp": 1200},
    {"isim": "Ejderha", "emoji": "🐉", "hp": 8000},
    {"isim": "Karanlık Lord", "emoji": "😈", "hp": 15000},
  ];

  final List<String> quotes = [
    "Bir büyücü asla geç kalmaz, tam zamanında odaklanır.",
    "Büyük güç, büyük odaklanma gerektirir.",
    "Zafer, pes etmeyenlerindir.",
  ];

  bool sesAcik = true;
  bool titresimAcik = true;
  int seciliTemaID = 0; 
  List<bool> satinAlinanTemalar = [true, false, false, false];
  bool xpKalkaniVar = false;
  bool buzBuyusuAktif = false;
  DateTime? buzBitisZamani;
  final TextEditingController _gorevController = TextEditingController();
  String mevcutGorev = "";
  bool cezaYendi = false;      
  int sonKesilenCeza = 0;      

  late ConfettiController _confettiController;
  final AudioPlayer _sfxPlayer = AudioPlayer(); 
  final AudioPlayer _ambiencePlayer = AudioPlayer(); 
  String? calanAtmosfer; 

  // --- REKLAMLAR ---
  RewardedAd? _odulluReklam;
  BannerAd? _bannerAd; 
  InterstitialAd? _gecisReklami; 
  bool reklamYuklendi = false;
  bool bannerYuklendi = false;
  bool reklamIzliyor = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _petAnimController;
  late Animation<double> _petScaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _lokalVerileriYukle().then((_) {
      if(mounted) {
        if (Platform.isAndroid || Platform.isIOS) {
          reklamYukle(); 
          bannerReklamYukle(); 
          gecisReklamiYukle(); 
        }
      }
    });
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _ambiencePlayer.setReleaseMode(ReleaseMode.loop); 

    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));
    
    _petAnimController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _petScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _petAnimController, curve: Curves.easeInOut));
  }

  String _tarihFormatla(DateTime tarih) {
    return "${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _sfxPlayer.dispose();
    _ambiencePlayer.dispose();
    _gorevController.dispose();
    _odulluReklam?.dispose();
    _bannerAd?.dispose();
    _gecisReklami?.dispose(); 
    _shakeController.dispose();
    _petAnimController.dispose();
    zamanlayici?.cancel();
    cezaZamanlayicisi?.cancel();
    super.dispose();
  }

  // --- REKLAM FONKSİYONLARI ---
  void reklamYukle() {
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId, 
      request: const AdRequest(), 
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) { 
          _odulluReklam = ad; 
          reklamYuklendi = true; 
        }, 
        onAdFailedToLoad: (error) { 
          reklamYuklendi = false; 
          Future.delayed(const Duration(seconds: 15), () => reklamYukle());
        }
      )
    );
  }

  void gecisReklamiYukle() { 
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _gecisReklami = ad;
          _gecisReklami!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              gecisReklamiYukle(); 
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              gecisReklamiYukle();
            },
          );
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }
  
  void bannerReklamYukle() {
    _bannerAd?.dispose(); 
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId, 
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) { setState(() { bannerYuklendi = true; }); }, 
        onAdFailedToLoad: (ad, error) { 
          ad.dispose(); 
          setState(() { bannerYuklendi = false; });
          Future.delayed(const Duration(seconds: 30), () => bannerReklamYukle());
        }
      ),
    );
    _bannerAd!.load();
  }

  void reklamiGoster() {
    final game = context.read<GameProvider>();
    if (!Platform.isAndroid && !Platform.isIOS) { 
      game.altinEkle(reklamOdulu);
      _mesajGoster("PC'de reklam yok! +$reklamOdulu G"); 
      return; 
    } 
    
    if (reklamYuklendi && _odulluReklam != null) { 
      reklamIzliyor = true; 
      _odulluReklam!.show(onUserEarnedReward: (adWithoutView, reward) { 
        game.altinEkle(reklamOdulu);
        _mesajGoster("+$reklamOdulu ALTIN KAZANDIN!"); 
        sfxCal('level.mp3'); 
        _confettiController.play(); 
      }); 
      
      _odulluReklam = null; 
      reklamYuklendi = false; 
      Future.delayed(const Duration(seconds: 1), () { 
        reklamIzliyor = false; 
        reklamYukle(); 
      }); 
    } else { 
      _mesajGoster("Reklam yükleniyor... Birkaç saniye sonra tekrar dene."); 
      reklamYukle(); 
    } 
  }

  Future<void> sfxCal(String dosyaAdi) async { 
    if (!sesAcik) return;
    try { await _sfxPlayer.play(AssetSource(dosyaAdi)); } catch (_) {} 
  }

  void _mesajGoster(String mesaj) { 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.indigo, duration: const Duration(seconds: 2))); 
  }

  void sayaciBaslat() {
    final game = context.read<GameProvider>();
    if (_gorevController.text.isEmpty) { _mesajGoster("Lütfen bir görev yaz!"); return; }
    if (game.playerHP <= 0) { _mesajGoster("Canın yok! Markete git."); return; }
    if (calisiyorMu) return;
    
    setState(() {
      kalanSaniye = (secilenDakika * 60).toInt();
      calisiyorMu = true; 
      mevcutGorev = _gorevController.text; 
      xpSayaci = 0; goldSayaci = 0;
      hedefGoldSuresi = _random.nextInt(8) + 3;
    });
    
    FocusScope.of(context).unfocus();
    if (titresimAcik) { sfxCal('sword_draw.mp3'); HapticFeedback.heavyImpact(); } 

    zamanlayici = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (kalanSaniye > 0) {
          kalanSaniye--;
          
          xpSayaci++;
          if (xpSayaci >= 3) {
             xpSayaci = 0;
             game.currentXP += (xpKalkaniVar ? 2 : 1); 
             game.bossHP -= (1 + (game.level ~/ 5)); // Hasar hesabı
             if (game.bossHP <= 0) {
                game.bossHP = game.bossMaxHP; 
                game.gold += 500;
                _mesajGoster("BOSS ÖLDÜ! +500 Altın"); 
                _confettiController.play();
             }
             if (game.currentXP >= game.targetXP) { 
               game.level++; 
               game.currentXP = 0; 
               game.targetXP += 50; 
               _confettiController.play(); 
             }
          }
          game.verileriKaydet(); // Her sn kaydet (ileride bunu optimize edebiliriz)
          game.notifyListeners(); // Arayüzü tetikle
        } else {
          zamanlayici?.cancel(); 
          calisiyorMu = false; 
          game.tamamlananGorevSayisi++; 
          game.gold += (secilenDakika * 10).toInt(); 
          
          _mesajGoster("Görev Bitti! Altın kazandın."); 
          _gorevController.clear(); 
          _confettiController.play(); 
          sfxCal('level.mp3'); 
          game.verileriKaydet(); 
          game.notifyListeners();
          
          if(_gecisReklami != null) { _gecisReklami!.show(); }
        }
      });
    });
  }

  // UI İÇİN LOKAL VERİLERİ YÜKLE
  Future<void> _lokalVerileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sesAcik = prefs.getBool('sesAcik') ?? true;
      titresimAcik = prefs.getBool('titresimAcik') ?? true;
      seciliTemaID = prefs.getInt('seciliTemaID') ?? 0;
      petAcildi = prefs.getBool('petAcildi') ?? false;
      petTuru = prefs.getString('petTuru') ?? "";
    });
  }

  Widget savasAlani(GameProvider game) {
    double bossYuzde = (game.bossHP / game.bossMaxHP).clamp(0.0, 1.0);
    double playerYuzde = (game.playerHP / game.playerMaxHP).clamp(0.0, 1.0);
    var canavar = canavarlar[game.bossIndex % canavarlar.length]; 

    return GlassBox(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("BOSS: ${canavar['isim']}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)), Text("${game.bossHP} / ${game.bossMaxHP} HP", style: const TextStyle(color: Colors.white54, fontSize: 12))]),
              GestureDetector(onTap: () => sfxCal('hit.mp3'), child: Text(canavar['emoji'], style: const TextStyle(fontSize: 50))),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: bossYuzde, color: Colors.red, backgroundColor: Colors.red.withOpacity(0.2), minHeight: 8),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [const Text("👑", style: TextStyle(fontSize: 50)), const SizedBox(width: 15), if(petAcildi) Text(petTuru, style: const TextStyle(fontSize: 40))]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("SAVAŞÇI", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)), Text("${game.playerHP} / ${game.playerMaxHP} HP", style: const TextStyle(color: Colors.white54, fontSize: 12))]),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: playerYuzde, color: Colors.green, backgroundColor: Colors.green.withOpacity(0.2), minHeight: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>(); // Beyni (Provider'ı) dinliyoruz!

    return Scaffold(
      backgroundColor: const Color(0xFF151522),
      floatingActionButton: FloatingActionButton(
  onPressed: () {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) => MarketSheet(
        onReklamIzle: reklamiGoster, // Reklam fonksiyonunu markete paslıyoruz!
      ),
    );
  }, 
  backgroundColor: Colors.amber, 
  child: const Icon(Icons.storefront, color: Colors.black)
),
      
      bottomNavigationBar: (bannerYuklendi && _bannerAd != null) 
          ? SafeArea(child: SizedBox(height: _bannerAd!.size.height.toDouble(), width: _bannerAd!.size.width.toDouble(), child: AdWidget(ad: _bannerAd!)))
          : null,
      
      body: SingleChildScrollView(
        child: SafeArea(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(
                children: [
                  // Üst Bar (Level ve Ayarlar)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LVL ${game.level}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)), Text('${game.currentXP} / ${game.targetXP} XP', style: const TextStyle(color: Colors.white54))]), Row(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.person, color: Colors.cyanAccent)), IconButton(onPressed: () {}, icon: const Icon(Icons.settings, color: Colors.white54))])])),
                  
                  // İstatistikler Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassBox(
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.timer, color: Colors.white54, size: 16), const SizedBox(width: 5), Text("${game.toplamOdakDakikasi} Dk", style: const TextStyle(color: Colors.white54)), const SizedBox(width: 15), const Icon(Icons.check_circle, color: Colors.white54, size: 16), const SizedBox(width: 5), Text("${game.tamamlananGorevSayisi} Görev", style: const TextStyle(color: Colors.white54))]), Row(children: [const Icon(Icons.local_fire_department, color: Colors.orange), const SizedBox(width: 5), Text("${game.gunlukSeri} Gün", style: const TextStyle(color: Colors.white))])]),
                    ),
                  ),
                  
                  // Altın Göstergesi
                  Padding(padding: const EdgeInsets.only(top: 10, right: 20, left: 20), child: Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.monetization_on, color: Colors.amber, size: 20), const SizedBox(width: 8), Text('${game.gold}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amberAccent))])))),
                  
                  // XP Barı
                  const SizedBox(height: 10), 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20), 
                    child: LinearProgressIndicator(value: (game.currentXP / game.targetXP).clamp(0.0, 1.0), minHeight: 10, backgroundColor: Colors.white10, color: Colors.greenAccent),
                  ),

                  // Savaş Alanı ve Timer
                  const SizedBox(height: 10),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: savasAlani(game)), 
                  
                  if (!calisiyorMu) 
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(height: 20), const Text("Süre Ayarla (Dakika)", style: TextStyle(color: Colors.white54)), Slider(value: secilenDakika, min: 5, max: 120, divisions: 23, activeColor: Colors.pinkAccent, inactiveColor: Colors.white10, label: "${secilenDakika.toInt()} Dk", onChanged: (val) { setState(() { secilenDakika = val; kalanSaniye = (val * 60).toInt(); }); }), const SizedBox(height: 10), TextField(controller: _gorevController, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18), decoration: const InputDecoration(hintText: "Örn: Kitap Oku", prefixIcon: Icon(Icons.edit, color: Colors.white54))), const SizedBox(height: 20), ElevatedButton(onPressed: calisiyorMu ? null : sayaciBaslat, style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text("BAŞLA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), const SizedBox(height: 50)])) 
                  else 
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(height: 20), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), child: Text("🎯 Odak: $mevcutGorev", style: const TextStyle(fontSize: 20, color: Colors.cyanAccent))), const SizedBox(height: 10), Text("${kalanSaniye ~/ 60}:${(kalanSaniye % 60).toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)), const SizedBox(height: 20)]),
                ],
              ),
              ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false, colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple]),
            ],
          ),
        ),
      ),
    );
  }
}