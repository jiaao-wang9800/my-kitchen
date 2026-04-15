import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

// ==========================================
// Recipe Category Manager Screen (保持原样)
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
          content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tag Name (e.g. Spicy, Vegan)')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                setState(() {
                  if (isEdit) { existingCategory.name = nameController.text; existingCategory.save(); } 
                  else { final newCat = RecipeCategory(id: generateId(), name: nameController.text); recipeCategoryBox.put(newCat.id, newCat); }
                  syncMemoryWithHive(); 
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

  void _deleteCategory(RecipeCategory category) {
    setState(() {
      category.delete(); 
      for (var recipe in allRecipes) { if (recipe.categoryIds.contains(category.id)) { recipe.categoryIds.remove(category.id); recipe.save(); } }
      syncMemoryWithHive(); 
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
            leading: const Icon(Icons.label), title: Text(cat.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCategoryDialog(existingCategory: cat)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(cat)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showCategoryDialog(), child: const Icon(Icons.add)),
    );
  }
}