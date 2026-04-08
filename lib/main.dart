// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'screens/main_tab_screen.dart';

void main() {
  runApp(const SmartRecipeApp());
}

class SmartRecipeApp extends StatelessWidget {
  const SmartRecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // DEEP STARDEW PALETTE (Based on Image 10)
    // ==========================================
    const Color darkWood = Color(0xFF5D3C1A);     // Image 10's darkest frame brown
    const Color mediumWood = Color(0xFF966C3D);   // The light-wood title bar brown
    const Color parchmentWarm = Color(0xFFF2E2C2); // The core parchment beige
    const Color outlineColor = Color(0xFF3E2723); // Super dark outline
    const Color coinGold = Color(0xFFD4A745);     // Stardew coin gold
    const Color stardewGreen = Color(0xFF4CAF50); // Farm green

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stardew Kitchen',
      // ==========================================
      // GLOBAL THEME ENGINE (Deeply Stardew-ized)
      // ==========================================
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: darkWood, // Background of screen should be dark wood
        colorScheme: ColorScheme.fromSeed(
          seedColor: stardewGreen,
          primary: darkWood,
          secondary: mediumWood,
          surface: parchmentWarm,
        ),
        
        // Pixel Art Font
        textTheme: GoogleFonts.vt323TextTheme(Theme.of(context).textTheme).apply(
          bodyColor: outlineColor,
          displayColor: outlineColor,
        ),
        
        // 1. APP BAR: Signboard with golden text and wood cap
        appBarTheme: AppBarTheme(
          backgroundColor: mediumWood, // Title background
          elevation: 0,
          shape: const Border(bottom: BorderSide(color: outlineColor, width: 4)),
          iconTheme: const IconThemeData(color: coinGold, size: 28),
          titleTextStyle: GoogleFonts.vt323(
            fontSize: 32, 
            fontWeight: FontWeight.bold, 
            color: coinGold, // Stardew title gold
            shadows: [const Shadow(offset: Offset(2, 2), color: outlineColor)]
          ),
        ),
        
        // 2. DIALOGS (Menus): Look like the large panel in image 10
        dialogTheme: DialogThemeData(
          backgroundColor: parchmentWarm,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: darkWood, width: 6), // Deep wood frame
          ),
          titleTextStyle: GoogleFonts.vt323(fontSize: 28, fontWeight: FontWeight.bold, color: darkWood),
        ),
        
        // 3. BOTTOM NAVIGATION BAR
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: mediumWood,
          selectedItemColor: coinGold, // Golden selected icon
          unselectedItemColor: darkWood,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 0,
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}