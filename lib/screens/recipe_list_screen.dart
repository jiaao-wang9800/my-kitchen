// lib/screens/recipe_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';
import '../main.dart'; 
import '../services/ai_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/recipe_card.dart'; // 🌟 新增：导入我们做好的共享卡片组件

// ==========================================
// SCREEN 2: Recipe List (小红书瀑布流风格重构)
// ==========================================

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});
  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final ImagePicker _picker = ImagePicker();
  String _mainSearchQuery = '';
  String? _selectedFilterCatId;

  // ----------------------------------------------------
  // 保留你原有的弹窗逻辑 (Add/Edit Recipe & AI Import)
  // ----------------------------------------------------
  void _showRecipeDialog({Recipe? existingRecipe}) {
    final bool isEdit = existingRecipe != null;
    final nameController = TextEditingController(text: isEdit ? existingRecipe.name : '');
    
    List<RecipeIngredient> selectedIngredients = isEdit 
        ? existingRecipe.ingredients.map((ri) => RecipeIngredient(ingredientId: ri.ingredientId, quantity: ri.quantity, isMain: ri.isMain)).toList() 
        : [];
    Map<String, TextEditingController> qtyControllers = {};
    for (var ri in selectedIngredients) {
      qtyControllers[ri.ingredientId] = TextEditingController(text: ri.quantity);
    }

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
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('New'),
                            onPressed: () async {
                              final newIngNameCtrl = TextEditingController();
                              String? selectedCatId = allCategories.isNotEmpty ? allCategories.first.id : null;

                              await showDialog(
                                context: context,
                                builder: (innerContext) => StatefulBuilder(
                                  builder: (innerContext, setInnerState) => AlertDialog(
                                    title: const Text('Quick Add Ingredient'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextField(controller: newIngNameCtrl, decoration: const InputDecoration(labelText: 'Ingredient Name'), onChanged: (val) => setInnerState(() {})),
                                          const SizedBox(height: 16),
                                          const Text('Category:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(height: 8),
                                          allCategories.isEmpty 
                                            ? const Text('No categories exist!', style: TextStyle(color: Colors.red))
                                            : Wrap(spacing: 8.0, runSpacing: 4.0, children: allCategories.map((cat) { return ChoiceChip(label: Text(cat.name), selected: selectedCatId == cat.id, selectedColor: Colors.teal.withValues(alpha: 0.3), onSelected: (bool selected) { if (selected) setInnerState(() => selectedCatId = cat.id); }); }).toList()),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(innerContext), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: (selectedCatId == null || newIngNameCtrl.text.trim().isEmpty) ? null : () async {
                                          final newIng = Ingredient(id: generateId(), name: newIngNameCtrl.text.trim(), categoryId: selectedCatId!, inStock: false);
                                          await inventoryBox.put(newIng.id, newIng);
                                          syncMemoryWithHive();
                                          setDialogState(() {
                                            selectedIngredients.add(RecipeIngredient(ingredientId: newIng.id, quantity: '适量', isMain: true));
                                            qtyControllers[newIng.id] = TextEditingController(text: '适量');
                                          });
                                          if (innerContext.mounted) Navigator.pop(innerContext);
                                        },
                                        child: const Text('Create'),
                                      )
                                    ],
                                  )
                                )
                              );
                            },
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      TextField(decoration: InputDecoration(hintText: 'Search ingredients...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.all(8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: (val) => setDialogState(() => ingredientSearchQuery = val)),
                      const SizedBox(height: 8),
                      myInventory.isEmpty ? const Text('No ingredients in inventory.', style: TextStyle(color: Colors.red)) : filteredIngredients.isEmpty ? const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('No matching ingredients found.')) : ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filteredIngredients.length, itemBuilder: (context, index) {
                        final ingredient = filteredIngredients[index];
                        final existingIndex = selectedIngredients.indexWhere((ri) => ri.ingredientId == ingredient.id);
                        final isSelected = existingIndex >= 0;

                        return Column(
                          children: [
                            CheckboxListTile(
                              title: Text(ingredient.name), 
                              value: isSelected, 
                              dense: true, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, 
                              onChanged: (bool? value) { 
                                setDialogState(() { 
                                  if (value == true) { 
                                    selectedIngredients.add(RecipeIngredient(ingredientId: ingredient.id, quantity: '适量', isMain: true)); 
                                    qtyControllers[ingredient.id] = TextEditingController(text: '适量');
                                  } else { 
                                    selectedIngredients.removeAt(existingIndex); 
                                    qtyControllers.remove(ingredient.id)?.dispose();
                                  } 
                                }); 
                              }
                            ),
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(child: TextField(controller: qtyControllers[ingredient.id], decoration: const InputDecoration(labelText: '用量', isDense: true), onChanged: (val) => selectedIngredients[existingIndex].quantity = val)),
                                    const SizedBox(width: 8),
                                    ChoiceChip(label: const Text('主料'), selected: selectedIngredients[existingIndex].isMain, onSelected: (v) => setDialogState(() => selectedIngredients[existingIndex].isMain = true)),
                                    const SizedBox(width: 4),
                                    ChoiceChip(label: const Text('调料'), selected: !selectedIngredients[existingIndex].isMain, onSelected: (v) => setDialogState(() => selectedIngredients[existingIndex].isMain = false)),
                                  ],
                                ),
                              )
                          ],
                        );
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
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return; 
                    if (isEdit) {
                      existingRecipe.name = nameController.text;
                      existingRecipe.ingredients = selectedIngredients;
                      existingRecipe.steps = steps;
                      existingRecipe.imagePath = selectedImagePath;
                      existingRecipe.categoryIds = selectedRecipeCatIds;
                      await existingRecipe.save(); 
                    } else {
                      final newRecipe = Recipe(
                        id: generateId(), name: nameController.text, ingredients: selectedIngredients, steps: steps, imagePath: selectedImagePath, categoryIds: selectedRecipeCatIds
                      );
                      await recipeBox.put(newRecipe.id, newRecipe); 
                    }
                    setState(() => syncMemoryWithHive()); 
                    if (context.mounted) Navigator.pop(context);
                  }, 
                  child: const Text('Save')
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      for (var ctrl in qtyControllers.values) { ctrl.dispose(); }
    });
  }

  void _showAiImportDialog() {
    final textCtrl = TextEditingController();
    bool isLoading = false;
    List<XFile> selectedImages = []; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(children: [Icon(Icons.auto_awesome, color: Colors.amber), SizedBox(width: 8), Text('AI Smart Import')]),
            content: isLoading 
              ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
              : SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Paste text or upload screenshots/receipts.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'e.g. Tomato scrambled eggs...', border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        if (selectedImages.isNotEmpty)
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal, itemCount: selectedImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Padding(padding: const EdgeInsets.only(right: 8.0, top: 8.0), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: kIsWeb ? Image.network(selectedImages[index].path, width: 50, height: 50, fit: BoxFit.cover) : Image.file(File(selectedImages[index].path), width: 50, height: 50, fit: BoxFit.cover))),
                                    Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setDialogState(() => selectedImages.removeAt(index)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)))),
                                  ],
                                );
                              },
                            ),
                          ),
                        TextButton.icon(icon: const Icon(Icons.add_photo_alternate, color: Colors.teal), label: const Text('Add Images', style: TextStyle(color: Colors.teal)), onPressed: () async { final List<XFile> images = await _picker.pickMultiImage(); if (images.isNotEmpty) { setDialogState(() => selectedImages.addAll(images)); } }),
                      ],
                    ),
                  ),
                ),
            actions: [
              if (!isLoading) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              if (!isLoading) ElevatedButton(
                onPressed: (textCtrl.text.isEmpty && selectedImages.isEmpty) ? null : () async {
                  setDialogState(() => isLoading = true);
                  final recipe = await AiService.importRecipeFromAi(textContent: textCtrl.text, imageFiles: selectedImages);
                  if (context.mounted) {
                    Navigator.pop(context); 
                    if (recipe != null) { setState(() {}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported: ${recipe.name}!'))); } 
                    else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to parse recipe.'))); }
                  }
                },
                child: const Text('Generate'),
              )
            ],
          );
        }
      ),
    );
  }

  // ----------------------------------------------------
  // 🌟 全新重构的 UI 构建方法 (还原小红书风格)
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // 浅米色/灰色底，衬托白色卡片
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 70, // 加高一点适配两行文字
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('全家共享 · 菜谱库', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              Text('家庭厨房', style: TextStyle(fontSize: 28, color: Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.auto_awesome, color: Colors.amber), tooltip: 'AI Smart Import', onPressed: () => _showAiImportDialog()),
            IconButton(icon: const Icon(Icons.label_outline, color: Colors.black54), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const RecipeCategoryManagerScreen())); setState(() => syncMemoryWithHive()); })     
          ],
        ),
        body: Column(
          children: [
            // 1. 搜索框：淡青灰色背景，无边框
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索食谱、食材...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFE9EDEA), // 高级感淡青灰
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _mainSearchQuery = val),
              ),
            ),

            // 2. 分类横向滚动条 (ChoiceChip)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(label: '全部', id: null),
                  ...allRecipeCategories.map((cat) => _buildFilterChip(label: cat.name, id: cat.id)),
                  // 增加一个“我的喜爱”快捷入口
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 4)),
                  const SizedBox(width: 8),
                  _buildFilterChip(label: '我的喜爱 ❤️', id: 'FAV_ONLY_SPECIAL_ID'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. 替换掉原先的 GridView，调用新的 _buildRecipeList
            Expanded(
              child: _buildRecipeList(),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF4A5D4E), // 深橄榄绿
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () => _showRecipeDialog(), 
          child: const Icon(Icons.add, color: Colors.white, size: 28)
        ),
      ),
    );
  }

  // 辅助方法：构建圆角分类标签
  Widget _buildFilterChip({required String label, required String? id}) {
    final bool isSelected = _selectedFilterCatId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilterCatId = id);
        },
        selectedColor: const Color(0xFF4A5D4E), // 选中时的深绿色
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        showCheckmark: false,
      ),
    );
  }

  // 🌟 核心重构：将 Grid 改为了直接调用 RecipeCard 的 ListView
  Widget _buildRecipeList() {
    final bool onlyFavorites = _selectedFilterCatId == 'FAV_ONLY_SPECIAL_ID';
    
    final displayedRecipes = allRecipes.where((r) {
      final matchesSearch = r.name.toLowerCase().contains(_mainSearchQuery.toLowerCase());
      final matchesCategory = (_selectedFilterCatId == null || onlyFavorites) 
          ? true 
          : r.categoryIds.contains(_selectedFilterCatId);
      final matchesFav = !onlyFavorites || r.isFavorite; 
      return matchesSearch && matchesCategory && matchesFav;
    }).toList();

    if (displayedRecipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(onlyFavorites ? '还没有收藏的菜谱' : '没有找到相关菜谱', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100), // 底部留出 FAB 的空间
      itemCount: displayedRecipes.length,
      itemBuilder: (context, index) {
        final recipe = displayedRecipes[index];
        return InkWell(
          // 点击卡片任意位置进入详情页
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)));
            setState(() => syncMemoryWithHive()); 
          },
          // 复用我们刚刚写好的高颜值卡片组件
          child: RecipeCard(
            recipe: recipe,
            onFavoriteChanged: () => setState(() {}),
          ),
        );
      },
    );
  }
}

