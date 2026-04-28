import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/game_provider.dart';

class MarketSheet extends StatelessWidget {
  final VoidCallback onReklamIzle;

  const MarketSheet({super.key, required this.onReklamIzle});

  void _mesajGoster(BuildContext context, String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj), backgroundColor: Colors.indigo, duration: const Duration(seconds: 1)
    ));
  }

  @override
  Widget build(BuildContext context) {
    // 💎 Provider'ı dinliyoruz
    final game = context.watch<GameProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151522),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 10),
            
            // Başlık ve Altın Miktarı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                const Text("⚔️ Market", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), 
                  child: Row(children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 16), 
                    const SizedBox(width: 5), 
                    Text("${game.gold} G", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
                  ])
                )
            ]),
            const SizedBox(height: 15),

            // Reklam Butonu
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Marketi kapat
                onReklamIzle(); // Reklam fonksiyonunu tetikle
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.play_circle_fill, color: Colors.black, size: 30), 
                  const SizedBox(width: 10), 
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text("ALTIN KAZAN (+50 G)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)), 
                    Text("Kısa bir reklam izle", style: TextStyle(color: Colors.black87, fontSize: 12))
                  ])
                ]),
              ),
            ),
            const SizedBox(height: 15),

            // Eşyalar Listesi
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("🎒 Eşyalar & Petler", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold))),
                    
                    _marketListTile(
                      icon: "🥚", baslik: "Gizemli Yumurta", 
                      aciklama: game.yumurtaVar ? "Çantanda, çatlatmayı bekle." : (game.petAcildi ? "Zaten bir petin var!" : "İçinden sürpriz pet çıkar!"), 
                      fiyat: 1000, satinAlindi: game.yumurtaVar || game.petAcildi, 
                      ozelDurumText: game.yumurtaVar ? "ÇANTADA" : (game.petAcildi ? "SAHİPSİN" : null),
                      islem: () { 
                        if (game.altinHarca(1000)) { 
                          game.yumurtaVar = true; game.verileriKaydet(); game.notifyListeners();
                          _mesajGoster(context, "Yumurta Alındı!"); 
                        } else { _mesajGoster(context, "Para Yok"); } 
                      }
                    ),
                    
                    if (game.petAcildi) 
                      _marketListTile(
                        icon: "🐾", baslik: "Pet Yemi", aciklama: "Seviye Atlat (+1 Güç)", 
                        fiyat: 500, satinAlindi: false, 
                        islem: () { 
                          if (game.altinHarca(500)) { 
                            game.petLevel++; game.verileriKaydet(); game.notifyListeners();
                            _mesajGoster(context, "Yoldaş Büyüdü!"); 
                          } else { _mesajGoster(context, "Para Yok"); } 
                        }
                      ),

                    _marketListTile(
                      icon: "🛡️", baslik: "XP Kalkanı", aciklama: "Kalıcı 2x XP Kazancı", 
                      fiyat: 500, satinAlindi: game.xpKalkaniVar, 
                      ozelDurumText: game.xpKalkaniVar ? "AKTİF" : null, 
                      islem: () { 
                        if (game.altinHarca(500)) { 
                          game.xpKalkaniVar = true; game.verileriKaydet(); game.notifyListeners();
                          _mesajGoster(context, "Kalkan Alındı!"); 
                        } else { _mesajGoster(context, "Yetersiz Altın"); } 
                      }
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Market Satır Tasarımı (Bileşenleştirilmiş hali)
  Widget _marketListTile({required String icon, required String baslik, required String aciklama, required int fiyat, required bool satinAlindi, required VoidCallback islem, String? ozelDurumText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 24)), 
        title: Text(baslik, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)), 
        subtitle: Text(aciklama, style: const TextStyle(fontSize: 10, color: Colors.white54)), 
        trailing: ElevatedButton(
          onPressed: satinAlindi ? null : islem, 
          style: ElevatedButton.styleFrom(backgroundColor: satinAlindi ? Colors.grey.withOpacity(0.2) : Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 10)), 
          child: Text(ozelDurumText ?? "$fiyat G", style: TextStyle(color: satinAlindi ? Colors.white54 : Colors.black, fontSize: 12, fontWeight: FontWeight.bold))
        )
      ) 
    );
  }
}