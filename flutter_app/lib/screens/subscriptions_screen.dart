import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<dynamic> _subs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _subs = await ApiService.instance.getSubscriptions();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showAdd() {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 30))));
    String cycle = 'monthly';
    String category = 'Entertainment';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Subscription', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (Netflix, Spotify, JioHotstar)')),
          const SizedBox(height: 12),
          TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ ')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: AppColors.surfaceAlt, value: cycle,
            decoration: const InputDecoration(labelText: 'Cycle'),
            items: ['monthly', 'yearly'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setSt(() => cycle = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: AppColors.surfaceAlt, value: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Entertainment', 'Learning', 'Telecom', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setSt(() => category = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Next Due Date (YYYY-MM-DD)')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              await ApiService.instance.createSubscription({
                'name': nameCtrl.text,
                'amount': double.tryParse(amtCtrl.text) ?? 0.0,
                'cycle': cycle,
                'category': category,
                'nextDueDate': dateCtrl.text,
                'active': true,
              });
              _load();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Subscription'),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final totalMonthly = _subs.where((s) => s['active'] == true).fold<double>(0, (sum, s) {
      double amt = (s['amount'] as num).toDouble();
      return sum + (s['cycle'] == 'yearly' ? amt / 12 : amt);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions'), actions: [
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: _showAdd),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (_subs.isNotEmpty) Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total Monthly Impact', style: TextStyle(color: AppColors.textSecondary)),
                  Text(fmt.format(totalMonthly), style: const TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
              ),
              Expanded(
                child: _subs.isEmpty
                    ? const Center(child: Text('No subscriptions added. Tap + to add.', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _subs.length,
                        itemBuilder: (ctx, i) {
                          final sub = _subs[i];
                          final active = sub['active'] ?? true;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: active ? AppColors.accent.withOpacity(0.15) : AppColors.surfaceAlt,
                                child: Icon(Icons.subscriptions_rounded, color: active ? AppColors.accent : AppColors.textSecondary, size: 18),
                              ),
                              title: Text(sub['name'], style: TextStyle(fontWeight: FontWeight.w600, decoration: active ? null : TextDecoration.lineThrough)),
                              subtitle: Text('${sub['cycle']} · Next due: ${sub['nextDueDate']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(fmt.format(sub['amount']), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Switch(
                                  value: active,
                                  onChanged: (_) async {
                                    await ApiService.instance.toggleSubscription(sub['id']);
                                    _load();
                                  },
                                ),
                              ]),
                              onLongPress: () async {
                                await ApiService.instance.deleteSubscription(sub['id']);
                                _load();
                              },
                            ),
                          );
                        }),
              ),
            ]),
    );
  }
}
