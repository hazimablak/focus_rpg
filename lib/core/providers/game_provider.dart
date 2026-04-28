import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameProvider extends ChangeNotifier {
  // --- TEMEL RPG VERİLERİ ---
  bool ilkAcilis = true;
  int level = 1;
  int currentXP = 0;
  int targetXP = 100;
  int gold = 0;
  int playerHP = 100;
  int playerMaxHP = 100;
  int bossIndex = 0;
  int bossHP = 200;
  int bossMaxHP = 200;
  int toplamOdakDakikasi = 0;
  int tamamlananGorevSayisi = 0;
  int gunlukSeri = 0;

  // --- MARKET VE AYAR VERİLERİ (YENİ EKLENDİ) ---
  bool sesAcik = true;
  bool titresimAcik = true;
  bool yumurtaVar = false;
  bool petAcildi = false;
  int petLevel = 1;
  bool xpKalkaniVar = false;
  bool buzBuyusuAktif = false;
  int seciliTemaID = 0;
  List<String> satinAlinanSesler = ["rain.mp3", "tavern.mp3"];
  List<bool> satinAlinanTemalar = [true, false, false, false];

  GameProvider() { verileriYukle(); }

  Future<void> verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    ilkAcilis = prefs.getBool('ilkAcilis') ?? true;
    level = prefs.getInt('level') ?? 1;
    gold = prefs.getInt('gold') ?? 0;
    currentXP = prefs.getInt('xp') ?? 0;
    targetXP = prefs.getInt('targetXP') ?? 100;
    playerHP = prefs.getInt('playerHP') ?? 100;
    bossIndex = prefs.getInt('bossIndex') ?? 0;
    bossMaxHP = prefs.getInt('bossMaxHP') ?? 200; 
    bossHP = prefs.getInt('bossHP') ?? bossMaxHP;
    toplamOdakDakikasi = prefs.getInt('toplamOdak') ?? 0;
    tamamlananGorevSayisi = prefs.getInt('tamamlananGorev') ?? 0;
    gunlukSeri = prefs.getInt('gunlukSeri') ?? 0;

    // Yeni eklenenler
    sesAcik = prefs.getBool('sesAcik') ?? true;
    titresimAcik = prefs.getBool('titresimAcik') ?? true;
    yumurtaVar = prefs.getBool('yumurtaVar') ?? false;
    petAcildi = prefs.getBool('petAcildi') ?? false;
    petLevel = prefs.getInt('petLevel') ?? 1;
    xpKalkaniVar = prefs.getBool('xpKalkaniVar') ?? false;
    seciliTemaID = prefs.getInt('seciliTemaID') ?? 0;
    satinAlinanSesler = prefs.getStringList('satinAlinanSesler') ?? ["rain.mp3", "tavern.mp3"];
    
    List<String>? temaKayit = prefs.getStringList('satinAlinanTemalar');
    if (temaKayit != null) {
      satinAlinanTemalar = temaKayit.map((e) => e == "true").toList();
    }
    notifyListeners();
  }

  Future<void> verileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ilkAcilis', ilkAcilis);
    await prefs.setInt('level', level);
    await prefs.setInt('gold', gold);
    await prefs.setInt('xp', currentXP);
    await prefs.setInt('targetXP', targetXP);
    await prefs.setInt('playerHP', playerHP);
    await prefs.setInt('bossIndex', bossIndex);
    await prefs.setInt('bossHP', bossHP);
    await prefs.setInt('bossMaxHP', bossMaxHP);
    await prefs.setInt('toplamOdak', toplamOdakDakikasi);
    await prefs.setInt('tamamlananGorev', tamamlananGorevSayisi);
    await prefs.setInt('gunlukSeri', gunlukSeri);

    // Yeni eklenenler
    await prefs.setBool('sesAcik', sesAcik);
    await prefs.setBool('titresimAcik', titresimAcik);
    await prefs.setBool('yumurtaVar', yumurtaVar);
    await prefs.setBool('petAcildi', petAcildi);
    await prefs.setInt('petLevel', petLevel);
    await prefs.setBool('xpKalkaniVar', xpKalkaniVar);
    await prefs.setInt('seciliTemaID', seciliTemaID);
    await prefs.setStringList('satinAlinanSesler', satinAlinanSesler);
    await prefs.setStringList('satinAlinanTemalar', satinAlinanTemalar.map((e) => e.toString()).toList());
  }

  // Altın Ekleme & Harcama Mantığı
  void altinEkle(int miktar) { gold += miktar; verileriKaydet(); notifyListeners(); }
  bool altinHarca(int miktar) {
    if (gold >= miktar) { gold -= miktar; verileriKaydet(); notifyListeners(); return true; }
    return false;
  }
}