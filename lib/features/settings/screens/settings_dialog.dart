import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/game_provider.dart';

class SettingsDialog extends StatelessWidget {
  final VoidCallback onVerileriSifirla;

  const SettingsDialog({super.key, required this.onVerileriSifirla});

  @override
  Widget build(BuildContext context) {
    // 💎 Provider'ı dinliyoruz
    final game = context.watch<GameProvider>();

    return AlertDialog(
      backgroundColor: const Color(0xFF151522), 
      title: const Text("⚙️ Ayarlar", style: TextStyle(color: Colors.white)), 
      content: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [ 
          SwitchListTile(
            title: const Text("Ses Efektleri", style: TextStyle(color: Colors.white)), 
            value: game.sesAcik, 
            activeColor: Colors.amber, 
            onChanged: (val) { 
              game.sesAcik = val;
              game.verileriKaydet();
              game.notifyListeners();
            }
          ), 
          SwitchListTile(
            title: const Text("Titreşim", style: TextStyle(color: Colors.white)), 
            value: game.titresimAcik, 
            activeColor: Colors.amber, 
            onChanged: (val) { 
              game.titresimAcik = val;
              game.verileriKaydet();
              game.notifyListeners();
            }
          ), 
          const Divider(color: Colors.white24), 
          
          ElevatedButton(
            onPressed: () async { 
              // 1. Cihaz hafızasını temizle
              final prefs = await SharedPreferences.getInstance(); 
              await prefs.clear(); 
              
              // 2. Provider'ı sıfırla
              game.ilkAcilis = true;
              game.level = 1; 
              game.gold = 0; 
              game.currentXP = 0; 
              game.targetXP = 100; 
              game.playerHP = 100;
              game.bossIndex = 0; 
              game.bossHP = 200; 
              game.toplamOdakDakikasi = 0; 
              game.tamamlananGorevSayisi = 0; 
              game.yumurtaVar = false; 
              game.petAcildi = false; 
              game.satinAlinanSesler = ["rain.mp3", "tavern.mp3"]; 
              
              game.verileriKaydet();
              game.notifyListeners();

              // 3. Menüyü Kapat ve Reklamları Sıfırla
              Navigator.pop(context); 
              onVerileriSifirla(); 
              
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Tüm veriler sıfırlandı!"), backgroundColor: Colors.red
              ));
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
            child: const Text("VERİLERİ SIFIRLA", style: TextStyle(color: Colors.white))
          ) 
        ]
      ), 
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Kapat", style: TextStyle(color: Colors.amber))
        )
      ] 
    );
  }
}