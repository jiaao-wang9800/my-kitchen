// lib/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // NEW: Import for panel text
import '../models/app_models.dart';
import '../data/mock_database.dart';
import 'category_manager_screen.dart';

// NEW Sorting enum
enum InventorySortOption { addedDate, expirationDate, category }

// ==========================================
// STARDEW UI DECORATOR PANEL (Pure Code Simulation)
// ==========================================
class StardewPanelContainer extends StatelessWidget {
  final Widget child;
  const StardewPanelContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Colors from lib/main.dart palette
    const Color darkWood = Color(0xFF5D3C1A);
    const Color mediumWood = Color(0xFF966C3D);
    const Color parchmentWarm = Color(0xFFF2E2C2);
    const Color outlineColor = Color(0xFF3E2723);

    return Container(
      // This is the wooden frame panel logic from image 10
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(2.0), // Tiny gap for pixel precision
      decoration: BoxDecoration(
        color: mediumWood, // The title bar wood
        border: Border.all(color: darkWood, width: 4.0), // The thick main frame
      ),
      child: Column(
        children: [
          // Simulated Title Bar (The [meat] or [vegetables] line from image 10)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: mediumWood,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book, size: 16, color: darkWood), // Tiny swirl analog
                const SizedBox(width: 8),
                Text('[kitchen inventory]', style: GoogleFonts.vt323(fontSize: 18, color: darkWood, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.menu_book, size: 16, color: darkWood), // Tiny swirl analog
              ],
            ),
          ),
          // Pure Stardew Parchment Content Area
          Expanded(
            child: Container(
              color: parchmentWarm,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Stardew Colors
    const Color darkWood = Color(0xFF5D3C1A);
    const Color parchmentWarm = Color(0xFFF2E2C2);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: darkWood, // <--- 改成 backgroundColor
        appBar: AppBar(
          title: const Text('My Kitchen'),
          actions: [
            IconButton(icon: const Icon(Icons.category), tooltip: 'Manage Categories', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryManagerScreen())))
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: darkWood,
            indicatorColor: parchmentWarm,
            tabs: [
              Tab(icon: Icon(Icons.kitchen), text: 'Fridge'),
              Tab(icon: Icon(Icons.ac_unit), text: 'Freezer'),
              Tab(icon: Icon(Icons.shelves), text: 'Cupboard'),
              Tab(icon: Icon(Icons.local_dining), text: 'Spices'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LocationTab(location: StorageLocation.fridge),
            LocationTab(location: StorageLocation.freezer),
            LocationTab(location: StorageLocation.cupboard),
            LocationTab(location: StorageLocation.spices),
          ],
        ),
      ),
    );
  }
}

