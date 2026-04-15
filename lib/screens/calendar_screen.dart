// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../data/mock_database.dart';
import 'inventory_screen.dart'; // 🌟 导入了库存页面以使用 MatchedRecipesScreen

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isOverviewMode = false;
  bool _isGroupedByMealType = false;
  Set<String> _syncedPlanIds = {};
  bool _isSyncSelectionMode = false;
  final PageController _weekPageController = PageController(initialPage: 500);

  @override
  void initState() {
    super.initState();
    _syncedPlanIds = myShoppingCart.where((item) => item.mealPlanId != null).map((item) => item.mealPlanId!).toSet();
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Future<void> _triggerSync() async {
    await syncMealPlansToCart(_syncedPlanIds.toList());
    setState(() {}); 
  }

  DateTime _getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));
  String _getWeekdayName(int weekday) => ['一', '二', '三', '四', '五', '六', '日'][weekday - 1];

  void _showRecipePicker(MealType mealType) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredRecipes = allRecipes.where((r) => r.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
          return AlertDialog(
            title: Text('Plan ${mealType.displayName}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(decoration: const InputDecoration(hintText: 'Search recipes...', prefixIcon: Icon(Icons.search), isDense: true), onChanged: (val) => setDialogState(() => searchQuery = val)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true, itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(filteredRecipes[index].name),
                          onTap: () async {
                            final newPlan = MealPlan(id: generateId(), date: _selectedDate, type: mealType, recipeId: filteredRecipes[index].id);
                            await mealPlanBox.put(newPlan.id, newPlan);
                            syncMemoryWithHive();
                            if (context.mounted) Navigator.pop(context);
                            setState(() {});
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            if (_isOverviewMode) 
              Expanded(child: _buildGridCalendarMode())
            else ...[
              _buildWeeklySlider(),
              const SizedBox(height: 16),
              Expanded(child: _buildMealListContainer()),
            ]
          ],
        ),
      ),
      bottomNavigationBar: _isSyncSelectionMode ? Container(color: Colors.orange, padding: const EdgeInsets.all(8), child: Text('Sync Mode: ${_syncedPlanIds.length} plans selected', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))) : null,
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))]),
            child: const Text('饮食搭配', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Row(
            children: [
              if (_isOverviewMode) 
                IconButton(icon: Icon(_isSyncSelectionMode ? Icons.shopping_cart : Icons.add_shopping_cart), color: _isSyncSelectionMode ? Colors.orange : Colors.grey.shade600, onPressed: () => setState(() => _isSyncSelectionMode = !_isSyncSelectionMode)),
              Container(
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))]),
                child: IconButton(
                  icon: Icon(_isOverviewMode ? Icons.view_agenda_outlined : Icons.calendar_month_outlined, color: Colors.black87),
                  onPressed: () => setState(() { _isOverviewMode = !_isOverviewMode; if (!_isOverviewMode) _isSyncSelectionMode = false; }),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeeklySlider() {
    return SizedBox(
      height: 80,
      child: PageView.builder(
        controller: _weekPageController,
        itemBuilder: (context, index) {
          int weekOffset = index - 500;
          DateTime startOfWeek = _getStartOfWeek(DateTime.now()).add(Duration(days: weekOffset * 7));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (dayIndex) {
                DateTime date = startOfWeek.add(Duration(days: dayIndex));
                bool isSelected = _isSameDay(date, _selectedDate);
                bool isToday = _isSameDay(date, DateTime.now());
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 45, decoration: BoxDecoration(color: isSelected ? const Color(0xFF4A5D4E) : Colors.white, borderRadius: BorderRadius.circular(24), border: isToday && !isSelected ? Border.all(color: const Color(0xFF4A5D4E), width: 1.5) : null, boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4A5D4E).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : []),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_getWeekdayName(date.weekday), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey.shade500)), const SizedBox(height: 4), Text('${date.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87))]),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealListContainer() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('周${_getWeekdayName(_selectedDate.weekday)}吃什么', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                Row(children: [Text('三餐展示', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), const SizedBox(width: 8), Switch(value: _isGroupedByMealType, activeColor: const Color(0xFF4A5D4E), onChanged: (val) => setState(() => _isGroupedByMealType = val))])
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                if (_isGroupedByMealType) ...[
                  _buildGroupedMealSlot(MealType.breakfast), _buildGroupedMealSlot(MealType.lunch), _buildGroupedMealSlot(MealType.dinner),
                ] else 
                  _buildFlatMealList(),
                
                const SizedBox(height: 24),
                // 🌟 新增：最下方的餐食推荐核心模块
                _buildRecommendationBlock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedMealSlot(MealType type) {
    final currentPlans = myMealPlans.where((m) => _isSameDay(m.date, _selectedDate) && m.type == type).toList();
    IconData slotIcon = type == MealType.breakfast ? Icons.free_breakfast_outlined : (type == MealType.lunch ? Icons.lunch_dining_outlined : Icons.dinner_dining_outlined);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(children: [Icon(slotIcon, size: 20, color: Colors.orange), const SizedBox(width: 8), Text(type.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), const Spacer(), IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4A5D4E)), onPressed: () => _showRecipePicker(type))]),
        ),
        if (currentPlans.isEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0), child: Text('No meals planned yet.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
        ...currentPlans.map((plan) => _buildPlanListItem(plan)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
      ],
    );
  }

  Widget _buildFlatMealList() {
    final dayPlans = myMealPlans.where((m) => _isSameDay(m.date, _selectedDate)).toList();
    return Column(
      children: [
        if (dayPlans.isEmpty) 
          Padding(padding: const EdgeInsets.all(24.0), child: Text('今天还没有安排菜谱哦', style: TextStyle(color: Colors.grey.shade400))),
        ...dayPlans.map((p) => _buildPlanListItem(p)),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add), label: const Text('添加菜谱'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D4E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => _showRecipePicker(MealType.lunch),
          ),
        )
      ],
    );
  }

  Widget _buildPlanListItem(MealPlan plan) {
    final recipe = allRecipes.where((r) => r.id == plan.recipeId).firstOrNull;
    bool isSynced = _syncedPlanIds.contains(plan.id);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(recipe?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      subtitle: Text('Swipe left to delete', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      leading: Checkbox(value: isSynced, activeColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), onChanged: (val) async { setState(() { val! ? _syncedPlanIds.add(plan.id) : _syncedPlanIds.remove(plan.id); }); await _triggerSync(); }),
      trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), onPressed: () async { _syncedPlanIds.remove(plan.id); await plan.delete(); syncMemoryWithHive(); await _triggerSync(); }),
    );
  }

  // ==========================================
  // 🌟 NEW: 膳食推荐与库存打通模块
  // ==========================================

  // 1. 计算今天已经摄入了哪些 DietaryGroup
  Set<DietaryGroup> _getConsumedGroupsForToday() {
    Set<DietaryGroup> consumed = {};
    final dayPlans = myMealPlans.where((m) => _isSameDay(m.date, _selectedDate)).toList();
    for (var plan in dayPlans) {
      final recipe = allRecipes.where((r) => r.id == plan.recipeId).firstOrNull;
      if (recipe != null) {
        for (var req in recipe.ingredients) {
          final ing = myInventory.where((i) => i.id == req.ingredientId || i.name == req.ingredientId).firstOrNull;
          if (ing != null && ing.dietaryGroup != null) consumed.add(ing.dietaryGroup!);
        }
      }
    }
    return consumed;
  }

  // 2. 推荐模块 UI
  Widget _buildRecommendationBlock() {
    final consumedGroups = _getConsumedGroupsForToday();
    
    // 过滤掉不需要推荐的基础调料
    final displayGroups = DietaryGroup.values.where((g) => g != DietaryGroup.oils && g != DietaryGroup.saltAndCondiments && g != DietaryGroup.others).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAEB), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E9C5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.lightbulb_outline, color: Color(0xFF8B9D3C), size: 20), SizedBox(width: 8), Text('今日餐食推荐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A5D4E)))]),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧：代码绘制的高级膳食宝塔 (替代图片)
              Container(
                width: 90, height: 120,
                decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE5E9C5), Color(0xFFD4DCA3)]), borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.health_and_safety, color: Color(0xFF4A5D4E), size: 36),
                    SizedBox(height: 8),
                    Text('中国居民\n膳食指南', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4A5D4E)))
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 右侧：智能变灰的 Dietary Tags
              Expanded(
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: displayGroups.map((group) {
                    bool isConsumed = consumedGroups.contains(group);
                    return GestureDetector(
                      onTap: () => _showIngredientInventorySheet(group), // 🌟 触发底部弹窗选食材
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isConsumed ? Colors.grey.shade200 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isConsumed ? Colors.transparent : const Color(0xFF8B9D3C).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          group.displayName, 
                          style: TextStyle(fontSize: 12, fontWeight: isConsumed ? FontWeight.normal : FontWeight.bold, color: isConsumed ? Colors.grey.shade500 : const Color(0xFF4A5D4E))
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // 3. 🌟 底部半屏弹窗：根据 DietaryGroup 筛选厨房库存
// 3. 🌟 底部半屏弹窗：根据 DietaryGroup 筛选厨房库存 (包含全部食材，有库存靠前)
  void _showIngredientInventorySheet(DietaryGroup group) {
    // 🌟 修改1：去掉了 && i.inStock，获取该类的所有食材
    final ingredients = myInventory.where((i) => i.dietaryGroup == group).toList();
    
    // 🌟 修改2：复合排序算法
    ingredients.sort((a, b) {
      // 规则 A：有货的排在缺货的前面
      if (a.inStock && !b.inStock) return -1;
      if (!a.inStock && b.inStock) return 1;
      
      // 规则 B：如果都有货，按保质期排（快过期的在最上面，没填保质期的垫底）
      if (a.inStock && b.inStock) {
        if (a.expirationDate == null && b.expirationDate == null) return a.name.compareTo(b.name);
        if (a.expirationDate == null) return 1;
        if (b.expirationDate == null) return -1;
        return a.expirationDate!.compareTo(b.expirationDate!);
      }
      
      // 规则 C：如果都没货，就按首字母顺口排
      return a.name.compareTo(b.name);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, // 占屏幕 60% 高度
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12, bottom: 16), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Text('挑选: ${group.displayName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('点击食材查看可做菜谱', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const Divider(),
              Expanded(
                child: ingredients.isEmpty 
                  // 🌟 修改3：文案变得更严谨，因为现在没货的也会显示
                  ? Center(child: Text('您的厨房数据库中还没有记录过此类食材。', style: TextStyle(color: Colors.grey.shade400)))
                  : ListView.builder(
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final ing = ingredients[index];
                        bool isExpiringSoon = ing.expirationDate != null && ing.expirationDate!.difference(DateTime.now()).inDays <= 3;
                        
                        // 🌟 修改4：用 Opacity 包裹，缺货时半透明变灰
                        return Opacity(
                          opacity: ing.inStock ? 1.0 : 0.4, 
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.kitchen, color: Colors.grey)),
                            title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            
                            // 🌟 修改5：缺货时，副标题显示红色的缺货提示
                            subtitle: !ing.inStock 
                                ? const Text('缺货 (Out of stock)', style: TextStyle(color: Colors.red))
                                : (ing.expirationDate != null ? Text('保质期至: ${ing.expirationDate!.toLocal().toString().split(' ')[0]}', style: TextStyle(color: isExpiringSoon ? Colors.red : Colors.grey, fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal)) : null),
                            
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.pop(context); // 关掉当前食材弹窗
                              // 魔法跳转：进入菜谱列表，并带上 targetDate 激活一键添加！
                              Navigator.push(context, MaterialPageRoute(builder: (_) => MatchedRecipesScreen(ingredient: ing, targetDate: _selectedDate)))
                                .then((_) => setState(() {})); 
                            },
                          ),
                        );
                      },
                    ),
              )
            ],
          ),
        );
      }
    );
  }
  // ==========================================
  // OLD GRID MODE
  // ==========================================
  Widget _buildGridCalendarMode() {
    int year = _selectedDate.year; int month = _selectedDate.month;
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int firstWeekday = DateTime(year, month, 1).weekday; 
    int emptySlotsAtStart = firstWeekday - 1; 

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedDate = DateTime(year, month - 1, 1))),
              Text('${month}月 $year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selectedDate = DateTime(year, month + 1, 1))),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.6),
            itemCount: emptySlotsAtStart + daysInMonth,
            itemBuilder: (context, index) {
              if (index < emptySlotsAtStart) return const SizedBox.shrink();
              int day = index - emptySlotsAtStart + 1;
              DateTime cellDate = DateTime(year, month, day);
              var dayPlans = myMealPlans.where((m) => _isSameDay(m.date, cellDate)).toList();
              bool dayHasSync = dayPlans.isNotEmpty && dayPlans.every((p) => _syncedPlanIds.contains(p.id));

              return GestureDetector(
                onTap: () async {
                  if (_isSyncSelectionMode) {
                    var currentDayPlans = myMealPlans.where((m) => _isSameDay(m.date, cellDate)).toList();
                    if (currentDayPlans.isEmpty) return; 
                    bool allCurrentlySynced = currentDayPlans.every((p) => _syncedPlanIds.contains(p.id));
                    setState(() { if (allCurrentlySynced) { for (var p in currentDayPlans) _syncedPlanIds.remove(p.id); } else { for (var p in currentDayPlans) _syncedPlanIds.add(p.id); } });
                    await _triggerSync(); 
                  } else { setState(() { _selectedDate = cellDate; _isOverviewMode = false; }); }
                },
                child: Container(
                  decoration: BoxDecoration(color: _isSameDay(cellDate, _selectedDate) ? const Color(0xFF4A5D4E).withValues(alpha: 0.1) : Colors.white, border: Border.all(color: dayHasSync && _isSyncSelectionMode ? Colors.orange : Colors.grey.shade200, width: 2)),
                  child: Column(
                    children: [
                      Text('$day', style: TextStyle(fontWeight: _isSameDay(cellDate, DateTime.now()) ? FontWeight.bold : FontWeight.normal)),
                      ...dayPlans.map((p) {
                        final recipe = allRecipes.where((r) => r.id == p.recipeId).firstOrNull;
                        return Container(margin: const EdgeInsets.symmetric(vertical: 1), padding: const EdgeInsets.all(2), color: _syncedPlanIds.contains(p.id) ? Colors.orange.withValues(alpha: 0.2) : const Color(0xFF4A5D4E).withValues(alpha: 0.1), child: Text(recipe?.name ?? '', style: const TextStyle(fontSize: 8), overflow: TextOverflow.ellipsis));
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}