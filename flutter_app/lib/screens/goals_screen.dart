import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<dynamic> _goals = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _goals = await ApiService.instance.getGoals();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showAddOrEdit({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final targetCtrl = TextEditingController(text: existing != null ? existing['targetAmount'].toString() : '');
    final savedCtrl = TextEditingController(text: existing != null ? existing['savedAmount'].toString() : '0');
    final dateCtrl = TextEditingController(
      text: existing?['deadline'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 180))),
    );
    String category = existing?['category'] ?? 'Travel';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isEdit ? 'Edit Goal' : 'Add Goal', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Goal Name (e.g. Goa Trip)')),
          const SizedBox(height: 12),
          TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Amount (₹)', prefixText: '₹ ')),
          const SizedBox(height: 12),
          TextField(controller: savedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Currently Saved (₹)', prefixText: '₹ ')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: AppColors.surfaceAlt, value: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Travel', 'Gifts', 'Shopping', 'Education', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setSt(() => category = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameCtrl.text,
                'targetAmount': double.tryParse(targetCtrl.text) ?? 0.0,
                'savedAmount': double.tryParse(savedCtrl.text) ?? 0.0,
                'category': category,
                'deadline': dateCtrl.text,
              };
              if (isEdit) {
                await ApiService.instance.updateGoal(existing['id'], data);
              } else {
                await ApiService.instance.createGoal(data);
              }
              _load();
              if (mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? 'Update Goal' : 'Save Goal'),
          )),
        ]),
      )),
    );
  }

  void _showAddSavings(String id, String goalName) {
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Add Savings to $goalName'),
        content: TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount to add (₹)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              double amt = double.tryParse(amtCtrl.text) ?? 0.0;
              if (amt > 0) {
                await ApiService.instance.addGoalSavings(id, amt);
                _load();
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals'), actions: [
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddOrEdit()),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? const Center(child: Text('No goals created. Tap + to add.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (ctx, i) {
                    final goal = _goals[i];
                    final target = (goal['targetAmount'] as num).toDouble();
                    final saved = (goal['savedAmount'] as num).toDouble();
                    final pct = (saved / target).clamp(0.0, 1.0);

                    return Dismissible(
                      key: Key(goal['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRed),
                      ),
                      confirmDismiss: (_) => _confirmDelete(goal['name']),
                      onDismissed: (_) async {
                        await ApiService.instance.deleteGoal(goal['id']);
                        _load();
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              CircleAvatar(
                                backgroundColor: AppColors.accentGreen.withOpacity(0.15),
                                child: const Icon(Icons.flag_rounded, color: AppColors.accentGreen, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(goal['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                Text('${goal['category']} · Deadline: ${goal['deadline']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ])),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                                onPressed: () => _showAddOrEdit(existing: Map<String, dynamic>.from(goal)),
                                tooltip: 'Edit Goal',
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent),
                                onPressed: () => _showAddSavings(goal['id'], goal['name']),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: pct,
                              backgroundColor: AppColors.border,
                              color: AppColors.accentGreen,
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('${(pct * 100).toStringAsFixed(0)}% saved', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              Text('${fmt.format(saved)} / ${fmt.format(target)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ]),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
