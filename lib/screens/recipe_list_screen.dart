// lib/screens/recipe_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

// ==========================================
// SCREEN 2: Recipe List
// ==========================================

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});
  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final ImagePicker _picker = ImagePicker();

  void _showRecipeDialog({Recipe? existingRecipe}) {
    final bool isEdit = existingRecipe != null;
    final nameController = TextEditingController(text: isEdit ? existingRecipe.name : '');
    List<String> selectedIngredientIds = isEdit ? List.from(existingRecipe.ingredientIds) : [];
    List<String> steps = isEdit ? List.from(existingRecipe.steps) : [];
    List<String> selectedRecipeCatIds = isEdit ? List.from(existingRecipe.categoryIds) : []; 
    String? selectedImagePath = isEdit ? existingRecipe.imagePath : null;
    final newStepController = TextEditingController();
    String ingredientSearchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredIngredients = myInventory.where((ing) => ing.name.toLowerCase().contains(ingredientSearchQuery.toLowerCase())).toList();
            return AlertDialog(
              title: Text(isEdit ? 'Edit Recipe' : 'Add Recipe'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: GestureDetector(onTap: () async { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) setDialogState(() => selectedImagePath = image.path); }, child: Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), image: selectedImagePath != null ? DecorationImage(image: FileImage(File(selectedImagePath!)), fit: BoxFit.cover) : null), child: selectedImagePath == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), SizedBox(height: 8), Text('Tap to add photo', style: TextStyle(color: Colors.grey))]) : null))),
                      const SizedBox(height: 16),
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Recipe Name', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      const Text('Tags / Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(spacing: 8.0, children: allRecipeCategories.map((cat) { return FilterChip(label: Text(cat.name), selected: selectedRecipeCatIds.contains(cat.id), selectedColor: Colors.teal.withValues(alpha: 0.3), onSelected: (bool selected) { setDialogState(() { selected ? selectedRecipeCatIds.add(cat.id) : selectedRecipeCatIds.remove(cat.id); }); }); }).toList()),
                      const Divider(),
                      const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(decoration: InputDecoration(hintText: 'Search ingredients...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.all(8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: (val) => setDialogState(() => ingredientSearchQuery = val)),
                      const SizedBox(height: 8),
                      myInventory.isEmpty ? const Text('No ingredients in inventory.', style: TextStyle(color: Colors.red)) : filteredIngredients.isEmpty ? const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('No matching ingredients found.')) : ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filteredIngredients.length, itemBuilder: (context, index) {
                        final ingredient = filteredIngredients[index];
                        return CheckboxListTile(title: Text(ingredient.name), value: selectedIngredientIds.contains(ingredient.id), dense: true, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, onChanged: (bool? value) { setDialogState(() { value == true ? selectedIngredientIds.add(ingredient.id) : selectedIngredientIds.remove(ingredient.id); }); });
                      }),
                      const Divider(),
                      const Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: steps.length, itemBuilder: (context, index) { return ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: CircleAvatar(radius: 12, child: Text('${index + 1}', style: const TextStyle(fontSize: 12))), title: Text(steps[index]), trailing: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20), onPressed: () => setDialogState(() => steps.removeAt(index)))); }),
                      Row(children: [Expanded(child: TextField(controller: newStepController, decoration: const InputDecoration(hintText: 'Add a step...', isDense: true))), IconButton(icon: const Icon(Icons.add_circle, color: Colors.teal), onPressed: () { if (newStepController.text.isNotEmpty) { setDialogState(() { steps.add(newStepController.text); newStepController.clear(); }); } })]),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(onPressed: () { setState(() { if (isEdit) { existingRecipe.name = nameController.text; existingRecipe.ingredientIds = selectedIngredientIds; existingRecipe.steps = steps; existingRecipe.imagePath = selectedImagePath; existingRecipe.categoryIds = selectedRecipeCatIds; } else { allRecipes.add(Recipe(id: generateId(), name: nameController.text, ingredientIds: selectedIngredientIds, steps: steps, imagePath: selectedImagePath, categoryIds: selectedRecipeCatIds)); } }); Navigator.pop(context); }, child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteRecipe(Recipe recipe) => setState(() => allRecipes.remove(recipe));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Recipes'), 
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // NEW: Button to open Recipe Category Manager
          IconButton(
            icon: const Icon(Icons.label),
            tooltip: 'Manage Recipe Tags',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RecipeCategoryManagerScreen()));
            },
          )
        ],
      ),
      body: allRecipes.isEmpty ? const Center(child: Text('No recipes yet. Tap + to add one!')) : ListView.builder(
        itemCount: allRecipes.length,
        itemBuilder: (context, index) {
          final recipe = allRecipes[index];
          String tagsText = recipe.categoryIds.map((id) => allRecipeCategories.firstWhere((cat) => cat.id == id).name).join(', ');
          
          // NEW: Calculate missing ingredients directly in the list
          final allRequired = myInventory.where((ing) => recipe.ingredientIds.contains(ing.id)).toList();
          final missingIngredients = allRequired.where((ing) => !ing.inStock).toList();

          return ListTile(
            leading: recipe.imagePath != null ? CircleAvatar(backgroundImage: FileImage(File(recipe.imagePath!))) : const CircleAvatar(child: Icon(Icons.restaurant)),
            title: Text(recipe.name), 
            subtitle: Text(tagsText.isEmpty ? 'No tags' : tagsText, style: const TextStyle(color: Colors.teal)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                // NEW: Quick Add to Cart button right on the list tile
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.orange), 
                  tooltip: 'Add missing ingredients to cart',
                  onPressed: () {
                    if (missingIngredients.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have all ingredients!')));
                      return;
                    }
                    setState(() {
                      for (var ing in missingIngredients) {
                        if (!myShoppingCart.any((item) => item.ingredientId == ing.id && !item.isPurchased)) {
                          myShoppingCart.add(ShoppingItem(id: generateId(), ingredientId: ing.id, groupName: recipe.name));
                        }
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added missing items for ${recipe.name} to Cart!')));
                  }
                ),
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showRecipeDialog(existingRecipe: recipe)), 
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRecipe(recipe))
              ]
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showRecipeDialog(), child: const Icon(Icons.add)),
    );
  }
}

