// lib/screens/main_tab_screen.dart
import 'package:flutter/material.dart';
// Note: We removed the global AppBar, so we no longer need to import main.dart here
import 'inventory_screen.dart';
import 'recipe_list_screenq.dart';
import 'calendar_screen.dart';
import 'shopping_cart_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});
  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const InventoryScreen(),
      const RecipeListScreen(),
      const CalendarScreen(),
      const ShoppingCartScreen(),
    ];

    return Scaffold(
      // FIXED: Removed the global AppBar to prevent double headers.
      // The child screens will provide their own AppBars.
      body: screens[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, 
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Kitchen'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}