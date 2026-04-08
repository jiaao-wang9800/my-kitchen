// lib/screens/category_manager_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';

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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isEdit) {
                        existingCategory.name = nameController.text;
                        existingCategory.location = selectedLoc;
                      } else {
                        allCategories.add(IngredientCategory(
                          id: generateId(),
                          name: nameController.text,
                          location: selectedLoc,
                        ));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: ListView.builder(
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final cat = allCategories[index];
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(cat.name),
            subtitle: Text('Location: ${cat.location.displayName}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showCategoryDialog(existingCategory: cat),
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