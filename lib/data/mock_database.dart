// lib/data/mock_database.dart
import '../models/app_models.dart';

List<IngredientCategory> allCategories = [
  IngredientCategory(id: 'c1', name: 'Vegetables', location: StorageLocation.fridge),
  IngredientCategory(id: 'c2', name: 'Dairy & Eggs', location: StorageLocation.fridge),
  IngredientCategory(id: 'c3', name: 'Frozen Meat', location: StorageLocation.freezer),
  IngredientCategory(id: 'c4', name: 'Dry Beans', location: StorageLocation.cupboard),
  IngredientCategory(id: 'c5', name: 'Basic Spices', location: StorageLocation.spices),
];

List<Ingredient> myInventory = [
  Ingredient(id: 'i1', name: 'Tomato', categoryId: 'c1', inStock: true, addedDate: DateTime.now().subtract(const Duration(days: 2)), expirationDate: DateTime.now().add(const Duration(days: 3))),
  Ingredient(id: 'i2', name: 'Egg', categoryId: 'c2', inStock: true, addedDate: DateTime.now().subtract(const Duration(days: 1)), expirationDate: DateTime.now().add(const Duration(days: 10))),
  Ingredient(id: 'i3', name: 'Frozen Meatballs', categoryId: 'c3', inStock: true, addedDate: DateTime.now().subtract(const Duration(days: 10))), // No expiration date
  Ingredient(id: 'i4', name: 'Black Beans', categoryId: 'c4', inStock: true, addedDate: DateTime.now()),
  Ingredient(id: 'i5', name: 'Salt', categoryId: 'c5', inStock: true, addedDate: DateTime.now()),
];

List<RecipeCategory> allRecipeCategories = [
  RecipeCategory(id: 'rc1', name: 'Quick & Easy'),
  RecipeCategory(id: 'rc2', name: 'Home-style'),
  RecipeCategory(id: 'rc3', name: 'Meat'),
  RecipeCategory(id: 'rc4', name: 'Vegetarian'),
  RecipeCategory(id: 'rc5', name: 'Soup'),
];

List<Recipe> allRecipes = [
  Recipe(
    id: 'r1', 
    name: 'Tomato & Egg Stir-fry', 
    ingredientIds: ['i1', 'i2', 'i5'],
    steps: [
      'Wash and cut the tomatoes into wedges.',
      'Beat the eggs in a bowl with a pinch of salt.',
      'Scramble the eggs in a pan.',
      'Stir-fry tomatoes until soft, add eggs back, and mix.'
    ],
    categoryIds: ['rc1', 'rc2', 'rc4'], 
  ),
];

List<MealPlan> myMealPlans = [];
List<ShoppingItem> myShoppingCart = [];

String generateId() => DateTime.now().millisecondsSinceEpoch.toString();