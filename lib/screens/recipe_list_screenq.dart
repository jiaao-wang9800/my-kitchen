// lib/screens/recipe_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';
import '../services/ai_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/recipe_card.dart'; // 🌟 新增：导入我们做好的共享卡片组件
import '../services/backup_service.dart';
import '../widgets/ai_import_dialog.dart';
// 在你原本的 import 下面，加上这三行：
import 'recipe_detail_screen.dart';       // 引入菜谱详情页
import 'recipe_category_manager.dart'; // 引入分类管理页 (注意你的文件名如果不同，请按实际文件名写)
import '../widgets/ai_import_dialog.dart';  // 引入刚才做好的 AI 弹窗

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
    final ingredientSearchCtrl = TextEditingController(); // 🌟 新增：给弹窗搜索框用的控制器

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
                      
                      // 1. 干净的搜索框
                      TextField(
                        controller: ingredientSearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search or create ingredient...', 
                          prefixIcon: const Icon(Icons.search, size: 20), 
                          isDense: true, 
                          contentPadding: const EdgeInsets.all(8), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          suffixIcon: ingredientSearchQuery.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setDialogState(() { ingredientSearchCtrl.clear(); ingredientSearchQuery = ''; }))
                            : null,
                        ), 
                        onChanged: (val) => setDialogState(() => ingredientSearchQuery = val)
                      ),
                      const SizedBox(height: 8),

                      // 2. 搜索状态下：显示匹配结果 & 新建按钮
                      if (ingredientSearchQuery.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ✅ 弹窗里的搜索结果展示
                              ...filteredIngredients.map((ing) {
                                final isAlreadyAdded = selectedIngredients.any((ri) => ri.ingredientId == ing.id);
                                
                                return ListTile(
                                  dense: true, 
                                  title: Text(
                                    ing.name, 
                                    style: TextStyle(
                                      color: isAlreadyAdded ? Colors.grey : Colors.black87,
                                      decoration: isAlreadyAdded ? TextDecoration.lineThrough : null,
                                    )
                                  ), 
                                  trailing: isAlreadyAdded 
                                    ? const Text('已添加', style: TextStyle(color: Colors.grey, fontSize: 12))
                                    : const Icon(Icons.add_circle_outline, color: Colors.teal),
                                  onTap: isAlreadyAdded ? null : () {
                                    setDialogState(() {
                                      selectedIngredients.add(RecipeIngredient(ingredientId: ing.id, quantity: '适量', isMain: true));
                                      qtyControllers[ing.id] = TextEditingController(text: '适量');
                                      ingredientSearchCtrl.clear(); 
                                      ingredientSearchQuery = '';
                                    });
                                  }
                                );
                              }),
                              ListTile(
                                dense: true, leading: const Icon(Icons.add, color: Colors.blue), title: Text('Create new "$ingredientSearchQuery"', style: const TextStyle(color: Colors.blue)),
                                onTap: () async {
                                  final newIngNameCtrl = TextEditingController(text: ingredientSearchQuery);
                                  String? selectedCatId = allCategories.isNotEmpty ? allCategories.first.id : null;
                                  await showDialog(
                                    context: context,
                                    builder: (innerContext) => StatefulBuilder(
                                      builder: (innerContext, setInnerState) => AlertDialog(
                                        title: const Text('Quick Add'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TextField(controller: newIngNameCtrl, decoration: const InputDecoration(labelText: 'Name'), onChanged: (v) => setInnerState((){})),
                                            const SizedBox(height: 16),
                                            const Text('Category:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            Wrap(spacing: 8.0, children: allCategories.map((cat) => ChoiceChip(label: Text(cat.name), selected: selectedCatId == cat.id, onSelected: (sel) { if (sel) setInnerState(() => selectedCatId = cat.id); })).toList()),
                                          ]
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(innerContext), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: (selectedCatId == null || newIngNameCtrl.text.isEmpty) ? null : () async {
                                              final newIng = Ingredient(id: generateId(), name: newIngNameCtrl.text.trim(), categoryId: selectedCatId!, inStock: false);
                                              await inventoryBox.put(newIng.id, newIng); syncMemoryWithHive();
                                              setDialogState(() {
                                                selectedIngredients.add(RecipeIngredient(ingredientId: newIng.id, quantity: '适量', isMain: true));
                                                qtyControllers[newIng.id] = TextEditingController(text: '适量');
                                                ingredientSearchCtrl.clear(); ingredientSearchQuery = '';
                                              });
                                              if (innerContext.mounted) Navigator.pop(innerContext);
                                            },
                                            child: const Text('Create')
                                          )
                                        ]
                                      )
                                    )
                                  );
                                }
                              )
                            ]
                          )
                        ),

                      // 3. 始终显示：已选中的食材列表（带修改用量和删除）
                      if (selectedIngredients.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                          itemCount: selectedIngredients.length,
                          itemBuilder: (context, index) {
                            final ri = selectedIngredients[index];
                            final ing = myInventory.firstWhere((i) => i.id == ri.ingredientId, orElse: () => Ingredient(id: '', name: 'Unknown', categoryId: ''));
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('• ${ing.name}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => setDialogState(() { selectedIngredients.removeAt(index); qtyControllers.remove(ing.id)?.dispose(); }))
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(child: TextField(controller: qtyControllers[ing.id], decoration: const InputDecoration(labelText: '用量', isDense: true), onChanged: (val) => ri.quantity = val)),
                                      const SizedBox(width: 8),
                                      ChoiceChip(label: const Text('主料', style: TextStyle(fontSize: 12)), selected: ri.isMain, onSelected: (v) => setDialogState(() => ri.isMain = true)),
                                      const SizedBox(width: 4),
                                      ChoiceChip(label: const Text('调料', style: TextStyle(fontSize: 12)), selected: !ri.isMain, onSelected: (v) => setDialogState(() => ri.isMain = false)),
                                    ],
                                  ),
                                )
                              ],
                            );
                          }
                        ),
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
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.amber), 
              tooltip: 'AI Smart Import', 
              onPressed: () async {
                // 1. 弹出你刚才写好的独立弹窗，并等待它的返回值（Recipe）
                final generatedRecipe = await showDialog<Recipe>(
                  context: context,
                  builder: (context) => const AiImportDialog(),
                );

                if (context.mounted) {
                  // 🌟 魔法就在这里：重新从 Hive 读取所有菜谱到 allRecipes 列表
                  //syncMemoryWithHive(); 
                  
                  // 然后通知 UI：内存里的 allRecipes 已经更新了，快重画！
                  //setState(() {});

                if (generatedRecipe != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('🎉 已成功同步: ${generatedRecipe.name}'))
                        );
                      }
                    }
                  }
                ),
            
            IconButton(icon: const Icon(Icons.label_outline, color: Colors.black54), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const RecipeCategoryManagerScreen())); setState(() => syncMemoryWithHive()); }),
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blueAccent), 
              tooltip: '备份数据到微信/云端', 
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在打包数据...')));
                await BackupService.exportAllData();
              }
            )     
            
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


