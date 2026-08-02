import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> _txns = [];
  List<dynamic> _accounts = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  String? _filterMonth;

  @override
  void initState() {
    super.initState();
    _filterMonth = DateFormat('yyyy-MM').format(DateTime.now());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.instance.getTransactions(month: _filterMonth),
        ApiService.instance.getAccounts(),
        ApiService.instance.getCategories(),
      ]);
      setState(() {
        _txns = results[0];
        _accounts = results[1];
        _categories = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddTransactionSheet(accounts: _accounts, categories: _categories, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _showAddDialog),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _txns.isEmpty
              ? const Center(child: Text('No transactions. Tap + to add.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  itemCount: _txns.length,
                  itemBuilder: (ctx, i) {
                    final t = _txns[i];
                    final isCredit = t['type'] == 'credit';
                    final subcat = t['subcategory'] != null ? ' · ${t['subcategory']}' : '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCredit ? AppColors.accentGreen.withOpacity(0.15) : AppColors.accentRed.withOpacity(0.15),
                        child: Icon(
                          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isCredit ? AppColors.accentGreen : AppColors.accentRed,
                          size: 18,
                        ),
                      ),
                      title: Text(t['description'] ?? t['category'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text('${t['category']}$subcat · ${t['date']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: Text(
                        '${isCredit ? '+' : '-'}${fmt.format(t['amount'])}',
                        style: TextStyle(color: isCredit ? AppColors.accentGreen : AppColors.accentRed, fontWeight: FontWeight.w600),
                      ),
                      onLongPress: () async {
                        await ApiService.instance.deleteTransaction(t['id']);
                        _load();
                      },
                    );
                  },
                ),
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  final List<dynamic> accounts;
  final List<dynamic> categories;
  final VoidCallback onSaved;
  const _AddTransactionSheet({required this.accounts, required this.categories, required this.onSaved});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'debit';
  String? _category;
  String? _subcategory;
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _accountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _category = widget.categories.first['name'];
      final List subs = widget.categories.first['subcategories'] ?? [];
      if (subs.isNotEmpty) _subcategory = subs.first.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _accountId == null) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.createTransaction({
        'accountId': _accountId,
        'amount': double.parse(_amountCtrl.text),
        'type': _type,
        'category': _category,
        'subcategory': _subcategory,
        'description': _descCtrl.text,
        'date': _date,
        'source': 'manual',
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentCatObj = widget.categories.firstWhere(
      (c) => c['name'] == _category,
      orElse: () => null,
    );
    final List subcategories = currentCatObj != null ? (currentCatObj['subcategories'] ?? []) : [];

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _TypeButton(label: 'Expense', selected: _type == 'debit', color: AppColors.accentRed,
              onTap: () => setState(() => _type = 'debit'))),
            const SizedBox(width: 10),
            Expanded(child: _TypeButton(label: 'Income', selected: _type == 'credit', color: AppColors.accentGreen,
              onTap: () => setState(() => _type = 'credit'))),
          ]),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            dropdownColor: AppColors.surfaceAlt,
            decoration: const InputDecoration(labelText: 'Account'),
            value: _accountId,
            items: widget.accounts.map<DropdownMenuItem<String>>((a) =>
              DropdownMenuItem(value: a['id'].toString(), child: Text(a['name']))).toList(),
            onChanged: (v) => setState(() => _accountId = v),
            validator: (v) => v == null ? 'Select an account' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountCtrl,
            decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description (e.g. Swiggy biryani)'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                dropdownColor: AppColors.surfaceAlt,
                decoration: const InputDecoration(labelText: 'Category'),
                value: _category,
                items: widget.categories.map<DropdownMenuItem<String>>((c) =>
                  DropdownMenuItem(value: c['name'].toString(), child: Text(c['name']))).toList(),
                onChanged: (v) {
                  setState(() {
                    _category = v;
                    final catObj = widget.categories.firstWhere((c) => c['name'] == v, orElse: () => null);
                    final List subs = catObj != null ? (catObj['subcategories'] ?? []) : [];
                    _subcategory = subs.isNotEmpty ? subs.first.toString() : null;
                  });
                },
              ),
            ),
            if (subcategories.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  dropdownColor: AppColors.surfaceAlt,
                  decoration: const InputDecoration(labelText: 'Subcategory'),
                  value: _subcategory,
                  items: subcategories.map<DropdownMenuItem<String>>((s) =>
                    DropdownMenuItem(value: s.toString(), child: Text(s.toString()))).toList(),
                  onChanged: (v) => setState(() => _subcategory = v),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _date,
            decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            onChanged: (v) => _date = v,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeButton({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(color: selected ? color : AppColors.textSecondary, fontWeight: FontWeight.w600))),
      ),
    );
  }
}
