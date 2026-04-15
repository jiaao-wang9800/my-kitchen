// lib/screens/category_manager_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';
import '../main.dart'; // <--- NEW: Insert this to access isStardewTheme

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  void _showCategoryDialog({IngredientCategory? existingCategory}) {
    final bool isEdit = existingCategory != null;
    final nameController = TextEditingController(text: isEdit ? existingCategory.name : '');
    StorageLocation selectedLoc = isEdit ? existingCategory.location : StorageLocation.fridge;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Category' : 'New Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<StorageLocation>(
                    value: selectedLoc,
                    decoration: const InputDecoration(labelText: 'Store In'),
                    items: StorageLocation.values.map((loc) {
                      return DropdownMenuItem(value: loc, child: Text(loc.displayName));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedLoc = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
// REPLACE the ElevatedButton in _showCategoryDialog actions
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return; // Basic validation
                    
                    if (isEdit) {
                      existingCategory.name = nameController.text;
                      existingCategory.location = selectedLoc;
                      await existingCategory.save(); // HIVE: Save changes to disk
                    } else {
                      final newCat = IngredientCategory(
                        id: generateId(),
                        name: nameController.text,
                        location: selectedLoc,
                      );
                      await categoryBox.put(newCat.id, newCat); // HIVE: Save new category to disk
                    }
                    
                    setState(() => syncMemoryWithHive()); // SYNC
                    if (context.mounted) Navigator.pop(context);
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

  Future<void> _deleteCategory(IngredientCategory category) async {
    // HIVE: Delete category from disk completely
    await category.delete(); 
    
    // Note: If you want to be extremely safe, you could also find all ingredients 
    // that belong to this category and delete them or move them to a default category here.
    
    setState(() => syncMemoryWithHive());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // REPLACE the appBar inside Scaffold
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Theme support
        actions: [
          // Theme Toggle Button
          ValueListenableBuilder<bool>(
            valueListenable: isStardewTheme,
            builder: (context, isStardew, child) {
              return IconButton(
                icon: Icon(isStardew ? Icons.auto_awesome_motion : Icons.videogame_asset),
                tooltip: 'Switch Theme',
                onPressed: () => isStardewTheme.value = !isStardewTheme.value,
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final cat = allCategories[index];
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(cat.name),
            subtitle: Text('Location: ${cat.location.displayName}'),
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