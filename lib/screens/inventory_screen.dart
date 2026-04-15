// lib/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../main.dart'; 
import '../models/app_models.dart';
import '../data/mock_database.dart';
import 'category_manager_screen.dart';
import '../services/ai_nutrition_service.dart'; // 你的 AI 大脑
import '../widgets/recipe_card.dart';
enum InventorySortOption { addedDate, expirationDate, category }

// ==========================================
// STARDEW UI DECORATOR PANEL (Reserved for future)
// ==========================================
class StardewPanelContainer extends StatelessWidget {
  final Widget child;
  const StardewPanelContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeExt = Theme.of(context).extension<ThemeModeExtension>();
    final bool isStardew = themeExt?.isStardew ?? true;

    if (!isStardew) return Container(color: Colors.white, child: child);

    const Color darkWood = Color(0xFF5D3C1A);
    const Color mediumWood = Color(0xFF966C3D);
    const Color parchmentWarm = Color(0xFFF2E2C2);

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(2.0), 
      decoration: BoxDecoration(color: mediumWood, border: Border.all(color: darkWood, width: 4.0)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: mediumWood,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book, size: 16, color: darkWood), 
                const SizedBox(width: 8),
                Text('[kitchen inventory]', style: GoogleFonts.vt323(fontSize: 18, color: darkWood, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.menu_book, size: 16, color: darkWood), 
              ],
            ),
          ),
          Expanded(child: Container(color: parchmentWarm, child: child)),
        ],
      ),
    );
  }
}

