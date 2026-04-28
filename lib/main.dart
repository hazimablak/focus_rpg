import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Kendi oluşturduğumuz dosyalar
import 'core/providers/game_provider.dart';
import 'features/home/screens/ana_oyun_ekrani.dart'; 

void main() {
  // Flutter motorunun hazır olduğundan emin oluyoruz
  WidgetsFlutterBinding.ensureInitialized();
  
  // Üst barı (Status Bar) şeffaf ve şık yapıyoruz
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  // Reklam servisini başlatıyoruz
  if (Platform.isAndroid || Platform.isIOS) {
    MobileAds.instance.initialize();
  }
  
  runApp(
    // Uygulamanın en tepesine "Beyni" (GameProvider) yerleştiriyoruz
    // Böylece her sayfadan altın, xp gibi verilere ulaşabileceğiz.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameProvider()),
      ],
      child: const FocusRPGApp(),
    ),
  );
}

class FocusRPGApp extends StatelessWidget {
  const FocusRPGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus Hero',
      
      // Profesyonel Tema Ayarları
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF151522),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'PixelFont'),
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.cyanAccent,
        ),
        // Slider ve Input gibi bileşenlerin genel görünümleri
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.always,
          activeTrackColor: Colors.amber,
          thumbColor: Colors.amber,
        ),
      ),
      
      // Uygulama açıldığında gideceği ana sayfa
      // Not: Bu dosya henüz oluşturulmadıysa hata verebilir, şimdi onu oluşturacağız.
      home: const AnaOyunEkrani(), 
    );
  }
}