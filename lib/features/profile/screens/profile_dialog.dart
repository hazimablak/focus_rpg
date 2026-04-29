import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/game_provider.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // 💎 Provider'ı dinliyoruz
    final game = context.watch<GameProvider>();

    return AlertDialog(
      backgroundColor: const Color(0xFF151522),
      title: const Text("👤 Kahraman Profili", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 40, 
            backgroundColor: Colors.amber, 
            child: Icon(Icons.person, size: 50, color: Colors.black)
          ),
          const SizedBox(height: 15),
          Text(
            "Seviye: ${game.level}", 
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.timer, color: Colors.cyanAccent), 
            title: const Text("Toplam Odak", style: TextStyle(color: Colors.white54)), 
            trailing: Text("${game.toplamOdakDakikasi} Dk", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.greenAccent), 
            title: const Text("Biten Görev", style: TextStyle(color: Colors.white54)), 
            trailing: Text("${game.tamamlananGorevSayisi}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Kapat", style: TextStyle(color: Colors.amber))
        )
      ],
    );
  }
}