// ==========================================
// MODERN DUAL-PANE INVENTORY SCREEN
// ==========================================
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  StorageLocation _selectedLocation = StorageLocation.fridge;
  String? _selectedCategoryId;
  final ScrollController _rightScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setDefaultCategoryForLocation();
    
    // Future placeholder: Listen to scroll for bi-directional sync
    _rightScrollController.addListener(() {
      // In the future, calculate offset here to update _selectedCategoryId
    });
  }

  @override
  void dispose() {
    _rightScrollController.dispose();
    super.dispose();
  }

  void _setDefaultCategoryForLocation() {
    final categories = allCategories.where((c) => c.location == _selectedLocation).toList();
    if (categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    } else {
      _selectedCategoryId = null;
    }
  }

  // --- Dialogs & Actions (Migrated from LocationTab) ---
  
  void _showIngredientDialog({Ingredient? existingIngredient, String? defaultCategoryId}) {
    final bool isEdit = existingIngredient != null;
    
    // Core state variables for the form
    final nameController = TextEditingController(text: isEdit ? existingIngredient.name : '');
    final amountController = TextEditingController(text: isEdit && existingIngredient.numericAmount != null ? existingIngredient.numericAmount.toString() : ''); 
    
    StorageLocation selectedLoc = _selectedLocation;
    String? selectedCategoryId;
    
    if (isEdit) {
      final cat = allCategories.firstWhere((c) => c.id == existingIngredient.categoryId);
      selectedLoc = cat.location;
      selectedCategoryId = existingIngredient.categoryId;
    } else if (defaultCategoryId != null) {
      selectedCategoryId = defaultCategoryId;
    }

    String selectedUnit = isEdit && existingIngredient.unit != null ? existingIngredient.unit! : 'g';
    DateTime? selectedExpirationDate = isEdit ? existingIngredient.expirationDate : null;
    
    // RESTORED: Variables for explicit Recipe searching and linking
    List<String> linkedRecipeIds = [];
    if (isEdit) {
      // Find all recipes that currently include this ingredient
      linkedRecipeIds = allRecipes.where((r) => r.ingredients.any((ri) => ri.ingredientId == existingIngredient.id)).map((r) => r.id).toList();
    }
    String recipeSearchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableCategories = allCategories.where((c) => c.location == selectedLoc).toList();
            // Ensure a category is selected if available
            if (selectedCategoryId == null && availableCategories.isNotEmpty) {
              selectedCategoryId = availableCategories.first.id;
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(backgroundColor: Color(0xFF10C07B), radius: 12, child: Icon(Icons.add, color: Colors.white, size: 16)),
                              const SizedBox(width: 8),
                              Text(isEdit ? '编辑食材' : '入库新食材', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                          IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name Input
                      const Text('名称', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: '输入名称...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10C07B))),
                        ),
                        // FIXED: Removed the old onChanged listener that was causing the undefined errors
                      ),
                      const SizedBox(height: 20),

                      // Location and Category Linkage
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Large Location Button
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('位置', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<StorageLocation>(
                                      isExpanded: true,
                                      value: selectedLoc,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                      items: StorageLocation.values.map((loc) => DropdownMenuItem(value: loc, child: Text(loc.displayName, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                                      onChanged: (loc) {
                                        if (loc != null) {
                                          setModalState(() {
                                            selectedLoc = loc;
                                            final newCats = allCategories.where((c) => c.location == loc).toList();
                                            selectedCategoryId = newCats.isNotEmpty ? newCats.first.id : null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right: Category Chips
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('分类', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                availableCategories.isEmpty 
                                  ? const Text('该位置暂无分类', style: TextStyle(color: Colors.red, fontSize: 12))
                                  : Wrap(
                                      spacing: 8, runSpacing: 8,
                                      children: availableCategories.map((cat) {
                                        final isSel = selectedCategoryId == cat.id;
                                        return ChoiceChip(
                                          label: Text(cat.name),
                                          selected: isSel,
                                          selectedColor: const Color(0xFF10C07B).withValues(alpha: 0.1),
                                          labelStyle: TextStyle(color: isSel ? const Color(0xFF10C07B) : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                                          side: BorderSide(color: isSel ? const Color(0xFF10C07B) : Colors.grey.shade300),
                                          onSelected: (val) => setModalState(() => selectedCategoryId = cat.id),
                                        );
                                      }).toList(),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
// Quantity and Unit
                      const Text('数量与单位 (选填)', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // 1. Number Input
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '输入数量',
                                filled: true, fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10C07B))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 2. Segmented Unit Buttons
                          Expanded(
                            flex: 4, 
                            child: Container(
                              height: 48, // Matches the approximate height of the TextField
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: ['g', 'ml', '个'].map((u) {
                                  final isSel = selectedUnit == u;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setModalState(() => selectedUnit = u),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSel ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: isSel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                        ),
                                        margin: const EdgeInsets.all(3),
                                        alignment: Alignment.center,
                                        child: Text(
                                          u, 
                                          style: TextStyle(
                                            color: isSel ? const Color(0xFF10C07B) : Colors.grey.shade600, 
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal, 
                                            fontSize: 15
                                          )
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Smart Quick Add Buttons (Scrollable horizontally if screen is narrow)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickAddBtn('+1', amountController, setModalState),
                            const SizedBox(width: 8),
                            _buildQuickAddBtn('+5', amountController, setModalState),
                            const SizedBox(width: 8),
                            _buildQuickAddBtn('+50', amountController, setModalState),
                            const SizedBox(width: 8),
                            _buildQuickAddBtn('+100', amountController, setModalState),
                            const SizedBox(width: 8),
                            _buildQuickAddBtn('+500', amountController, setModalState),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Expiration Date
                      const Text('保质期 (选填)', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildQuickDateBtn('+3天', 3, setModalState, () => selectedExpirationDate = DateTime.now().add(const Duration(days: 3))),
                          const SizedBox(width: 8),
                          _buildQuickDateBtn('+1周', 7, setModalState, () => selectedExpirationDate = DateTime.now().add(const Duration(days: 7))),
                          const SizedBox(width: 8),
                          _buildQuickDateBtn('+1月', 30, setModalState, () => selectedExpirationDate = DateTime.now().add(const Duration(days: 30))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: selectedExpirationDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2050));
                          if (picked != null) setModalState(() => selectedExpirationDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedExpirationDate == null ? '年 / 月 / 日' : selectedExpirationDate!.toLocal().toString().split(' ')[0], style: TextStyle(color: selectedExpirationDate == null ? Colors.grey : Colors.black87, fontSize: 16)),
                              const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      

                      // RESTORED & REDESIGNED: Recipe Search Box
                      const Text('关联菜谱 (可选)', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: '搜索并关联已有菜谱...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                          filled: true, fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10C07B))),
                        ),
                        onChanged: (val) => setModalState(() => recipeSearchQuery = val),
                      ),
                      const SizedBox(height: 8),
                      
                      // Recipe Checklist
                      Builder(
                        builder: (context) {
                          final filteredRecipes = allRecipes.where((r) => r.name.toLowerCase().contains(recipeSearchQuery.toLowerCase())).toList();
                          
                          if (allRecipes.isEmpty) return const Text('暂无菜谱，请先去菜谱页添加', style: TextStyle(color: Colors.grey, fontSize: 12));
                          if (filteredRecipes.isEmpty) return const Text('未找到匹配的菜谱', style: TextStyle(color: Colors.grey, fontSize: 12));
                          
                          return Container(
                            constraints: const BoxConstraints(maxHeight: 160), // Limit height so it scrolls if too many
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = filteredRecipes[index];
                                return CheckboxListTile(
                                  title: Text(recipe.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  value: linkedRecipeIds.contains(recipe.id),
                                  activeColor: const Color(0xFF10C07B),
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  onChanged: (bool? value) {
                                    setModalState(() {
                                      if (value == true) {
                                        linkedRecipeIds.add(recipe.id);
                                      } else {
                                        linkedRecipeIds.remove(recipe.id);
                                      }
                                    });
                                  }
                                );
                              }
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10C07B), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入食材名称')));
                              return;
                            }
                            if (selectedCategoryId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先建立分类')));
                              return;
                            }

                            double? parsedAmt;
                            if (amountController.text.isNotEmpty) {
                              parsedAmt = double.tryParse(amountController.text);
                            }

                            String currentIngId = isEdit ? existingIngredient.id : generateId();
                            final inputName = nameController.text.trim();
                            
                            // 1. Save or Merge Ingredient
                            if (isEdit) {
                              // Normal edit logic
                              existingIngredient.name = inputName;
                              existingIngredient.categoryId = selectedCategoryId!;
                              existingIngredient.expirationDate = selectedExpirationDate;
                              existingIngredient.numericAmount = parsedAmt;
                              existingIngredient.unit = selectedUnit;
                              await existingIngredient.save();
                            } else {
                              // SMART DUPLICATE CHECK: Search entire DB (including out-of-stock items)
                              final existingMatch = inventoryBox.values.where(
                                (i) => i.name.trim().toLowerCase() == inputName.toLowerCase()
                              ).firstOrNull;

                              if (existingMatch != null) {
                                // Revive/Update the existing ingredient instead of cloning
                                existingMatch.inStock = true; // Bring it back to kitchen!
                                existingMatch.categoryId = selectedCategoryId!;
                                existingMatch.expirationDate = selectedExpirationDate;
                                existingMatch.numericAmount = parsedAmt;
                                existingMatch.unit = selectedUnit;
                                await existingMatch.save();
                                // Overwrite the currentIngId so recipe linking uses the old ID
                                currentIngId = existingMatch.id; 
                              } else {
                                // Truly new ingredient
                                final newIng = Ingredient(
                                  id: currentIngId, 
                                  name: inputName, 
                                  categoryId: selectedCategoryId!, 
                                  inStock: true, 
                                  addedDate: DateTime.now(), 
                                  expirationDate: selectedExpirationDate, 
                                  numericAmount: parsedAmt,
                                  unit: selectedUnit
                                );
                                await inventoryBox.put(currentIngId, newIng);
                              }
                            }

                            // 2. RESTORED: Save Recipe Links
                            for (var recipe in allRecipes) {
                              bool changed = false;
                              final existingIndex = recipe.ingredients.indexWhere((ri) => ri.ingredientId == currentIngId);
                              
                              if (linkedRecipeIds.contains(recipe.id)) {
                                if (existingIndex == -1) { 
                                  recipe.ingredients.add(RecipeIngredient(ingredientId: currentIngId, quantity: '适量', isMain: true)); 
                                  changed = true; 
                                }
                              } else {
                                // 关键修复：只有在明确是“编辑”模式时，未勾选才意味着“解除关联”。
                                // 如果是新建模式触发的智能合并，不勾选绝对不能去抹除它原本已有的关联！
                                if (isEdit && existingIndex != -1) { 
                                  recipe.ingredients.removeAt(existingIndex); 
                                  changed = true; 
                                }
                              }
                              if (changed) await recipe.save(); 
                            }
                            

                            
                          },
                          child: const Text('确认入库', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            
                            
                        ),
                      ),
                      
// RESTORED & BEAUTIFIED: Safe Delete Button
                      if (isEdit)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.08), 
                                foregroundColor: Colors.red, 
                                elevation: 0, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              label: const Text('彻底删除此食材', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                // Safe Delete Logic: Check if any recipe depends on this ingredient
                                final isLinked = allRecipes.any((r) => r.ingredients.any((ri) => ri.ingredientId == existingIngredient.id));
                                
                                if (isLinked) {
                                  Navigator.pop(context); // Close the modal first
                                  showDialog(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Text('无法彻底删除')]),
                                      content: const Text('有菜谱正在使用该食材。\n\n由于菜谱需要读取它的名称和单位，因此不能被彻底抹除。\n\n如果您当前不需要它，只需在界面上取消勾选关联，或将其数量清空即可（它会自动沉底并显示缺货）。'),
                                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('我知道了', style: TextStyle(color: Color(0xFF10C07B))))],
                                    )
                                  );
                                } else {
                                  // Safe to delete completely
                                  _deleteIngredient(existingIngredient);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget for quick add numbers
  Widget _buildQuickAddBtn(String label, TextEditingController ctrl, StateSetter setModalState) {
    return InkWell(
      onTap: () {
        double current = double.tryParse(ctrl.text) ?? 0.0;
        double toAdd = double.tryParse(label.replaceAll('+', '')) ?? 0.0;
        setModalState(() {
          // Format to remove trailing zeros if it's a whole number
          double result = current + toAdd;
          ctrl.text = result == result.truncateToDouble() ? result.toInt().toString() : result.toString();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Helper widget for quick dates
  Widget _buildQuickDateBtn(String label, int days, StateSetter setModalState, VoidCallback onSelect) {
    return InkWell(
      onTap: () { setModalState(onSelect); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
  void _consumeIngredient(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ingredient Consumed!'),
        content: Text('You finished ${ingredient.name}. Do you need to restock?'),
        actions: [
          TextButton(onPressed: () async { ingredient.inStock = false; await ingredient.save(); setState(() => syncMemoryWithHive()); if (context.mounted) Navigator.pop(c); }, child: const Text('No, just remove')),
          ElevatedButton(
            onPressed: () async {
              ingredient.inStock = false; await ingredient.save(); 
              final shoppingItem = ShoppingItem(id: generateId(), ingredientId: ingredient.id, groupName: 'Restock');
              await shoppingCartBox.put(shoppingItem.id, shoppingItem); 
              setState(() => syncMemoryWithHive());
              if (context.mounted) { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ingredient.name} added to Cart!'))); }
            },
            child: const Text('Yes, add to Cart'),
          ),
        ],
      ),
    );
  }

  void _deleteIngredient(Ingredient ingredient) {
    ingredient.delete(); 
    // REMOVED: The aggressive loop that modified recipes is gone forever!
    setState(() => syncMemoryWithHive());
  }

  // --- UI Builders ---

  Widget _buildTopLocationBar() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: StorageLocation.values.length,
        itemBuilder: (context, index) {
          final loc = StorageLocation.values[index];
          final isSelected = loc == _selectedLocation;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLocation = loc;
                _setDefaultCategoryForLocation();
                if (_rightScrollController.hasClients) {
                  _rightScrollController.jumpTo(0);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF4A5D4E) : Colors.grey.shade600,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 3,
                      width: 24,
                      decoration: BoxDecoration(color: const Color(0xFF4A5D4E), borderRadius: BorderRadius.circular(2)),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftCategoryMenu() {
    final categories = allCategories.where((c) => c.location == _selectedLocation).toList();
    
    return Container(
      width: 90,
      color: const Color(0xFFF5F5F5), // Light grey background for left menu
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == _selectedCategoryId;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryId = cat.id);
              // Future: _rightScrollController.animateTo(...) to jump to section
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border(left: BorderSide(color: isSelected ? const Color(0xFF4A5D4E) : Colors.transparent, width: 4))
              ),
              alignment: Alignment.center,
              child: Text(
                cat.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildRightContentArea() {
    final categories = allCategories.where((c) => c.location == _selectedLocation).toList();
    
    if (categories.isEmpty) {
      return const Center(child: Text('No categories in this location.', style: TextStyle(color: Colors.grey)));
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        controller: _rightScrollController,
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          
          final ingredients = myInventory.where((i) => i.categoryId == cat.id).toList();

          ingredients.sort((a, b) {
            if (a.inStock && !b.inStock) return -1;
            if (!a.inStock && b.inStock) return 1;
            return a.name.compareTo(b.name); 
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                child: Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black45)),
              ),
              
              if (ingredients.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text('No items added yet.', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                )
              else
                ...ingredients.map((ing) {
                  bool isExpired = ing.expirationDate != null && ing.expirationDate!.isBefore(DateTime.now());
                  bool hasAmount = ing.numericAmount != null;
                  bool hasDate = ing.expirationDate != null;
                  bool isOutOfStock = !ing.inStock;
                  
                  String subtitleText = '';
                  
                  if (isOutOfStock) {
                    subtitleText = '缺货 (Out of stock)';
                  } else {
                    if (hasAmount) {
                      String amtStr = ing.numericAmount == ing.numericAmount!.truncateToDouble() 
                          ? ing.numericAmount!.toInt().toString() 
                          : ing.numericAmount!.toString();
                      subtitleText += 'Qty: $amtStr${ing.unit ?? ''}';
                    }
                    if (hasDate) {
                      if (subtitleText.isNotEmpty) subtitleText += '  |  ';
                      subtitleText += 'Exp: ${ing.expirationDate!.toLocal().toString().split(' ')[0]}';
                    }
                  }

                  // 🌟 NEW: Advanced Subtitle Builder (Qty/Date + Tags)
                  List<Widget> subtitleChildren = [];
                  
                  // 1. Basic Info (Qty/Exp Date)
                  if (subtitleText.isNotEmpty) {
                    subtitleChildren.add(
                      Text(
                        subtitleText, 
                        style: TextStyle(
                          fontSize: 12, 
                          color: isExpired && !isOutOfStock ? Colors.red : Colors.grey.shade500, 
                          fontWeight: isExpired ? FontWeight.bold : FontWeight.normal
                        )
                      )
                    );
                  }

                  

                  // 2. AI Nutritional Tags (绿色亮点标签)
                  if (ing.nutritionalTags != null && ing.nutritionalTags!.isNotEmpty) {
                    if (subtitleChildren.isNotEmpty) {
                      subtitleChildren.add(const SizedBox(height: 6)); // 如果上面有库存文字，加一点间距
                    }
                    subtitleChildren.add(
                      Wrap(
                        spacing: 4, 
                        runSpacing: 4, 
                        children: ing.nutritionalTags!.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade100) // 淡淡的绿色边框更精致
                          ),
                          child: Text(
                            tag, 
                            style: TextStyle(fontSize: 9, color: Colors.green.shade700)
                          ),
                        )).toList(),
                      )
                    );
                  }

                  // 组合最终的副标题 Widget
                  Widget? finalSubtitleWidget;
                  if (subtitleChildren.isNotEmpty) {
                    finalSubtitleWidget = Padding(
                      padding: const EdgeInsets.only(top: 4.0), // 和标题拉开一点距离
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: subtitleChildren,
                      ),
                    );
                  }

                  return Opacity(
                    opacity: isOutOfStock ? 0.4 : 1.0, 
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.kitchen, color: Colors.grey.shade400)),
                        
                        // 1. Title now ONLY contains the ingredient name
                        title: Text(ing.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                        
                        // 2. Subtitle handles Qty/Date + Orange Tag + Green Tag
                        subtitle: Builder(
                          builder: (context) {
                            List<Widget> subtitleChildren = [];
                            
                            // A. Basic Info (Qty/Exp Date)
                            if (subtitleText.isNotEmpty) {
                              subtitleChildren.add(
                                Text(
                                  subtitleText, 
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: isExpired && !isOutOfStock ? Colors.red : Colors.grey.shade500, 
                                    fontWeight: isExpired ? FontWeight.bold : FontWeight.normal
                                  )
                                )
                              );
                            }

                            // B. Tags Row (Orange Group Tag + 1 Green Nutritional Tag)
                            List<Widget> tagWidgets = [];

                            if (ing.isAiAnalyzing) {
                              // Loading spinner
                              tagWidgets.add(const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)));
                            } else if (ing.dietaryGroup != null) {
                              // Orange Tag (Moved down here!)
                              tagWidgets.add(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.shade200)),
                                  child: Text(
                                    '${ing.dietaryGroup!.displayName} · ${ing.caloriesPer100g?.toInt()}大卡', 
                                    style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)
                                  ),
                                )
                              );
                            }

                            // Green Tag (Limit to 1 to save UI space and AI tokens)
                            if (ing.nutritionalTags != null && ing.nutritionalTags!.isNotEmpty) {
                              tagWidgets.add(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.shade200)),
                                  child: Text(
                                    ing.nutritionalTags!.first, // Take only the first tag
                                    style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)
                                  ),
                                )
                              );
                            }

                            // C. Combine Tags and add spacing
                            if (tagWidgets.isNotEmpty) {
                              if (subtitleChildren.isNotEmpty) subtitleChildren.add(const SizedBox(height: 6));
                              subtitleChildren.add(Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: tagWidgets));
                            }

                            if (subtitleChildren.isEmpty) return const SizedBox.shrink();
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: subtitleChildren),
                            );
                          }
                        ),
                        
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isOutOfStock)
                              IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.teal, size: 22), onPressed: () => _consumeIngredient(ing)),
                            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 22), onPressed: () => _showIngredientDialog(existingIngredient: ing)),
                          ],
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MatchedRecipesScreen(ingredient: ing))),
                      ),
                    ),
                  );
                }),
                
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
                child: InkWell(
                  onTap: () => _showIngredientDialog(defaultCategoryId: cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text('+ Add to ${cat.name}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return StardewPanelContainer(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // Clean modern background
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('My Kitchen', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            // 🌟 NEW: Batch AI Analysis Button
            IconButton(
              icon: const Icon(Icons.bolt, color: Colors.orangeAccent), 
              tooltip: '一键刷新营养成分', 
              onPressed: () => _batchAnalyzeNutrition(),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isStardewTheme,
              builder: (context, isStardew, child) {
                return IconButton(icon: Icon(isStardew ? Icons.wb_sunny_outlined : Icons.palette_outlined), tooltip: 'Switch Theme', onPressed: () => isStardewTheme.value = !isStardewTheme.value);
              },
            ),
            IconButton(icon: const Icon(Icons.category_outlined), tooltip: 'Manage Categories', onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryManagerScreen())); setState(() => syncMemoryWithHive()); })
          ],
        ),
        body: Column(
          children: [
            _buildTopLocationBar(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeftCategoryMenu(),
                  Expanded(child: _buildRightContentArea()),
                ],
              ),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF10C07B), // XHS Green
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Square with rounded corners
          elevation: 2,
          onPressed: () => _showIngredientDialog(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

// 🌟 NEW: Batch processing logic
  Future<void> _batchAnalyzeNutrition() async {
    // Find all ingredients that don't have a dietary group yet
    final needsAnalysis = myInventory.where((ing) => ing.dietaryGroup == null).toList();
    
    if (needsAnalysis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('所有食材都已分析完毕，无需刷新 ✨')));
      return;
    }

    // Turn on loading spinners for target items
    setState(() {
      for (var ing in needsAnalysis) { ing.isAiAnalyzing = true; }
    });

    // Extract names to send to AI
    final namesToAnalyze = needsAnalysis.map((i) => i.name).toList();
    
    try {
      // Simulate calling the batch API (You will implement the real API later)
      final results = await AiNutritionService.batchAnalyzeIngredients(namesToAnalyze);
      
      setState(() {
        for (var ing in needsAnalysis) {
          ing.isAiAnalyzing = false;
          if (results.containsKey(ing.name)) {
            final data = results[ing.name];
            ing.dietaryGroup = data['group'];
            ing.caloriesPer100g = data['cal'];
            ing.nutritionalTags = data['tags'];
            ing.save();
          }
        }
        syncMemoryWithHive();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功分析 ${needsAnalysis.length} 项食材！')));
    } catch (e) {
      // Handle error and turn off spinners
      setState(() { for (var ing in needsAnalysis) { ing.isAiAnalyzing = false; } });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分析失败，请重试')));
    }
  }
}
// ==========================================
// MATCHED RECIPES SCREEN (Enhanced Name-Matching Logic)
// ==========================================
// ==========================================
// MATCHED RECIPES SCREEN (用 RecipeCard 重构)
// ==========================================
class MatchedRecipesScreen extends StatefulWidget {
  final Ingredient ingredient;
  final DateTime? targetDate; // 🌟 NEW: 用于接收日历页传来的日期

