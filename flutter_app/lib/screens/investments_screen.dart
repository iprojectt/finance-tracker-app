import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});
  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  List<dynamic> _investments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _investments = await ApiService.instance.getInvestments();
    setState(() => _loading = false);
  }

  void _showAdd() {
    final nameCtrl = TextEditingController();
    final subtypeCtrl = TextEditingController();
    final investedCtrl = TextEditingController();
    final currentCtrl = TextEditingController();
    final unitsCtrl = TextEditingController();
    final platformCtrl = TextEditingController();
    String type = 'mutual_fund';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => SingleChildScrollView(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Add Investment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Nifty 50 Index Fund)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: AppColors.surfaceAlt, value: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: ['mutual_fund', 'stocks', 'fd', 'ppf', 'gold', 'crypto']
              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setSt(() => type = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: subtypeCtrl, decoration: const InputDecoration(labelText: 'Subtype (SIP/Lumpsum or Scrip Name)')),
          const SizedBox(height: 12),
          TextField(controller: platformCtrl, decoration: const InputDecoration(labelText: 'Platform (Zerodha, Groww, etc)')),
          const SizedBox(height: 12),
          TextField(controller: investedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Invested Amount (₹)')),
          const SizedBox(height: 12),
          TextField(controller: currentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Value (₹)')),
          const SizedBox(height: 12),
          TextField(controller: unitsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Units (optional)')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              await ApiService.instance.createInvestment({
                'name': nameCtrl.text,
                'type': type,
                'subtype': subtypeCtrl.text.isNotEmpty ? subtypeCtrl.text : null,
                'platform': platformCtrl.text,
                'investedAmount': double.tryParse(investedCtrl.text) ?? 0.0,
                'currentValue': double.tryParse(currentCtrl.text) ?? 0.0,
                'units': double.tryParse(unitsCtrl.text),
              });
              _load();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Investment'),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    double totalInvested = _investments.fold(0, (s, i) => s + (i['investedAmount'] as num));
    double totalCurrent = _investments.fold(0, (s, i) => s + (i['currentValue'] as num));
    double totalGain = totalCurrent - totalInvested;

    return Scaffold(
      appBar: AppBar(title: const Text('Investments'), actions: [
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: _showAdd),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (_investments.isNotEmpty) Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _InvStat(label: 'Invested', value: fmt.format(totalInvested), color: AppColors.accent),
                  _InvStat(label: 'Current', value: fmt.format(totalCurrent), color: AppColors.textPrimary),
                  _InvStat(
                    label: 'Gain/Loss',
                    value: '${totalGain >= 0 ? '+' : ''}${fmt.format(totalGain)}',
                    color: totalGain >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                  ),
                ]),
              ),
              Expanded(
                child: _investments.isEmpty
                    ? const Center(child: Text('No investments. Tap + to add.', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _investments.length,
                        itemBuilder: (ctx, i) {
                          final inv = _investments[i];
                          final gain = (inv['gain_loss'] ?? 0) as num;
                          final ret = (inv['return_pct'] ?? 0) as num;
                          final subtype = inv['subtype'] != null ? ' · ${inv['subtype']}' : '';
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.accent.withOpacity(0.15),
                                child: const Icon(Icons.trending_up_rounded, color: AppColors.accent, size: 18),
                              ),
                              title: Text(inv['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${inv['type']}$subtype · ${inv['platform'] ?? '-'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(fmt.format(inv['currentValue'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(
                                  '${gain >= 0 ? '+' : ''}${fmt.format(gain)} (${ret.toStringAsFixed(1)}%)',
                                  style: TextStyle(color: gain >= 0 ? AppColors.accentGreen : AppColors.accentRed, fontSize: 11),
                                ),
                              ]),
                              onLongPress: () async {
                                await ApiService.instance.deleteInvestment(inv['id']);
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

class _InvStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InvStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
  ]);
}
