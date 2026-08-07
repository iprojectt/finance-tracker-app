import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<dynamic> _accounts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _accounts = await ApiService.instance.getAccounts();
    setState(() => _loading = false);
  }

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account?'),
        content: Text('Are you sure you want to delete "$name"? Transactions linked to this account will lose their association.'),
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
    final subtypeCtrl = TextEditingController(text: existing?['subtype'] ?? '');
    final balCtrl = TextEditingController(text: existing != null ? existing['balance'].toString() : '');
    String type = existing?['type'] ?? 'savings';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isEdit ? 'Edit Account' : 'Add Account', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Account Name (e.g. SBI Savings)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: AppColors.surfaceAlt,
            value: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: ['savings', 'current', 'upi', 'cash'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setSt(() => type = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: subtypeCtrl, decoration: const InputDecoration(labelText: 'Subtype / App (for UPI: PhonePe, Paytm, etc)')),
          const SizedBox(height: 12),
          TextField(controller: balCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Balance (₹)', prefixText: '₹ ')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameCtrl.text,
                'subtype': subtypeCtrl.text.isNotEmpty ? subtypeCtrl.text : null,
                'balance': double.tryParse(balCtrl.text) ?? 0.0,
              };
              if (isEdit) {
                await ApiService.instance.updateAccount(existing['id'], data);
              } else {
                data['type'] = type;
                data['currency'] = 'INR';
                await ApiService.instance.createAccount(data);
              }
              _load();
              if (mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? 'Update Account' : 'Save Account'),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts'), actions: [
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddOrEdit()),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? const Center(child: Text('No accounts yet. Tap + to add.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _accounts.length,
                  itemBuilder: (ctx, i) {
                    final a = _accounts[i];
                    final subtype = a['subtype'] != null && a['subtype'].toString().isNotEmpty ? ' · ${a['subtype']}' : '';
                    return Dismissible(
                      key: Key(a['id'].toString()),
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
                      confirmDismiss: (_) => _confirmDelete(a['name']),
                      onDismissed: (_) async {
                        await ApiService.instance.deleteAccount(a['id']);
                        _load();
                      },
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent),
                          title: Text(a['name']),
                          subtitle: Text('${a['type']}$subtype'),
                          trailing: Text(fmt.format(a['balance'] ?? 0),
                            style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w700, fontSize: 15)),
                          onTap: () => _showAddOrEdit(existing: Map<String, dynamic>.from(a)),
                        ),
                      ),
                    );
                  }),
    );
  }
}