  const MatchedRecipesScreen({super.key, required this.ingredient, this.targetDate});

  @override
  State<MatchedRecipesScreen> createState() => _MatchedRecipesScreenState();
}

class _MatchedRecipesScreenState extends State<MatchedRecipesScreen> {
  @override
  
  Widget build(BuildContext context) {
    // 1. 智能匹配逻辑：找出包含此食材 ID 或名称的所有菜谱
    final matchedRecipes = allRecipes.where((recipe) {
      return recipe.ingredients.any((ri) {
        // 条件 A: ID 直接匹配
        if (ri.ingredientId == widget.ingredient.id) return true;
        
        // 条件 B: 名称匹配（兼容手动输入的旧数据）
        final String currentIngName = widget.ingredient.name.trim().toLowerCase();
        final recipeIngDetails = myInventory.where((inv) => inv.id == ri.ingredientId).firstOrNull;
        if (recipeIngDetails != null) {
          return recipeIngDetails.name.trim().toLowerCase() == currentIngName;
        }
        
        // 条件 C: 如果 ingredientId 本身存的就是名称字符串
        return ri.ingredientId.trim().toLowerCase() == currentIngName;
      });
    }).toList();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 浅米色底色，衬托白色卡片
      appBar: AppBar(
        title: Text(
          '包含 "${widget.ingredient.name}" 的菜谱', 
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
        ), 
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: matchedRecipes.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '暂无包含此食材的菜谱', 
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)
                  ),
                ],
              ),
            ) 
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: matchedRecipes.length,
              itemBuilder: (context, index) {
                // 调用我们刚刚定义的共享组件
                return RecipeCard(
                  recipe: matchedRecipes[index],
                  quickAddDate: widget.targetDate,
                  // 当用户在卡片里点击收藏时，刷新当前页面的状态
                  onFavoriteChanged: () => setState(() {}),
                );
              },
            ),
    );
  }
}
//