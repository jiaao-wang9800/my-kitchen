// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:hive_flutter/hive_flutter.dart'; // NEW: Import Hive
import 'models/app_models.dart'; // NEW: Import your models
import 'data/mock_database.dart'; // NEW: Import database initialization
import 'screens/main_tab_screen.dart';

final ValueNotifier<bool> isStardewTheme = ValueNotifier<bool>(false);

void main() async {
  // Ensure Flutter engine is fully initialized before async database calls
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter
  await Hive.initFlutter();

  // Register all auto-generated TypeAdapters
  Hive.registerAdapter(StorageLocationAdapter());
  Hive.registerAdapter(IngredientCategoryAdapter());
  Hive.registerAdapter(IngredientAdapter());
  Hive.registerAdapter(RecipeCategoryAdapter());
  Hive.registerAdapter(RecipeAdapter());
  Hive.registerAdapter(MealTypeAdapter());
  Hive.registerAdapter(MealPlanAdapter());
  Hive.registerAdapter(ShoppingItemAdapter());
  Hive.registerAdapter(RecipeIngredientAdapter());
  // Open the actual database boxes
  await initDatabase();

  runApp(const SmartRecipeApp());
}

class SmartRecipeApp extends StatelessWidget {
  const SmartRecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isStardewTheme,
      builder: (context, isStardew, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Recipe Manager',
          theme: isStardew ? _buildStardewTheme() : _buildModernTheme(),
          home: const MainTabScreen(),
        );
      },
    );
  }

  // ==========================================
  // THEME A: STARDEW VALLEY (Pixel Art)
  // ==========================================
  ThemeData _buildStardewTheme() {
    const Color darkWood = Color(0xFF5D3C1A);
    const Color mediumWood = Color(0xFF966C3D);
    const Color parchmentWarm = Color(0xFFF2E2C2);
    const Color outlineColor = Color(0xFF3E2723);
    const Color coinGold = Color(0xFFD4A745);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkWood,
      textTheme: GoogleFonts.vt323TextTheme().apply(bodyColor: outlineColor, displayColor: outlineColor),
      appBarTheme: AppBarTheme(
        backgroundColor: mediumWood,
        titleTextStyle: GoogleFonts.vt323(fontSize: 32, color: coinGold, shadows: [const Shadow(offset: Offset(2, 2), color: outlineColor)]),
        iconTheme: const IconThemeData(color: coinGold),
        shape: const Border(bottom: BorderSide(color: outlineColor, width: 4)),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: outlineColor, width: 3)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: parchmentWarm,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: darkWood, width: 6)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: mediumWood,
        selectedItemColor: coinGold,
        unselectedItemColor: darkWood,
      ),
      extensions: const [ThemeModeExtension(isStardew: true)],
    );
  }

  // ==========================================
  // THEME B: MODERN MINIMALIST (Clean & Crisp)
  // ==========================================
  ThemeData _buildModernTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.teal,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: GoogleFonts.interTextTheme(), 
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.teal,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
      extensions: const [ThemeModeExtension(isStardew: false)],
    );
  }
}

class ThemeModeExtension extends ThemeExtension<ThemeModeExtension> {
  final bool isStardew;
  const ThemeModeExtension({required this.isStardew});

  @override
  ThemeExtension<ThemeModeExtension> copyWith({bool? isStardew}) => ThemeModeExtension(isStardew: isStardew ?? this.isStardew);

  @override
  ThemeExtension<ThemeModeExtension> lerp(ThemeExtension<ThemeModeExtension>? other, double t) => this;
}