// ==========================================
// Recipe Detail Screen (With Missing Analysis)
// ==========================================
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final allRequired = myInventory.where((ing) => widget.recipe.ingredientIds.contains(ing.id)).toList();
    final missingIngredients = allRequired.where((ing) => !ing.inStock).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.name), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.recipe.imagePath != null && widget.recipe.imagePath!.isNotEmpty) Image.file(File(widget.recipe.imagePath!), width: double.infinity, height: 250, fit: BoxFit.cover) else Container(width: double.infinity, height: 200, color: Colors.grey[300], child: const Icon(Icons.restaurant_menu, size: 80, color: Colors.grey)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ingredients', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (missingIngredients.isNotEmpty)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add Missing to Cart'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() {
                              for (var ing in missingIngredients) {
                                if (!myShoppingCart.any((item) => item.ingredientId == ing.id && !item.isPurchased)) {
                                  myShoppingCart.add(ShoppingItem(id: generateId(), ingredientId: ing.id, groupName: widget.recipe.name));
                                }
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Shopping Cart!')));
                          },
                        )
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (allRequired.isEmpty) const Text('No ingredients linked.') else ...allRequired.map((ing) {
                    bool isMissing = !ing.inStock;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0), 
                      child: Row(children: [
                        Icon(isMissing ? Icons.cancel : Icons.check_circle, size: 16, color: isMissing ? Colors.red : Colors.teal), 
                        const SizedBox(width: 8), 
                        Text(ing.name, style: TextStyle(fontSize: 16, color: isMissing ? Colors.red : Colors.black, decoration: isMissing ? TextDecoration.lineThrough : null)),
                        if (isMissing) const Text(' (Missing)', style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic))
                      ])
                    );
                  }),
                  const SizedBox(height: 24), const Divider(), const SizedBox(height: 16),
                  const Text('Instructions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (widget.recipe.steps.isEmpty) const Text('No steps added yet.') else ...widget.recipe.steps.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 14, backgroundColor: Colors.teal, child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 14))), const SizedBox(width: 12), Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 16, height: 1.4)))]))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ==========================================
// Recipe Category Manager Screen (Updated with Delete)
// ==========================================
class RecipeCategoryManagerScreen extends StatefulWidget {
  const RecipeCategoryManagerScreen({super.key});

  @override
  State<RecipeCategoryManagerScreen> createState() => _RecipeCategoryManagerScreenState();
}

class _RecipeCategoryManagerScreenState extends State<RecipeCategoryManagerScreen> {
  void _showCategoryDialog({RecipeCategory? existingCategory}) {
    final bool isEdit = existingCategory != null;
    final nameController = TextEditingController(text: isEdit ? existingCategory.name : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Tag' : 'New Tag'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Tag Name (e.g. Spicy, Vegan)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isEdit) {
                    existingCategory.name = nameController.text;
                  } else {
                    allRecipeCategories.add(RecipeCategory(id: generateId(), name: nameController.text));
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
  }

  // NEW: Method to cleanly delete a category
  void _deleteCategory(RecipeCategory category) {
    setState(() {
      // 1. Remove from the global list
      allRecipeCategories.remove(category);
      
      // 2. Remove this tag from any recipes that are currently using it
      for (var recipe in allRecipes) {
        recipe.categoryIds.remove(category.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Recipe Tags')),
      body: ListView.builder(
        itemCount: allRecipeCategories.length,
        itemBuilder: (context, index) {
          final cat = allRecipeCategories[index];
          return ListTile(
            leading: const Icon(Icons.label),
            title: Text(cat.name),
            // NEW: Expanded trailing section to include both Edit and Delete buttons
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showCategoryDialog(existingCategory: cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCategory(cat),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}