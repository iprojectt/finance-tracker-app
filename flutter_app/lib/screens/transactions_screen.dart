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

  void _showAddOrEdit({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TransactionSheet(
        accounts: _accounts,
        categories: _categories,
        onSaved: _load,
        existing: existing,
      ),
    );
  }

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Transaction?'),
        content: Text('Are you sure you want to delete "$name"? This will also reverse the account balance change.'),
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

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddOrEdit()),
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
                    final desc = t['description'] ?? t['category'] ?? '-';
                    return Dismissible(
                      key: Key(t['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRed),
                      ),
                      confirmDismiss: (_) => _confirmDelete(desc),
                      onDismissed: (_) async {
                        await ApiService.instance.deleteTransaction(t['id']);
                        _load();
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCredit ? AppColors.accentGreen.withOpacity(0.15) : AppColors.accentRed.withOpacity(0.15),
                          child: Icon(
                            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isCredit ? AppColors.accentGreen : AppColors.accentRed,
                            size: 18,
                          ),
                        ),
                        title: Text(desc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text('${t['category']}$subcat · ${t['date']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        trailing: Text(
                          '${isCredit ? '+' : '-'}${fmt.format(t['amount'])}',
                          style: TextStyle(color: isCredit ? AppColors.accentGreen : AppColors.accentRed, fontWeight: FontWeight.w600),
                        ),
                        onTap: () => _showAddOrEdit(existing: Map<String, dynamic>.from(t)),
                      ),
                    );
                  },
                ),
    );
  }
}

class _TransactionSheet extends StatefulWidget {
  final List<dynamic> accounts;
  final List<dynamic> categories;
  final VoidCallback onSaved;
  final Map<String, dynamic>? existing;
  const _TransactionSheet({required this.accounts, required this.categories, required this.onSaved, this.existing});

  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'debit';
  String? _category;
  String? _subcategory;
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _accountId;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existing!;
      _amountCtrl.text = (e['amount'] ?? 0).toString();
      _descCtrl.text = e['description'] ?? '';
      _type = e['type'] ?? 'debit';
      _category = e['category'];
      _subcategory = e['subcategory'];
      _date = e['date'] ?? _date;
      _accountId = e['accountId']?.toString();
    } else {
      if (widget.categories.isNotEmpty) {
        _category = widget.categories.first['name'];
        final List subs = widget.categories.first['subcategories'] ?? [];
        if (subs.isNotEmpty) _subcategory = subs.first.toString();
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _accountId == null) return;
    setState(() => _saving = true);
    try {
      final data = {
        'accountId': _accountId,
        'amount': double.parse(_amountCtrl.text),
        'type': _type,
        'category': _category,
        'subcategory': _subcategory,
        'description': _descCtrl.text,
        'date': _date,
      };
      if (_isEdit) {
        await ApiService.instance.updateTransaction(widget.existing!['id'], data);
      } else {
        data['source'] = 'manual';
        await ApiService.instance.createTransaction(data);
      }
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEdit ? 'Edit Transaction' : 'Add Transaction', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
                isExpanded: true,
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
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceAlt,
                  decoration: const InputDecoration(labelText: 'Subcategory'),
                  value: subcategories.contains(_subcategory) ? _subcategory : (subcategories.isNotEmpty ? subcategories.first.toString() : null),
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
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Update' : 'Save'),
            ),
          ),
        ]),
        ),
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
