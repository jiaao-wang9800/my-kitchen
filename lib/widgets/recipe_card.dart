// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';
// ✅ 换成新的路径
import '../screens/recipe_detail_screen.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onFavoriteChanged;
  final DateTime? quickAddDate; // 🌟 新增：如果传入了这个日期，说明开启了“一键排期”模式

  const RecipeCard({
    super.key, 
    required this.recipe, 
    this.onFavoriteChanged,
    this.quickAddDate, // 🌟 新增
  });

  // Calculate how many ingredients are currently missing
  int _calculateMissingCount() {
    int missing = 0;
    for (var req in recipe.ingredients) {
      final hasIngredient = myInventory.any((inv) => 
        (inv.id == req.ingredientId || inv.name == req.ingredientId) && inv.inStock
      );
      if (!hasIngredient) missing++;
    }
    return missing;
  }

  // Add to Calendar Logic
  Future<void> _addToCalendar(BuildContext context) async {
    final date = await showDatePicker(
      context: context, 
      initialDate: DateTime.now(), 
      firstDate: DateTime.now().subtract(const Duration(days: 30)), 
      lastDate: DateTime.now().add(const Duration(days: 365))
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
      final plan = MealPlan(id: generateId(), date: date, type: mealType, recipeId: recipe.id);
      await mealPlanBox.put(plan.id, plan);
      syncMemoryWithHive();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('成功加入菜单！', style: TextStyle(color: Colors.white)), backgroundColor: Colors.teal)
        );
      }
    }
  }

// 🌟 新增：极速加入指定日期的逻辑
  void _quickAddToDate(BuildContext context) async {
    if (quickAddDate == null) return;
    
    // 默认可以先不分三餐，或者如果你想的话，也可以弹个简易弹窗问一下早中晚
    // 这里我们先默认加入一个 'others'（不分餐）的计划中，配合你要求的“默认不按三餐”
    final plan = MealPlan(
      id: generateId(), 
      date: quickAddDate!, 
      type: MealType.lunch, // 先默认塞进午餐里 // 之后如果需要，也可以改成弹窗选择
      recipeId: recipe.id
    );
    await mealPlanBox.put(plan.id, plan);
    syncMemoryWithHive();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加到 ${quickAddDate!.month}月${quickAddDate!.day}日 的菜单！'), backgroundColor: const Color(0xFF4A5D4E))
      );
      // 如果是在弹窗里，自动关闭弹窗
      Navigator.pop(context);
    }
  }
  
  // NEW: Add missing ingredients to the Shopping Cart grouped by this recipe
  void _addMissingToCart(BuildContext context) {
    bool addedAny = false;

    for (var req in recipe.ingredients) {
      // Check if we have it in stock
      final hasIngredient = myInventory.any((inv) => 
        (inv.id == req.ingredientId || inv.name == req.ingredientId) && inv.inStock
      );
      
      if (!hasIngredient) {
        // Find the actual ingredient ID (it might exist in DB but be out of stock)
        final existingInv = myInventory.firstWhere(
          (inv) => inv.id == req.ingredientId || inv.name == req.ingredientId,
          // Fallback: If it completely doesn't exist in DB, we use the string as ID temporarily
          orElse: () => Ingredient(id: req.ingredientId, name: req.ingredientId, categoryId: '') 
        );
        
        final targetId = existingInv.id; 
        
        // Check if it's already in the cart and not purchased
        bool alreadyInCart = myShoppingCart.any((item) => item.ingredientId == targetId && !item.isPurchased);
        
        if (!alreadyInCart) {
          final newItem = ShoppingItem(id: generateId(), ingredientId: targetId, groupName: recipe.name);
          shoppingCartBox.put(newItem.id, newItem);
          addedAny = true;
        }
      }
    }
    
    if (addedAny) {
      syncMemoryWithHive();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已将缺少的食材加入购物车 🛒')));
      // Force UI refresh if callback is provided
      if (onFavoriteChanged != null) onFavoriteChanged!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缺少的食材已在购物车中')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final int missingCount = _calculateMissingCount();
    final bool isFull = missingCount == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            // Navigate to Details
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))
            );
            if (onFavoriteChanged != null) onFavoriteChanged!();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 1. Left: Info Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      
                      // Status and Cart Button Row
                      Row(
                        children: [
                          // Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFull ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isFull ? Icons.check_circle : Icons.error_outline,
                                  size: 14,
                                  color: isFull ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFull ? '食材齐全' : '缺 $missingCount 样',
                                  style: TextStyle(
                                    color: isFull ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // RESTORED: Add to Cart Button (Only shows if missing items)
                          if (!isFull)
                            GestureDetector(
                              onTap: () => _addMissingToCart(context),
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.orange),
                              ),
                            ),
                          
                          const SizedBox(width: 12),
                          // Time Pill
                          const Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey),
                              SizedBox(width: 4),
                              Text('10 分', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // NEW: Pill Tags for Recipe Categories
                      Wrap(
                        spacing: 6, 
                        runSpacing: 4, 
                        children: allRecipeCategories
                            .where((cat) => recipe.categoryIds.contains(cat.id))
                            .map((cat) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.08), 
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      if (recipe.categoryIds.isEmpty)
                        Text('暂无分类', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ],
                  ),
                ),
                
                // 2. Right: Image and Buttons
                const SizedBox(width: 12),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: recipe.imagePath != null
                          ? Image.asset(recipe.imagePath!, width: 100, height: 100, fit: BoxFit.cover)
                          : Container(color: Colors.grey.shade100, width: 100, height: 100, child: const Icon(Icons.restaurant, color: Colors.grey)),
                    ),
                    
                    // Favorite Heart
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () async {
                          recipe.isFavorite = !recipe.isFavorite;
                          await recipe.save();
                          if (onFavoriteChanged != null) onFavoriteChanged!();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(
                            recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: recipe.isFavorite ? Colors.pinkAccent : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    // Calendar Add
                   // 右下角：加入计划按钮 或 一键添加按钮
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        // 🌟 判断：如果有快捷日期，就触发极速添加；否则触发原来的弹窗选日期
                        onTap: () => quickAddDate != null ? _quickAddToDate(context) : _addToCalendar(context), 
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            // 🌟 如果是一键添加模式，变成更醒目的主色调
                            color: quickAddDate != null ? const Color(0xFF4A5D4E) : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Icon(
                            // 🌟 图标切换
                            quickAddDate != null ? Icons.add : Icons.event_available, 
                            size: 20, 
                            color: quickAddDate != null ? Colors.white : const Color(0xFF4A5D4E)
                          ),
                        ),
                      ),
                    ),
                    ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}