// ==========================================
// Recipe Detail Screen (保持你之前的原样)
// ==========================================
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late List<TextEditingController> _stepControllers;
  
  late List<RecipeIngredient> _selectedIngredients;
  final Map<String, TextEditingController> _qtyControllers = {};
  String _ingSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe.name);
    _stepControllers = widget.recipe.steps.map((step) => TextEditingController(text: step)).toList();
    
    _selectedIngredients = widget.recipe.ingredients.map((ri) => 
      RecipeIngredient(ingredientId: ri.ingredientId, quantity: ri.quantity, isMain: ri.isMain)
    ).toList();
    
    for (var ri in _selectedIngredients) {
      _qtyControllers[ri.ingredientId] = TextEditingController(text: ri.quantity);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _stepControllers) { controller.dispose(); }
    for (var controller in _qtyControllers.values) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      widget.recipe.name = _nameController.text;
      widget.recipe.steps = _stepControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();
      widget.recipe.ingredients = _selectedIngredients;
    });
    await widget.recipe.save();
    syncMemoryWithHive();
  }

  Future<void> _addToCalendar() async {
    final date = await showDatePicker(
      context: context, initialDate: DateTime.now(), 
      firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 365))
    );
    if (date == null || !context.mounted) return;

    final mealType = await showDialog<MealType>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('选择餐段 (Meal Type)'),
        children: MealType.values.map((t) => SimpleDialogOption(
          onPressed: () => Navigator.pop(c, t),
          child: Text(t.displayName, style: const TextStyle(fontSize: 16)),
        )).toList(),
      )
    );

    if (mealType != null) {
      final plan = MealPlan(id: generateId(), date: date, type: mealType, recipeId: widget.recipe.id);
      await mealPlanBox.put(plan.id, plan);
      syncMemoryWithHive();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('成功加入菜单！', style: TextStyle(color: Colors.white)), backgroundColor: Colors.teal));
      }
    }
  }

  Widget _buildTimelineStep(int index, String text, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(radius: 14, backgroundColor: const Color(0xFF4A5D4E), child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 4))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 4),
              child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(RecipeIngredient ri) {
    final ing = myInventory.firstWhere((i) => i.id == ri.ingredientId, orElse: () => Ingredient(id: '', name: 'Unknown', categoryId: ''));
    final isMissing = !ing.inStock;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isMissing ? const Color(0xFFFFF9F0) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMissing ? const Color(0xFFFFECCC) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(isMissing ? Icons.shopping_basket : Icons.check_circle, color: isMissing ? Colors.orange.shade300 : Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(ing.name, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500))),
          Text(ri.quantity ?? '适量', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredIngredients = myInventory.where((ing) => ing.name.toLowerCase().contains(_ingSearchQuery.toLowerCase())).toList();
    final mains = _selectedIngredients.where((ri) => ri.isMain).toList();
    final seasonings = _selectedIngredients.where((ri) => !ri.isMain).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 浅灰色底色
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.recipe.imagePath != null 
                        ? Image.file(File(widget.recipe.imagePath!), fit: BoxFit.cover) 
                        : Container(color: Colors.grey[400], child: const Icon(Icons.restaurant, size: 80, color: Colors.white)),
                      Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.1), Colors.transparent, Colors.black.withValues(alpha: 0.8)]))),
                      if (!_isEditing)
                        Positioned(
                          bottom: 70, left: 24, right: 24,
                          child: Text(widget.recipe.name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, shadows: [Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black54)])),
                        ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8, runSpacing: 8,
                            children: allRecipeCategories.where((cat) => widget.recipe.categoryIds.contains(cat.id)).map((cat) => 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFF4A5D4E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                                child: Text(cat.name, style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D4E), fontWeight: FontWeight.bold)),
                              )
                            ).toList(),
                          ),
                        ),
                        if (!_isEditing)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_month, size: 16), 
                            label: const Text('加入日历'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D4E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                            onPressed: _addToCalendar,
                          )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing) ...[
                        TextField(controller: _nameController, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(labelText: 'Recipe Name', border: OutlineInputBorder())),
                        const SizedBox(height: 30),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('所需食材', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                          Text('${_selectedIngredients.length} 项', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isEditing) ...[
                        TextField(decoration: InputDecoration(hintText: '搜索并添加食材...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: (val) => setState(() => _ingSearchQuery = val)),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filteredIngredients.length,
                          itemBuilder: (context, index) {
                            final ing = filteredIngredients[index];
                            final riIdx = _selectedIngredients.indexWhere((ri) => ri.ingredientId == ing.id);
                            final isSel = riIdx >= 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: CheckboxListTile(
                                title: Text(ing.name), value: isSel, activeColor: const Color(0xFF4A5D4E),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) { 
                                      _selectedIngredients.add(RecipeIngredient(ingredientId: ing.id, quantity: '适量', isMain: true)); 
                                      _qtyControllers[ing.id] = TextEditingController(text: '适量');
                                    } else { 
                                      _selectedIngredients.removeAt(riIdx); 
                                      _qtyControllers.remove(ing.id)?.dispose();
                                    }
                                  });
                                }
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        if (mains.isNotEmpty) ...[
                          const Text('主料', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 12),
                          ...mains.map((ri) => _buildIngredientTile(ri)),
                        ],
                        if (seasonings.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('调味料', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 12),
                          ...seasonings.map((ri) => _buildIngredientTile(ri)),
                        ],
                      ],
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('烹饪步骤', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                          if (_isEditing) IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF4A5D4E)), onPressed: () => setState(() => _stepControllers.add(TextEditingController()))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true, padding: EdgeInsets.zero, physics: const NeverScrollableScrollPhysics(),
                        itemCount: _isEditing ? _stepControllers.length : widget.recipe.steps.length,
                        itemBuilder: (context, index) {
                          if (_isEditing) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 12, backgroundColor: const Color(0xFF4A5D4E), child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextField(controller: _stepControllers[index], decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: Colors.white))),
                                  IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _stepControllers.removeAt(index))),
                                ],
                              ),
                            );
                          } else {
                            return _buildTimelineStep(index, widget.recipe.steps[index], index == widget.recipe.steps.length - 1);
                          }
                        },
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('删除此菜谱', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.1), foregroundColor: Colors.red, elevation: 0, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: () => _confirmDelete(),
                        ),
                      ],
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(backgroundColor: Colors.white.withValues(alpha: 0.9), radius: 20, child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18), onPressed: () => Navigator.pop(context))),
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9), radius: 20,
                  child: IconButton(
                    icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined, color: Colors.black87, size: 20),
                    onPressed: () async {
                      if (_isEditing) await _saveChanges();
                      setState(() => _isEditing = !_isEditing);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('确认删除?'), content: const Text('删除后将无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { await widget.recipe.delete(); syncMemoryWithHive(); if (context.mounted) { Navigator.pop(c); Navigator.pop(context); } }, child: const Text('删除')),
        ],
      ),
    );
  }
}

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