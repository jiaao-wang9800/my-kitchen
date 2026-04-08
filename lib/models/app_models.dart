// lib/models/app_models.dart

enum StorageLocation { fridge, freezer, cupboard, spices }

extension StorageLocationExtension on StorageLocation {
  String get displayName {
    switch (this) {
      case StorageLocation.fridge: return 'Fridge';
      case StorageLocation.freezer: return 'Freezer';
      case StorageLocation.cupboard: return 'Cupboard';
      case StorageLocation.spices: return 'Spices';
    }
  }
}

class IngredientCategory {
  String id;
  String name;
  StorageLocation location;
  IngredientCategory({required this.id, required this.name, required this.location});
}

class Ingredient {
  String id;
  String name;
  String categoryId;
  bool inStock;
  
  // NEW: Date tracking properties
  DateTime addedDate; 
  DateTime? expirationDate; // Nullable, because it's optional

  Ingredient({
    required this.id, 
    required this.name, 
    required this.categoryId, 
    this.inStock = true,
    DateTime? addedDate,
    this.expirationDate,
  }) : addedDate = addedDate ?? DateTime.now(); // Default to current time if not provided
}

class RecipeCategory {
  String id;
  String name;
  RecipeCategory({required this.id, required this.name});
}

class Recipe {
  String id;
  String name;
  List<String> ingredientIds;
  List<String> steps;
  String? imagePath;
  List<String> categoryIds;

  Recipe({required this.id, required this.name, required this.ingredientIds, this.steps = const [], this.imagePath, this.categoryIds = const []});
}

enum MealType { breakfast, lunch, dinner }

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.dinner: return 'Dinner';
    }
  }
}

class MealPlan {
  String id;
  DateTime date;
  MealType type;
  String recipeId;
  MealPlan({required this.id, required this.date, required this.type, required this.recipeId});
}

class ShoppingItem {
  String id;
  String ingredientId; 
  bool isPurchased;
  String? groupName; 

  ShoppingItem({required this.id, required this.ingredientId, this.isPurchased = false, this.groupName});
}