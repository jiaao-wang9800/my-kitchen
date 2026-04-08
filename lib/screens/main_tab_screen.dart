// lib/screens/main_tab_screen.dart
import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'recipe_list_screen.dart';
import 'calendar_screen.dart';
import 'shopping_cart_screen.dart'; // NEW

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
      const ShoppingCartScreen(), // NEW
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, 
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'My Kitchen'), // Changed label!
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'), // NEW
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}