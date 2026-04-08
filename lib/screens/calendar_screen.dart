// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';
import 'recipe_list_screen.dart'; 

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  
  // State variable to toggle between Planner (edit) and Overview (Big Grid)
  bool _isOverviewMode = false;

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // ==========================================
  // SHARED: Recipe Picker Dialog
  // ==========================================
  void _showRecipePicker(MealType mealType) {
    String searchQuery = '';
    String? selectedFilterCategoryId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            final filteredRecipes = allRecipes.where((r) {
              final matchesSearch = r.name.toLowerCase().contains(searchQuery.toLowerCase());
              final matchesCategory = selectedFilterCategoryId == null || r.categoryIds.contains(selectedFilterCategoryId);
              return matchesSearch && matchesCategory;
            }).toList();

            return AlertDialog(
              title: Text('Plan ${mealType.displayName}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(hintText: 'Search recipes...', prefixIcon: Icon(Icons.search), isDense: true),
                      onChanged: (val) => setDialogState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: selectedFilterCategoryId == null,
                            onSelected: (selected) { if (selected) setDialogState(() => selectedFilterCategoryId = null); },
                          ),
                          ...allRecipeCategories.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ChoiceChip(
                                label: Text(cat.name),
                                selected: selectedFilterCategoryId == cat.id,
                                onSelected: (selected) { if (selected) setDialogState(() => selectedFilterCategoryId = cat.id); },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    ListTile(
                      leading: const Icon(Icons.add_box, color: Colors.teal),
                      title: const Text('Create New Recipe', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final newNameCtrl = TextEditingController();
                        final newRecipeName = await showDialog<String>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('New Recipe Name'),
                            content: TextField(controller: newNameCtrl),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(c, newNameCtrl.text), child: const Text('Create')),
                            ],
                          )
                        );

                        if (newRecipeName != null && newRecipeName.isNotEmpty) {
                          setState(() {
                            final newRecipe = Recipe(id: generateId(), name: newRecipeName, ingredientIds: [], categoryIds: []);
                            allRecipes.add(newRecipe);
                            myMealPlans.removeWhere((m) => _isSameDay(m.date, _selectedDate) && m.type == mealType);
                            myMealPlans.add(MealPlan(id: generateId(), date: _selectedDate, type: mealType, recipeId: newRecipe.id));
                          });
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const Divider(),
                    
                    Expanded(
                      child: filteredRecipes.isEmpty
                          ? const Center(child: Text('No recipes match.'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = filteredRecipes[index];
                                return ListTile(
                                  title: Text(recipe.name),
                                  subtitle: Text(
                                    recipe.categoryIds.map((id) => allRecipeCategories.firstWhere((c) => c.id == id).name).join(', '),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      myMealPlans.removeWhere((m) => _isSameDay(m.date, _selectedDate) && m.type == mealType);
                                      myMealPlans.add(MealPlan(id: generateId(), date: _selectedDate, type: mealType, recipeId: recipe.id));
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // VIEW 1: Planner Mode (Edit & Assign)
  // ==========================================
  Widget _buildMealSlot(MealType type) {
    final currentPlan = myMealPlans.where((m) => _isSameDay(m.date, _selectedDate) && m.type == type).firstOrNull;
    Recipe? plannedRecipe;
    if (currentPlan != null) plannedRecipe = allRecipes.where((r) => r.id == currentPlan.recipeId).firstOrNull;

    IconData slotIcon;
    switch (type) {
      case MealType.breakfast: slotIcon = Icons.free_breakfast; break;
      case MealType.lunch: slotIcon = Icons.lunch_dining; break;
      case MealType.dinner: slotIcon = Icons.dinner_dining; break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(slotIcon, color: Colors.orange, size: 30),
        title: Text(type.displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        subtitle: plannedRecipe != null ? Text(plannedRecipe.name, style: const TextStyle(color: Colors.teal, fontSize: 18, fontWeight: FontWeight.bold)) : const Text('Tap + to plan meal'),
        trailing: plannedRecipe != null 
            ? IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: () => setState(() => myMealPlans.remove(currentPlan))) 
            : IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30), onPressed: () => _showRecipePicker(type)),
        onTap: plannedRecipe != null ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: plannedRecipe!))) : null,
      ),
    );
  }

  Widget _buildPlannerMode() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: CalendarDatePicker(
            initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030),
            onDateChanged: (DateTime newDate) => setState(() => _selectedDate = newDate),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              children: [_buildMealSlot(MealType.breakfast), _buildMealSlot(MealType.lunch), _buildMealSlot(MealType.dinner)],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: Big Grid Calendar Mode (View Only)
  // ==========================================
  
  // Helper to build a tiny tag for the meal in the grid cell
  Widget _buildTinyMealLabel(MealType type, List<MealPlan> dayPlans) {
    final plan = dayPlans.where((p) => p.type == type).firstOrNull;
    if (plan == null) return const SizedBox.shrink();

    final recipe = allRecipes.where((r) => r.id == plan.recipeId).firstOrNull;
    if (recipe == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    switch (type) {
      case MealType.breakfast: icon = Icons.free_breakfast; color = Colors.orange; break;
      case MealType.lunch: icon = Icons.lunch_dining; color = Colors.green; break;
      case MealType.dinner: icon = Icons.dinner_dining; color = Colors.blue; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              recipe.name, 
              style: TextStyle(fontSize: 9, color: Colors.grey[800], fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCalendarMode() {
    // Math for the calendar grid
    int year = _selectedDate.year;
    int month = _selectedDate.month;
    
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int firstWeekday = DateTime(year, month, 1).weekday; // 1 (Mon) to 7 (Sun)
    int emptySlotsAtStart = firstWeekday - 1; 
    
    int totalCells = emptySlotsAtStart + daysInMonth;
    int totalRows = (totalCells / 7).ceil();
    int renderCells = totalRows * 7; // Fill the last row with empty cells to look nice

    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Column(
      children: [
        // 1. Month Navigation Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 30), 
                onPressed: () => setState(() => _selectedDate = DateTime(year, month - 1, 1))
              ),
              Text('${monthNames[month - 1]} $year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 30), 
                onPressed: () => setState(() => _selectedDate = DateTime(year, month + 1, 1))
              ),
            ],
          ),
        ),
        
        // 2. Weekdays Header
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => 
              Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))))
            ).toList(),
          ),
        ),

        // 3. The Big Grid
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.55, // Make cells tall enough to hold 3 meals
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: renderCells,
              itemBuilder: (context, index) {
                // Empty cells at start or end of the month
                if (index < emptySlotsAtStart || index >= emptySlotsAtStart + daysInMonth) {
                  return Container(color: Colors.white); 
                }
                
                int day = index - emptySlotsAtStart + 1;
                DateTime cellDate = DateTime(year, month, day);
                bool isToday = _isSameDay(cellDate, DateTime.now());
                bool isSelected = _isSameDay(cellDate, _selectedDate);

                // Get meals for this specific day
                var dayPlans = myMealPlans.where((m) => _isSameDay(m.date, cellDate)).toList();

                return GestureDetector(
                  onTap: () {
                    // Tap a cell to select that date and jump to Planner mode!
                    setState(() {
                      _selectedDate = cellDate;
                      _isOverviewMode = false;
                    });
                  },
                  child: Container(
                    color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.white,
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Number
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isToday ? Colors.teal : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$day', 
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.white : Colors.black87
                              )
                            ),
                          ),
                        ),
                        // Tiny Meal Labels
                        _buildTinyMealLabel(MealType.breakfast, dayPlans),
                        _buildTinyMealLabel(MealType.lunch, dayPlans),
                        _buildTinyMealLabel(MealType.dinner, dayPlans),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOverviewMode ? 'Month Overview' : 'Meal Planner'), 
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isOverviewMode ? Icons.edit_calendar : Icons.calendar_view_month),
            tooltip: _isOverviewMode ? 'Edit Daily Plan' : 'View Full Month',
            onPressed: () {
              setState(() {
                _isOverviewMode = !_isOverviewMode;
              });
            },
          )
        ],
      ),
      body: _isOverviewMode ? _buildGridCalendarMode() : _buildPlannerMode(),
    );
  }
}