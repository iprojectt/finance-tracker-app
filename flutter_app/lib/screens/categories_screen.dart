import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> _categories = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _categories = await ApiService.instance.getCategories();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showAdd() {
    final nameCtrl = TextEditingController();
    final subsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Custom Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name (e.g. Shopping)')),
          const SizedBox(height: 12),
          TextField(controller: subsCtrl, decoration: const InputDecoration(labelText: 'Subcategories (comma separated, e.g. Clothes, Shoes)')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              List<String> subs = subsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              await ApiService.instance.createCategory({
                'name': nameCtrl.text,
                'subcategories': subs,
                'type': 'transaction',
                'icon': 'category',
              });
              _load();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Category'),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), actions: [
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: _showAdd),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final List subs = cat['subcategories'] ?? [];
                return Card(
                  child: ExpansionTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.surfaceAlt,
                      child: Icon(Icons.category_rounded, color: AppColors.accent, size: 18),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text(
                          NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(cat['total_spent'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error, fontSize: 14),
                        ),
                      ],
                    ),
                    subtitle: Text('${subs.length} subcategories', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    children: subs.map<Widget>((s) {
                      final subTotal = (cat['subcategory_totals'] ?? {})[s] ?? 0;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 72, right: 32),
                        title: Text(s.toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        trailing: Text(
                          NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(subTotal),
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        leading: const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: AppColors.border),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
