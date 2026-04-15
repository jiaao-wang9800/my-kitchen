import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import '../models/app_models.dart';

import '../data/mock_database.dart';



// ==========================================

// Recipe Detail Screen (保持你之前的原样)

// ==========================================

class RecipeDetailScreen extends StatefulWidget {

final Recipe recipe;

const RecipeDetailScreen({super.key, required this.recipe});



@override

State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();

}

// ==========================================

// Recipe Detail Screen (全面重构编辑功能)

// ==========================================





class _RecipeDetailScreenState extends State<RecipeDetailScreen> {

bool _isEditing = false;

late TextEditingController _nameController;

late List<TextEditingController> _stepControllers;


late List<RecipeIngredient> _selectedIngredients;

final Map<String, TextEditingController> _qtyControllers = {};

String _ingSearchQuery = '';

final TextEditingController _ingSearchController = TextEditingController(); // 🌟 新增：用于控制食材搜索框


final ImagePicker _picker = ImagePicker(); // 🌟 新增：用于详情页换封面



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



// 🌟 新增：快捷添加全新食材（从弹窗提取出来复用）

// 🌟 修改：支持传入初始名称

Future<void> _quickAddIngredient({String? initialName}) async {

final newIngNameCtrl = TextEditingController(text: initialName ?? '');

String? selectedCatId = allCategories.isNotEmpty ? allCategories.first.id : null;



await showDialog(

context: context,

builder: (innerContext) => StatefulBuilder(

builder: (innerContext, setInnerState) => AlertDialog(

title: const Text('快速新建食材'),

content: SizedBox(

width: double.maxFinite,

child: Column(

mainAxisSize: MainAxisSize.min,

crossAxisAlignment: CrossAxisAlignment.start,

children: [

TextField(controller: newIngNameCtrl, decoration: const InputDecoration(labelText: '食材名称'), onChanged: (val) => setInnerState(() {})),

const SizedBox(height: 16),

const Text('所属分类:', style: TextStyle(fontSize: 12, color: Colors.grey)),

const SizedBox(height: 8),

allCategories.isEmpty

? const Text('没有可用的分类！请先去库存建立分类。', style: TextStyle(color: Colors.red))

: Wrap(spacing: 8.0, runSpacing: 4.0, children: allCategories.map((cat) { return ChoiceChip(label: Text(cat.name), selected: selectedCatId == cat.id, selectedColor: Colors.teal.withValues(alpha: 0.3), onSelected: (bool selected) { if (selected) setInnerState(() => selectedCatId = cat.id); }); }).toList()),

],

),

),

actions: [

TextButton(onPressed: () => Navigator.pop(innerContext), child: const Text('取消')),

ElevatedButton(

onPressed: (selectedCatId == null || newIngNameCtrl.text.trim().isEmpty) ? null : () async {

final newIng = Ingredient(id: generateId(), name: newIngNameCtrl.text.trim(), categoryId: selectedCatId!, inStock: false);

await inventoryBox.put(newIng.id, newIng);

syncMemoryWithHive();

setState(() {

_selectedIngredients.add(RecipeIngredient(ingredientId: newIng.id, quantity: '适量', isMain: true));

_qtyControllers[newIng.id] = TextEditingController(text: '适量');

// 🌟 新增：创建完成后清空搜索状态

_ingSearchController.clear();

_ingSearchQuery = '';

});

if (innerContext.mounted) Navigator.pop(innerContext);

},

child: const Text('创建并加入'),

)

],

)

)

);

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



GestureDetector(

onTap: _isEditing ? () async {

final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

if (image != null) {

setState(() => widget.recipe.imagePath = image.path);

}

} : null,

child: widget.recipe.imagePath != null

? Image.file(File(widget.recipe.imagePath!), fit: BoxFit.cover)

: Container(color: Colors.grey[400], child: Icon(_isEditing ? Icons.add_a_photo : Icons.restaurant, size: 80, color: Colors.white)),

),

Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.1), Colors.transparent, Colors.black.withValues(alpha: 0.8)]))),


// 🌟 新增：编辑模式下照片上的提示 Tag

if (_isEditing)

Positioned(

top: 100, right: 16,

child: Container(

padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),

child: const Row(children: [Icon(Icons.camera_alt, color: Colors.white, size: 16), SizedBox(width: 4), Text('点击更换封面', style: TextStyle(color: Colors.white, fontSize: 12))]),

),

),



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

