// lib/screens/shopping_cart_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  
  void _showAddManualItemDialog() {
    final nameCtrl = TextEditingController();
    String? selectedCategoryId;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add to Cart'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ingredient Name')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category (Needed for Kitchen)'),
                    items: allCategories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                    onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: selectedCategoryId == null ? null : () {
                    setState(() {
                      // 1. Create it in the global catalog, but NOT in stock yet
                      final newIng = Ingredient(id: generateId(), name: nameCtrl.text, categoryId: selectedCategoryId!, inStock: false);
                      myInventory.add(newIng);
                      
                      // 2. Add it to the cart
                      myShoppingCart.add(ShoppingItem(id: generateId(), ingredientId: newIng.id, groupName: 'Manual Add'));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group items by their groupName (Recipe Name or Restock/Manual)
    Map<String, List<ShoppingItem>> groupedCart = {};
    for (var item in myShoppingCart) {
      String group = item.groupName ?? 'Others';
      groupedCart.putIfAbsent(group, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Clear Purchased',
            onPressed: () {
              setState(() => myShoppingCart.removeWhere((item) => item.isPurchased));
            },
          )
        ],
      ),
      body: myShoppingCart.isEmpty
          ? const Center(child: Text('Your cart is empty. Go plan some meals!'))
          : ListView(
              children: groupedCart.entries.map((entry) {
                return ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  children: entry.value.map((cartItem) {
                    // Find the actual ingredient info
                    final ingredient = myInventory.firstWhere((ing) => ing.id == cartItem.ingredientId);
                    
                    return CheckboxListTile(
                      title: Text(
                        ingredient.name,
                        style: TextStyle(
                          decoration: cartItem.isPurchased ? TextDecoration.lineThrough : null,
                          color: cartItem.isPurchased ? Colors.grey : Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      value: cartItem.isPurchased,
                      activeColor: Colors.grey,
                      onChanged: (bool? val) {
                        setState(() {
                          cartItem.isPurchased = val!;
                          // THE MAGIC: Automatically put it in My Kitchen if checked!
                          if (val == true) {
                            ingredient.inStock = true;
                          } else {
                            ingredient.inStock = false;
                          }
                        });
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() => myShoppingCart.remove(cartItem)),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddManualItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}