import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';

// 把它变成一个正式的 setState
class AiImportDialog extends StatefulWidget {
  const AiImportDialog({super.key});

  @override
  State<AiImportDialog> createState() => _AiImportDialogState();
}

class _AiImportDialogState extends State<AiImportDialog> {
  final textCtrl = TextEditingController();
  bool isLoading = false;
  List<XFile> selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    // 把你原来 AlertDialog 里面的所有代码放在这里
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
                                    Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setState(() => selectedImages.removeAt(index)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)))),
                                  ],
                                );
                              },
                            ),
                          ),
                        TextButton.icon(icon: const Icon(Icons.add_photo_alternate, color: Colors.teal), label: const Text('Add Images', style: TextStyle(color: Colors.teal)), onPressed: () async { final List<XFile> images = await _picker.pickMultiImage(); if (images.isNotEmpty) { setState(() => selectedImages.addAll(images)); } }),
                      ],
                    ),
                  ),
                ),
            actions: [
              if (!isLoading) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              if (!isLoading) ElevatedButton(
                onPressed: (textCtrl.text.isEmpty && selectedImages.isEmpty) ? null : () async {
                  setState(() => isLoading = true);
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
}