class LocationTab extends StatefulWidget {
  final StorageLocation location;
  const LocationTab({super.key, required this.location});
  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {
  InventorySortOption _currentSort = InventorySortOption.addedDate;

  List<Ingredient> get sortedIngredients {
    List<String> validCategoryIds = allCategories.where((c) => c.location == widget.location).map((c) => c.id).toList();
    List<Ingredient> items = myInventory.where((i) => validCategoryIds.contains(i.categoryId) && i.inStock).toList();

    switch (_currentSort) {
      case InventorySortOption.addedDate: items.sort((a, b) => b.addedDate.compareTo(a.addedDate)); break;
      case InventorySortOption.expirationDate: items.sort((a, b) { if (a.expirationDate == null && b.expirationDate == null) return 0; if (a.expirationDate == null) return 1; if (b.expirationDate == null) return -1; return a.expirationDate!.compareTo(b.expirationDate!); }); break;
      case InventorySortOption.category: items.sort((a, b) { final catA = allCategories.firstWhere((c) => c.id == a.categoryId).name; final catB = allCategories.firstWhere((c) => c.id == b.categoryId).name; return catA.compareTo(catB); }); break;
    }
    return items;
  }

  Future<Recipe?> _showQuickAddRecipeDialog() async {
    final nameCtrl = TextEditingController();
    return showDialog<Recipe>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Recipe'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Recipe Name (e.g. Pasta)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { if (nameCtrl.text.isNotEmpty) Navigator.pop(context, Recipe(id: generateId(), name: nameCtrl.text, ingredientIds: [])); }, child: const Text('Create')),
        ],
      ),
    );
  }

  void _showIngredientDialog({Ingredient? existingIngredient}) {
    final bool isEdit = existingIngredient != null;
    final nameController = TextEditingController(text: isEdit ? existingIngredient.name : '');
    List<IngredientCategory> availableCategories = allCategories.where((c) => c.location == widget.location).toList();
    
    String? selectedCategoryId;
    if (isEdit) selectedCategoryId = existingIngredient.categoryId;
    else if (availableCategories.isNotEmpty) selectedCategoryId = availableCategories.first.id;
    DateTime? selectedExpirationDate = isEdit ? existingIngredient.expirationDate : null;
    List<String> linkedRecipeIds = [];
    if (isEdit) linkedRecipeIds = allRecipes.where((r) => r.ingredientIds.contains(existingIngredient.id)).map((r) => r.id).toList();
    String recipeSearchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredRecipes = allRecipes.where((r) => r.name.toLowerCase().contains(recipeSearchQuery.toLowerCase())).toList();
            return AlertDialog(
              title: Text(isEdit ? 'Edit Ingredient' : 'Add to ${widget.location.displayName}'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ingredient Name')),
                      const SizedBox(height: 16),
                      const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                      availableCategories.isEmpty ? const Text('Please create a category first.', style: TextStyle(color: Colors.red)) : DropdownButtonFormField<String>(initialValue: selectedCategoryId, items: availableCategories.map((cat) => DropdownMenuItem<String>(value: cat.id, child: Text(cat.name))).toList(), onChanged: (val) => setDialogState(() => selectedCategoryId = val)),
                      const SizedBox(height: 16), 
                      const Text('Expiration Date (Optional):', style: TextStyle(fontWeight: FontWeight.bold)),
                      Card(
                        margin: const EdgeInsets.only(top: 8.0),
                        elevation: 0,
                        color: Colors.grey[200],
                        child: ListTile(
                          title: Text(selectedExpirationDate == null ? 'No Date Set' : selectedExpirationDate!.toLocal().toString().split(' ')[0]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selectedExpirationDate != null)
                                IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: () => setDialogState(() => selectedExpirationDate = null)),
                              const Icon(Icons.calendar_today, color: Colors.teal),
                            ],
                          ),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedExpirationDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2050),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedExpirationDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Link to Recipes:', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('New'), onPressed: () async { final newRecipe = await _showQuickAddRecipeDialog(); if (newRecipe != null) setDialogState(() { allRecipes.add(newRecipe); linkedRecipeIds.add(newRecipe.id); }); }),
                        ],
                      ),
                      TextField(decoration: InputDecoration(hintText: 'Search recipes...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.all(8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: (val) => setDialogState(() => recipeSearchQuery = val)),
                      const SizedBox(height: 8),
                      if (allRecipes.isEmpty) const Padding(padding: EdgeInsets.all(8.0), child: Text('No recipes available.')) else if (filteredRecipes.isEmpty) const Padding(padding: EdgeInsets.all(8.0), child: Text('No recipes match.')) else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filteredRecipes.length, itemBuilder: (context, index) {
                        final recipe = filteredRecipes[index];
                        return CheckboxListTile(title: Text(recipe.name), value: linkedRecipeIds.contains(recipe.id), dense: true, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, onChanged: (bool? value) { setDialogState(() { value == true ? linkedRecipeIds.add(recipe.id) : linkedRecipeIds.remove(recipe.id); }); });
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: availableCategories.isEmpty ? null : () {
                    String currentIngId = isEdit ? existingIngredient.id : generateId();
                    setState(() {
                      if (isEdit) {
                        existingIngredient.name = nameController.text; existingIngredient.categoryId = selectedCategoryId!; existingIngredient.expirationDate = selectedExpirationDate;
                      } else {
                        myInventory.add(Ingredient(id: currentIngId, name: nameController.text, categoryId: selectedCategoryId!, inStock: true, addedDate: DateTime.now(), expirationDate: selectedExpirationDate));
                      }
                      for (var recipe in allRecipes) {
                        linkedRecipeIds.contains(recipe.id) ? {if (!recipe.ingredientIds.contains(currentIngId)) recipe.ingredientIds.add(currentIngId)} : recipe.ingredientIds.remove(currentIngId);
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _consumeIngredient(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Consumed!'),
        content: Text('You finished ${ingredient.name}.'),
        actions: [
          TextButton(onPressed: () { setState(() => ingredient.inStock = false); Navigator.pop(c); }, child: const Text('Yes')),
        ],
      ),
    );
  }

  void _deleteIngredient(Ingredient ingredient) {
    setState(() {
      myInventory.remove(ingredient);
      for (var recipe in allRecipes) recipe.ingredientIds.remove(ingredient.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = sortedIngredients;
    const Color darkWood = Color(0xFF5D3C1A); // libel to main dark wood
    const Color gold = Color(0xFFD4A745);

    // ==========================================
    // STARDEW UI WRAPPER: Wrapping the whole content in the Panel
    // ==========================================
    return StardewPanelContainer(
      child: Column(
        children: [
          // Sorting Toolbar (Refined Colors)
          Container(
            color: const Color(0xFF966C3D), // libel medium Wood
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sort:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: gold)),
                DropdownButton<InventorySortOption>(
                  value: _currentSort,
                  dropdownColor: const Color(0xFF966C3D),
                  iconEnabledColor: gold,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: InventorySortOption.addedDate, child: Text('Added', style: TextStyle(color: gold))),
                    DropdownMenuItem(value: InventorySortOption.expirationDate, child: Text('Expires', style: TextStyle(color: gold))),
                    DropdownMenuItem(value: InventorySortOption.category, child: Text('Category', style: TextStyle(color: gold))),
                  ],
                  onChanged: (val) { if (val != null) setState(() => _currentSort = val); },
                ),
              ],
            ),
          ),
          
          // Item List
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('Empty ${widget.location.displayName}.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFFC7A26C)), // libel border between items
                    itemBuilder: (context, index) {
                      final ingredient = items[index];
                      final category = allCategories.firstWhere((c) => c.id == ingredient.categoryId);
                      bool isExpired = ingredient.expirationDate != null && ingredient.expirationDate!.isBefore(DateTime.now());

                      return ListTile(
                        dense: true,
                        title: Text(ingredient.name, style: GoogleFonts.vt323(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF513106))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.name, style: const TextStyle(fontSize: 14)),
                            if (ingredient.expirationDate != null)
                              Text(
                                'Expires: ${ingredient.expirationDate!.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(color: isExpired ? Colors.red : Colors.grey[700], fontWeight: isExpired ? FontWeight.bold : FontWeight.normal),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.restaurant, color: Colors.green), tooltip: 'Mark as Consumed', onPressed: () => _consumeIngredient(ingredient)),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showIngredientDialog(existingIngredient: ingredient)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: 'Delete', onPressed: () => _deleteIngredient(ingredient)),
                          ],
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MatchedRecipesScreen(ingredient: ingredient))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MatchedRecipesScreen extends StatelessWidget {
  final Ingredient ingredient;
  const MatchedRecipesScreen({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final matchedRecipes = allRecipes.where((recipe) => recipe.ingredientIds.contains(ingredient.id)).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Recipes with ${ingredient.name}'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: matchedRecipes.isEmpty ? const Center(child: Text('No recipes found for this ingredient.')) : ListView.builder(
        itemCount: matchedRecipes.length,
        itemBuilder: (context, index) {
          final recipe = matchedRecipes[index];
          return ListTile(leading: const Icon(Icons.check_circle, color: Colors.teal), title: Text(recipe.name), subtitle: Text('${recipe.ingredientIds.length} ingredients required in total'));
        },
      ),
    );
  }
}