if (!_isEditing)

Text('${_selectedIngredients.length} 项', style: const TextStyle(color: Colors.grey, fontSize: 14)),

],

),

const SizedBox(height: 16),

if (_isEditing) ...[


// 1. 顶部的智能搜索框

TextField(

controller: _ingSearchController,

decoration: InputDecoration(

hintText: '搜索已有食材，或输入新名称...',

prefixIcon: const Icon(Icons.search),

filled: true, fillColor: Colors.white,

border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),

suffixIcon: _ingSearchQuery.isNotEmpty

? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => setState(() { _ingSearchController.clear(); _ingSearchQuery = ''; }))

: null,

),

onChanged: (val) => setState(() => _ingSearchQuery = val)

),


// 2. 动态搜索结果与新建选项（仅在输入时显示）

if (_ingSearchQuery.isNotEmpty)

Container(

margin: const EdgeInsets.only(top: 8, bottom: 16),

decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4A5D4E).withValues(alpha: 0.3))),

child: Column(

children: [

// 显示匹配到的现有食材

...filteredIngredients.map((ing) {

final isAlreadyAdded = _selectedIngredients.any((ri) => ri.ingredientId == ing.id);


return ListTile(

title: Text(

ing.name,

style: TextStyle(

color: isAlreadyAdded ? Colors.grey : Colors.black87,

decoration: isAlreadyAdded ? TextDecoration.lineThrough : null, // 加个删除线更有“禁用”的感觉

)

),

trailing: isAlreadyAdded

? const Row(

mainAxisSize: MainAxisSize.min,

children: [

Icon(Icons.check, color: Colors.grey, size: 16),

SizedBox(width: 4),

Text('已添加', style: TextStyle(color: Colors.grey, fontSize: 12)),

],

)

: const Icon(Icons.add_circle_outline, color: Color(0xFF4A5D4E)),

// 如果已经添加了，点击事件就设为 null（禁用点击）

onTap: isAlreadyAdded ? null : () {

setState(() {

_selectedIngredients.add(RecipeIngredient(ingredientId: ing.id, quantity: '适量', isMain: true));

_qtyControllers[ing.id] = TextEditingController(text: '适量');

_ingSearchController.clear();

_ingSearchQuery = '';

});

},

);

}),

// 🌟 永远在底部提供“新建”选项

ListTile(

leading: const Icon(Icons.add, color: Colors.blueAccent),

title: RichText(

text: TextSpan(

style: const TextStyle(color: Colors.black87, fontSize: 16),

children: [

const TextSpan(text: '新建食材 '),

TextSpan(text: '"$_ingSearchQuery"', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),

],

),

),

onTap: () => _quickAddIngredient(initialName: _ingSearchQuery),

)

],

),

),


const SizedBox(height: 16),



// 3. 下方展示已加入菜谱的食材卡片

if (_selectedIngredients.isNotEmpty)

ListView.builder(

shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),

itemCount: _selectedIngredients.length,

itemBuilder: (context, index) {

final ri = _selectedIngredients[index];

final ing = myInventory.firstWhere((i) => i.id == ri.ingredientId, orElse: () => Ingredient(id: '', name: 'Unknown', categoryId: ''));

return Container(

margin: const EdgeInsets.only(bottom: 12),

padding: const EdgeInsets.all(12),

decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),

child: Column(

children: [

Row(

children: [

Expanded(child: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),

IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () {

setState(() { _selectedIngredients.removeAt(index); _qtyControllers.remove(ing.id)?.dispose(); });

})

],

),

const SizedBox(height: 8),

Row(

children: [

Expanded(child: TextField(controller: _qtyControllers[ing.id], decoration: InputDecoration(labelText: '具体用量', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: (val) => ri.quantity = val)),

const SizedBox(width: 12),

ChoiceChip(label: const Text('主料'), selected: ri.isMain, onSelected: (v) => setState(() => ri.isMain = true)),

const SizedBox(width: 8),

ChoiceChip(label: const Text('调料'), selected: !ri.isMain, onSelected: (v) => setState(() => ri.isMain = false)),

],

)

],

),

);

}

),

] else ...[



// 阅读模式下的展示（保持原样）

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

if (_isEditing)

IconButton(

icon: const Icon(Icons.add_circle, color: Color(0xFF4A5D4E)),

onPressed: () => setState(() => _stepControllers.add(TextEditingController()))

),

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