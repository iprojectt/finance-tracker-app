import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});
  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  List<dynamic> _loans = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _loans = await ApiService.instance.getLoans();
    setState(() => _loading = false);
  }

  void _showAdd() {
    final nameCtrl = TextEditingController();
    final lenderCtrl = TextEditingController();
    final principalCtrl = TextEditingController();
    final outstandingCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final emiCtrl = TextEditingController();
    final tenureCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String type = 'personal';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => SingleChildScrollView(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Loan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Loan Name (e.g. HDFC Personal Loan)')),
          const SizedBox(height: 12),
          TextField(controller: lenderCtrl, decoration: const InputDecoration(labelText: 'Lender (Bank/Person)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: AppColors.surfaceAlt, value: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: ['personal', 'credit_card', 'friend_family', 'education']
              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setSt(() => type = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: principalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Principal Amount (₹)')),
          const SizedBox(height: 12),
          TextField(controller: outstandingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Outstanding Balance (₹)')),
          const SizedBox(height: 12),
          TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Interest Rate (% annual)')),
          const SizedBox(height: 12),
          TextField(controller: emiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'EMI (₹/month)')),
          const SizedBox(height: 12),
          TextField(controller: tenureCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Tenure (months)')),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              await ApiService.instance.createLoan({
                'name': nameCtrl.text, 'lender': lenderCtrl.text, 'type': type,
                'principal': double.tryParse(principalCtrl.text) ?? 0.0,
                'outstanding': double.tryParse(outstandingCtrl.text) ?? 0.0,
                'interestRate': double.tryParse(rateCtrl.text) ?? 0.0,
                'emi': double.tryParse(emiCtrl.text) ?? 0.0,
                'tenureMonths': int.tryParse(tenureCtrl.text) ?? 0,
                'startDate': dateCtrl.text,
              });
              _load();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Loan'),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Loans'), actions: [
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: _showAdd),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? const Center(child: Text('No loans. Tap + to add.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _loans.length,
                  itemBuilder: (ctx, i) {
                    final loan = _loans[i];
                    final principal = (loan['principal'] as num).toDouble();
                    final outstanding = (loan['outstanding'] as num).toDouble();
                    final pct = principal > 0 ? ((principal - outstanding) / principal * 100).clamp(0.0, 100.0) : 0.0;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(loan['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('${loan['lender'] ?? ''} · ${loan['type']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(fmt.format(outstanding), style: const TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w700, fontSize: 15)),
                              const Text('remaining', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ]),
                          ]),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: AppColors.border,
                            color: AppColors.accentGreen,
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 6,
                          ),
                          const SizedBox(height: 6),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('${pct.toStringAsFixed(0)}% paid', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            Text('EMI: ${fmt.format(loan['emi'])}/mo', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            Text('${loan['months_remaining'] ?? 0} months left', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            TextButton.icon(
                              onPressed: () async {
                                final result = await ApiService.instance.payEmi(loan['id']);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('EMI paid. Principal: ${fmt.format(result['principal_paid'])}, Interest: ${fmt.format(result['interest_paid'])}'),
                                ));
                                _load();
                              },
                              icon: const Icon(Icons.payment_rounded, size: 16),
                              label: const Text('Pay EMI'),
                            ),
                          ]),
                        ]),
                      ),
                    );
                  }),
    );
  }
}
