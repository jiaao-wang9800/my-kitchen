/// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:typed_data'; // 🌟 新增：用于处理字节流
import 'package:share_plus/share_plus.dart';
import '../data/mock_database.dart';
import '../models/app_models.dart';

class BackupService {
  /// Exports all Hive data into a single JSON file.
  /// Works on both Mobile (Share Sheet) and Web (Browser Download).
  static Future<String?> exportAllData() async {
    try {
      // 1. 收集数据
      final data = {
        'ingredients': inventoryBox.values.map((e) => _ingredientToJson(e)).toList(),
        'categories': allCategories.map((e) => _categoryToJson(e)).toList(),
        'recipes': recipeBox.values.map((e) => _recipeToJson(e)).toList(),
        'shopping_items': shoppingCartBox.values.map((e) => _shoppingItemToJson(e)).toList(),
        'meal_plans': mealPlanBox.values.map((e) => _mealPlanToJson(e)).toList(),
        'export_date': DateTime.now().toIso8601String(),
      };

      // 2. 转换为 JSON 字符串
      String jsonString = jsonEncode(data);

      // 3. 🌟 核心跨平台改动：不写本地文件，直接在内存中生成 XFile 字节流
      final bytes = utf8.encode(jsonString);
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'application/json',
        name: 'my_kitchen_backup.json', // 在浏览器中下载时会默认使用这个文件名
      );

      // 4. 调用分享 / 下载
      await Share.shareXFiles([xFile], text: 'My Kitchen App Data Backup');
      
      return null; // 成功
    } catch (e) {
      print('Export Error: $e');
      return e.toString();
    }
  }

  // ... [下面的 _ingredientToJson 等所有 Helper methods 保持原样不变] ...
  static Map<String, dynamic> _ingredientToJson(Ingredient ing) => {
    'id': ing.id,
    'name': ing.name,
    'categoryId': ing.categoryId,
    'inStock': ing.inStock,
    'addedDate': ing.addedDate.toIso8601String(),
    'expirationDate': ing.expirationDate?.toIso8601String(),
    'numericAmount': ing.numericAmount,
    'unit': ing.unit,
    'dietaryGroup': ing.dietaryGroup?.name,
    'cal': ing.caloriesPer100g,
    'pro': ing.proteinPer100g,
    'carb': ing.carbsPer100g,
    'fat': ing.fatPer100g,
    'tags': ing.nutritionalTags,
  };

  static Map<String, dynamic> _categoryToJson(IngredientCategory cat) => {
    'id': cat.id,
    'name': cat.name,
    'location': cat.location.name,
  };

  static Map<String, dynamic> _recipeToJson(Recipe rec) => {
    'id': rec.id,
    'name': rec.name,
    'steps': rec.steps,
    'categoryIds': rec.categoryIds,
    'ingredients': rec.ingredients.map((ri) => {
      'ingredientId': ri.ingredientId,
      'quantity': ri.quantity,
      'isMain': ri.isMain,
    }).toList(),
  };

  static Map<String, dynamic> _shoppingItemToJson(ShoppingItem item) => {
    'id': item.id,
    'ingredientId': item.ingredientId,
    'isPurchased': item.isPurchased,
    'groupName': item.groupName,
  };

  static Map<String, dynamic> _mealPlanToJson(MealPlan plan) => {
    'id': plan.id,
    'date': plan.date.toIso8601String(),
    'type': plan.type.name,
    'recipeId': plan.recipeId,
  };
}