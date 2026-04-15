// lib/screens/shopping_cart_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';
import '../services/receipt_scanner_service.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  // NEW: State for loading overlay
  bool _isScanning = false;

  // ==========================================
  // 🌟 NEW: Smart AI Scanner Logic
  // ==========================================
  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    // Allow user to pick an image from the gallery (can also use ImageSource.camera)
    final XFile? image = await picker.pickImage(source: ImageSource.gallery); 
    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      final bytes = await image.readAsBytes();
      
      // 1. Call AI to parse the image
      // 1. Call AI to parse the image, PASSING our kitchen's existing categories
      final results = await ReceiptScannerService.scanGroceries(bytes, categories: allCategories);
      
      if (results.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未能识别到食材，请换一张清晰的照片试试。')));
        return;
      }

      int processedCount = 0;
      int matchedCartCount = 0;

      // 2. Process each AI-detected ingredient
      for (var item in results) {
        final name = item['name'] as String;
        final amount = item['amount'] as double;
        final unit = item['unit'] as String;
        final group = item['group'] as DietaryGroup;
        final shelfLifeDays = item['shelfLifeDays'] as int;
        
        // 🌟 NEW: Get the exact category ID chosen by the AI
        final aiCategoryId = item['categoryId'] as String?;

        // Step 2.1: Smart Inventory Update
        var existingIng = myInventory.where((i) => 
          i.name.toLowerCase() == name.toLowerCase() || 
          i.name.contains(name) || 
          name.contains(i.name)
        ).firstOrNull;
        
        String targetIngId;

        if (existingIng != null) {
          existingIng.inStock = true;
          existingIng.numericAmount = (existingIng.numericAmount ?? 0) + amount;
          existingIng.unit = unit; // Always enforce the standard unit
          existingIng.dietaryGroup = group;
          existingIng.dietarySubGroup = item['subGroup'];
          existingIng.caloriesPer100g = item['cal'];
          existingIng.proteinPer100g = item['pro'];
          existingIng.carbsPer100g = item['carb'];
          existingIng.fatPer100g = item['fat'];
          existingIng.nutritionalTags = item['tags'];
          
          // Optionally update category if AI found a better match, or keep existing. We keep existing here.
          existingIng.expirationDate = DateTime.now().add(Duration(days: shelfLifeDays));
          existingIng.isAiAnalyzing = false;
          await existingIng.save();
          targetIngId = existingIng.id;
        } else {
          // 🌟 NEW: Create entirely new ingredient using the AI's selected Category ID
          // Fallback to the first category if AI failed to match one
          final finalCategoryId = (aiCategoryId != null && allCategories.any((c) => c.id == aiCategoryId)) 
              ? aiCategoryId 
              : (allCategories.firstOrNull?.id ?? 'default');

          final newIng = Ingredient(
            id: generateId(),
            name: name,
            categoryId: finalCategoryId, // Assigned properly!
            inStock: true,
            numericAmount: amount,
            unit: unit, // Assured to be g, ml, or 个
            dietaryGroup: group,
            dietarySubGroup: item['subGroup'],
            caloriesPer100g: item['cal'],
            proteinPer100g: item['pro'],
            carbsPer100g: item['carb'],
            fatPer100g: item['fat'],
            nutritionalTags: item['tags'],
            expirationDate: DateTime.now().add(Duration(days: shelfLifeDays)),
            isAiAnalyzing: false, 
          );
          await inventoryBox.put(newIng.id, newIng);
          targetIngId = newIng.id;
        }
        
        processedCount++;

        // Step 2.2: Smart Cart Clear (Fuzzy match with unpurchased items)
        final unpurchasedCartItems = myShoppingCart.where((i) => !i.isPurchased).toList();
        for (var cartItem in unpurchasedCartItems) {
          final cartIng = inventoryBox.get(cartItem.ingredientId);
          if (cartIng != null) {
            // Check if the cart item matches the AI scanned item
            if (cartIng.id == targetIngId || cartIng.name.contains(name) || name.contains(cartIng.name)) {
              cartItem.isPurchased = true; // Mark as bought!
              cartIng.inStock = true;
              await cartItem.save();
              await cartIng.save();
              matchedCartCount++;
            }
          }
        }
      }

      // 3. Refresh UI and show summary
      setState(() => syncMemoryWithHive());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 扫描完成！入库 $processedCount 项食材，自动划去购物车 $matchedCartCount 项！'),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 4),
          )
        );
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('扫描失败: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // ==========================================
  // OLD MANUAL ADD LOGIC
  // ==========================================
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
                  TextField(
                    controller: nameCtrl, 
                    decoration: const InputDecoration(labelText: 'Ingredient Name'),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category (For Kitchen)'),
                    items: allCategories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                    onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: (selectedCategoryId == null || nameCtrl.text.isEmpty) ? null : () async {
                    final newIng = Ingredient(id: generateId(), name: nameCtrl.text, categoryId: selectedCategoryId!, inStock: false);
                    await inventoryBox.put(newIng.id, newIng);
                    
                    final newItem = ShoppingItem(id: generateId(), ingredientId: newIng.id, groupName: '🛒 手动添加');
                    await shoppingCartBox.put(newItem.id, newItem);
                    
                    setState(() => syncMemoryWithHive());
                    if (context.mounted) Navigator.pop(context);
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
    Map<String, List<ShoppingItem>> calendarGroups = {};
    Map<String, List<ShoppingItem>> manualGroups = {};

    for (var item in myShoppingCart) {
      if (item.mealPlanId != null) {
        String group = item.groupName ?? '📅 计划所需';
        calendarGroups.putIfAbsent(group, () => []).add(item);
      } else {
        String group = item.groupName ?? '🛒 其他';
        manualGroups.putIfAbsent(group, () => []).add(item);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Clear Purchased',
            onPressed: () async {
              final purchasedItems = shoppingCartBox.values.where((item) => item.isPurchased).toList();
              for (var item in purchasedItems) {
                await item.delete(); 
              }
              setState(() => syncMemoryWithHive());
            },
          )
        ],
      ),
      // 🌟 NEW: Wrapped body in a Stack to overlay the Loading UI during AI scan
      body: Stack(
        children: [
          myShoppingCart.isEmpty
              ? const Center(child: Text('Your cart is empty. Go plan some meals!'))
              : ListView(
                  children: [
                    if (calendarGroups.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('来自日历计划', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                      ),
                      ...calendarGroups.entries.map((entry) => _buildGroup(entry.key, entry.value, isCalendar: true)),
                    ],

                    if (manualGroups.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.shopping_bag, size: 18, color: Colors.teal),
                            SizedBox(width: 8),
                            Text('手动添加 / 补货', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                      ),
                      ...manualGroups.entries.map((entry) => _buildGroup(entry.key, entry.value, isCalendar: false)),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
          
          // 🌟 NEW: Blocking Loading Overlay when AI is running
          if (_isScanning)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.teal),
                      SizedBox(height: 16),
                      Text('AI 正在清点小票并核销购物车...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      
      // 🌟 NEW: Expanded FAB layout for both actions
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 1. Smart Scanner Button
          FloatingActionButton.extended(
            heroTag: 'scan_btn',
            onPressed: _isScanning ? null : _scanReceipt,
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.document_scanner, color: Colors.white),
            label: const Text('智能小票入库', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          // 2. Manual Add Button
          FloatingActionButton(
            heroTag: 'manual_add_btn',
            onPressed: _showAddManualItemDialog,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<ShoppingItem> items, {required bool isCalendar}) {
    return ExpansionTile(
      initiallyExpanded: true,
      shape: const Border(),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isCalendar ? Colors.orange[800] : Colors.teal[800], fontSize: 16)),
      children: items.map((cartItem) {
        final ingredient = myInventory.where((ing) => ing.id == cartItem.ingredientId).firstOrNull;
        if (ingredient == null) return const SizedBox.shrink();

        return CheckboxListTile(
          title: Text(
            ingredient.name,
            style: TextStyle(
              decoration: cartItem.isPurchased ? TextDecoration.lineThrough : null,
              color: cartItem.isPurchased ? Colors.grey : null, 
              fontSize: 18,
            ),
          ),
          subtitle: isCalendar ? const Text('自动同步', style: TextStyle(fontSize: 10, color: Colors.grey)) : null,
          value: cartItem.isPurchased,
          activeColor: Colors.teal,
          onChanged: (bool? val) async {
            cartItem.isPurchased = val!;
            ingredient.inStock = val;
            await cartItem.save();
            await ingredient.save();
            setState(() => syncMemoryWithHive());
          },
          secondary: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () async {
              await cartItem.delete();
              setState(() => syncMemoryWithHive());
            },
          ),
        );
      }).toList(),
    );
  }
}